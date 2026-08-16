use std::{net::SocketAddr, path::PathBuf};

use anyhow::{Context, Result, bail};
use axum::Router;
use clap::{Parser, ValueEnum};
use rmcp::{
    ServerHandler, ServiceExt,
    handler::server::{router::tool::ToolRouter, wrapper::Parameters},
    model::{ServerCapabilities, ServerInfo},
    schemars, tool, tool_handler, tool_router,
    transport::streamable_http_server::{
        StreamableHttpServerConfig, StreamableHttpService, session::local::LocalSessionManager,
    },
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use tokio::process::Command;
use tokio_util::sync::CancellationToken;

#[derive(Debug, Clone, Copy, ValueEnum)]
enum Profile {
    Control,
    Node,
}

#[derive(Debug, Clone, Copy, ValueEnum)]
enum Transport {
    Stdio,
    Http,
}

#[derive(Debug, Parser)]
#[command(name = "water-spider-mcp", version, about)]
struct Args {
    /// Tool catalog to expose.
    #[arg(long, value_enum, default_value_t = Profile::Control)]
    profile: Profile,

    /// MCP transport. HTTP is restricted to a loopback listener.
    #[arg(long, value_enum, default_value_t = Transport::Stdio)]
    transport: Transport,

    /// Address for Streamable HTTP. Non-loopback addresses are rejected.
    #[arg(long, default_value = "127.0.0.1:8765")]
    listen: SocketAddr,
}

#[derive(Debug, Clone)]
struct CliBackend {
    executable: PathBuf,
}

#[derive(Debug, Serialize)]
struct CommandResult {
    ok: bool,
    exit_code: Option<i32>,
    stdout: String,
    stderr: String,
}

impl CliBackend {
    fn from_env() -> Self {
        Self {
            executable: std::env::var_os("WATER_SPIDER_BIN")
                .map(PathBuf::from)
                .unwrap_or_else(|| PathBuf::from("water-spider")),
        }
    }

    async fn run(&self, args: &[&str]) -> String {
        match Command::new(&self.executable).args(args).output().await {
            Ok(output) => serde_json::to_string(&CommandResult {
                ok: output.status.success(),
                exit_code: output.status.code(),
                stdout: String::from_utf8_lossy(&output.stdout).trim().to_string(),
                stderr: String::from_utf8_lossy(&output.stderr).trim().to_string(),
            })
            .unwrap_or_else(|error| json!({"ok": false, "error": error.to_string()}).to_string()),
            Err(error) => json!({
                "ok": false,
                "error": format!("failed to execute {}: {error}", self.executable.display())
            })
            .to_string(),
        }
    }
}

#[derive(Debug, Deserialize, schemars::JsonSchema)]
struct PodIdRequest {
    /// Exact RunPod pod ID from pods_list.
    pod_id: String,
}

#[derive(Debug, Deserialize, schemars::JsonSchema)]
struct GpusRequest {
    /// Return only GPU types currently reported as available.
    #[serde(default)]
    available_only: bool,
}

#[derive(Debug, Clone)]
struct ControlService {
    backend: CliBackend,
    tool_router: ToolRouter<Self>,
}

impl ControlService {
    fn new(backend: CliBackend) -> Self {
        Self {
            backend,
            tool_router: Self::tool_router(),
        }
    }
}

#[tool_router]
impl ControlService {
    #[tool(
        name = "account_status",
        description = "Read RunPod balance, current hourly spend, and pod count. Does not create or modify resources.",
        annotations(
            title = "Account status",
            read_only_hint = true,
            destructive_hint = false,
            idempotent_hint = true,
            open_world_hint = true
        )
    )]
    async fn account_status(&self) -> String {
        self.backend.run(&["status"]).await
    }

    #[tool(
        name = "pods_list",
        description = "List RunPod pods visible to the configured account. Does not create or modify resources.",
        annotations(
            title = "List pods",
            read_only_hint = true,
            destructive_hint = false,
            idempotent_hint = true,
            open_world_hint = true
        )
    )]
    async fn pods_list(&self) -> String {
        self.backend.run(&["list"]).await
    }

    #[tool(
        name = "pod_get",
        description = "Get the provider record for one exact pod ID. Does not modify the pod.",
        annotations(
            title = "Get pod",
            read_only_hint = true,
            destructive_hint = false,
            idempotent_hint = true,
            open_world_hint = true
        )
    )]
    async fn pod_get(&self, Parameters(request): Parameters<PodIdRequest>) -> String {
        self.backend.run(&["get", &request.pod_id]).await
    }

    #[tool(
        name = "gpus_list",
        description = "List RunPod GPU types, optionally filtering to currently available entries.",
        annotations(
            title = "List GPUs",
            read_only_hint = true,
            destructive_hint = false,
            idempotent_hint = true,
            open_world_hint = true
        )
    )]
    async fn gpus_list(&self, Parameters(request): Parameters<GpusRequest>) -> String {
        if request.available_only {
            self.backend.run(&["gpus", "--available"]).await
        } else {
            self.backend.run(&["gpus"]).await
        }
    }

    #[tool(
        name = "pod_connect_info",
        description = "Resolve and print SSH connection information for one pod. Does not open a connection or modify the pod.",
        annotations(
            title = "Pod connection info",
            read_only_hint = true,
            destructive_hint = false,
            idempotent_hint = true,
            open_world_hint = true
        )
    )]
    async fn pod_connect_info(&self, Parameters(request): Parameters<PodIdRequest>) -> String {
        self.backend.run(&["connect", &request.pod_id]).await
    }
}

#[tool_handler(router = self.tool_router)]
impl ServerHandler for ControlService {
    fn get_info(&self) -> ServerInfo {
        ServerInfo::new(ServerCapabilities::builder().enable_tools().build()).with_instructions(
            "Read-only water-spider control-plane tools. This profile cannot create, mutate, or delete RunPod resources.",
        )
    }
}

#[derive(Debug, Clone)]
struct NodeService {
    models_dir: PathBuf,
    image_metadata: PathBuf,
    tool_router: ToolRouter<Self>,
}

impl NodeService {
    fn from_env() -> Self {
        Self {
            models_dir: std::env::var_os("WATER_SPIDER_MODELS_DIR")
                .map(PathBuf::from)
                .unwrap_or_else(|| PathBuf::from("/workspace/scratch/models")),
            image_metadata: std::env::var_os("WATER_SPIDER_IMAGE_METADATA")
                .map(PathBuf::from)
                .unwrap_or_else(|| PathBuf::from("/etc/water-spider-image.json")),
            tool_router: Self::tool_router(),
        }
    }

    async fn fixed_command(program: &str, args: &[&str]) -> Value {
        match Command::new(program).args(args).output().await {
            Ok(output) => json!({
                "ok": output.status.success(),
                "exit_code": output.status.code(),
                "stdout": String::from_utf8_lossy(&output.stdout).trim(),
                "stderr": String::from_utf8_lossy(&output.stderr).trim(),
            }),
            Err(error) => json!({"ok": false, "error": error.to_string()}),
        }
    }
}

#[tool_router]
impl NodeService {
    #[tool(
        name = "node_status",
        description = "Inspect this water-spider image, hostname, kernel, and workspace disk without modifying the pod.",
        annotations(
            title = "Node status",
            read_only_hint = true,
            destructive_hint = false,
            idempotent_hint = true,
            open_world_hint = false
        )
    )]
    async fn node_status(&self) -> String {
        let image = tokio::fs::read_to_string(&self.image_metadata)
            .await
            .ok()
            .and_then(|text| serde_json::from_str::<Value>(&text).ok());
        let hostname = Self::fixed_command("hostname", &[]).await;
        let kernel = Self::fixed_command("uname", &["-srmo"]).await;
        let disk = Self::fixed_command("df", &["-h", "/workspace"]).await;
        json!({"image": image, "hostname": hostname, "kernel": kernel, "workspace_disk": disk})
            .to_string()
    }

    #[tool(
        name = "gpu_status",
        description = "Inspect GPUs attached to this pod through a fixed nvidia-smi query. Does not change clocks or processes.",
        annotations(
            title = "GPU status",
            read_only_hint = true,
            destructive_hint = false,
            idempotent_hint = true,
            open_world_hint = false
        )
    )]
    async fn gpu_status(&self) -> String {
        Self::fixed_command(
            "nvidia-smi",
            &[
                "--query-gpu=index,name,uuid,memory.used,memory.total,utilization.gpu,temperature.gpu,power.draw",
                "--format=csv,noheader,nounits",
            ],
        )
        .await
        .to_string()
    }

    #[tool(
        name = "models_list",
        description = "List regular files in the configured pod model directory. Does not read model contents or access the network.",
        annotations(
            title = "List models",
            read_only_hint = true,
            destructive_hint = false,
            idempotent_hint = true,
            open_world_hint = false
        )
    )]
    async fn models_list(&self) -> String {
        let mut entries = Vec::new();
        match tokio::fs::read_dir(&self.models_dir).await {
            Ok(mut directory) => loop {
                match directory.next_entry().await {
                    Ok(Some(entry)) => match entry.metadata().await {
                        Ok(metadata) if metadata.is_file() => entries.push(json!({
                            "name": entry.file_name().to_string_lossy(),
                            "bytes": metadata.len(),
                        })),
                        Ok(_) => {}
                        Err(error) => {
                            return json!({"ok": false, "error": error.to_string()}).to_string();
                        }
                    },
                    Ok(None) => break,
                    Err(error) => {
                        return json!({"ok": false, "error": error.to_string()}).to_string();
                    }
                }
            },
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
                return json!({"ok": true, "directory": self.models_dir, "models": []}).to_string();
            }
            Err(error) => return json!({"ok": false, "error": error.to_string()}).to_string(),
        }
        entries.sort_by(|left, right| left["name"].as_str().cmp(&right["name"].as_str()));
        json!({"ok": true, "directory": self.models_dir, "models": entries}).to_string()
    }
}

#[tool_handler(router = self.tool_router)]
impl ServerHandler for NodeService {
    fn get_info(&self) -> ServerInfo {
        ServerInfo::new(ServerCapabilities::builder().enable_tools().build()).with_instructions(
            "Read-only tools for the current water-spider pod. This profile has no RunPod lifecycle or arbitrary shell tool.",
        )
    }
}

async fn serve_stdio(profile: Profile) -> Result<()> {
    match profile {
        Profile::Control => {
            ControlService::new(CliBackend::from_env())
                .serve(rmcp::transport::stdio())
                .await?
                .waiting()
                .await?
        }
        Profile::Node => {
            NodeService::from_env()
                .serve(rmcp::transport::stdio())
                .await?
                .waiting()
                .await?
        }
    };
    Ok(())
}

async fn serve_http(profile: Profile, listen: SocketAddr) -> Result<()> {
    if !listen.ip().is_loopback() {
        bail!("refusing non-loopback MCP listener {listen}; use an SSH tunnel instead");
    }

    let cancellation = CancellationToken::new();
    let config = StreamableHttpServerConfig::default()
        .with_stateful_mode(false)
        .with_json_response(true)
        .with_sse_keep_alive(None)
        .with_cancellation_token(cancellation.child_token());

    let router = match profile {
        Profile::Control => {
            let service: StreamableHttpService<ControlService, LocalSessionManager> =
                StreamableHttpService::new(
                    || Ok(ControlService::new(CliBackend::from_env())),
                    Default::default(),
                    config,
                );
            Router::new().nest_service("/mcp", service)
        }
        Profile::Node => {
            let service: StreamableHttpService<NodeService, LocalSessionManager> =
                StreamableHttpService::new(
                    || Ok(NodeService::from_env()),
                    Default::default(),
                    config,
                );
            Router::new().nest_service("/mcp", service)
        }
    };

    let listener = tokio::net::TcpListener::bind(listen)
        .await
        .with_context(|| format!("failed to bind {listen}"))?;
    tracing::info!(profile = ?profile, endpoint = %format!("http://{listen}/mcp"), "MCP server listening");

    axum::serve(listener, router)
        .with_graceful_shutdown(async move {
            let _ = tokio::signal::ctrl_c().await;
            cancellation.cancel();
        })
        .await?;
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_writer(std::io::stderr)
        .init();

    match args.transport {
        Transport::Stdio => serve_stdio(args.profile).await,
        Transport::Http => serve_http(args.profile, args.listen).await,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::PermissionsExt;

    fn temporary_directory(name: &str) -> PathBuf {
        let directory = std::env::temp_dir().join(format!(
            "water-spider-mcp-{name}-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        std::fs::create_dir_all(&directory).unwrap();
        directory
    }

    #[tokio::test]
    async fn control_backend_passes_fixed_arguments_without_a_shell() {
        let directory = temporary_directory("backend");
        let fake = directory.join("water-spider");
        std::fs::write(&fake, "#!/bin/sh\nprintf '%s\\n' \"$@\"\n").unwrap();
        std::fs::set_permissions(&fake, std::fs::Permissions::from_mode(0o755)).unwrap();
        let backend = CliBackend { executable: fake };

        let result: Value =
            serde_json::from_str(&backend.run(&["get", "pod;echo unsafe"]).await).unwrap();
        assert_eq!(result["ok"], true);
        assert_eq!(result["stdout"], "get\npod;echo unsafe");
        std::fs::remove_dir_all(directory).unwrap();
    }

    #[tokio::test]
    async fn models_list_is_sorted_and_reports_sizes() {
        let directory = temporary_directory("models");
        std::fs::write(directory.join("z.gguf"), b"1234").unwrap();
        std::fs::write(directory.join("a.gguf"), b"12").unwrap();
        let service = NodeService {
            models_dir: directory.clone(),
            image_metadata: directory.join("missing.json"),
            tool_router: NodeService::tool_router(),
        };

        let result: Value = serde_json::from_str(&service.models_list().await).unwrap();
        assert_eq!(result["models"][0]["name"], "a.gguf");
        assert_eq!(result["models"][0]["bytes"], 2);
        assert_eq!(result["models"][1]["name"], "z.gguf");
        std::fs::remove_dir_all(directory).unwrap();
    }

    #[test]
    fn http_listener_must_be_loopback() {
        let public: SocketAddr = "0.0.0.0:8765".parse().unwrap();
        assert!(!public.ip().is_loopback());
        let local: SocketAddr = "127.0.0.1:8765".parse().unwrap();
        assert!(local.ip().is_loopback());
    }
}
