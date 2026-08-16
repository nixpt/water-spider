use std::os::unix::fs::PermissionsExt;

use rmcp::{
    ServiceExt,
    model::CallToolRequestParams,
    transport::{ConfigureCommandExt, StreamableHttpClientTransport, TokioChildProcess},
};
use serde_json::{Value, json};

#[tokio::test]
async fn control_profile_lists_only_control_tools_and_calls_backend() -> anyhow::Result<()> {
    let directory = tempfile::tempdir()?;
    let fake = directory.path().join("water-spider");
    std::fs::write(&fake, "#!/bin/sh\nprintf 'backend:%s\\n' \"$*\"\n")?;
    std::fs::set_permissions(&fake, std::fs::Permissions::from_mode(0o755))?;

    let transport = TokioChildProcess::new(
        tokio::process::Command::new(env!("CARGO_BIN_EXE_water-spider-mcp")).configure(|command| {
            command
                .args(["--profile", "control", "--transport", "stdio"])
                .env("WATER_SPIDER_BIN", &fake);
        }),
    )?;
    let client = ().serve(transport).await?;

    let tools = client.list_all_tools().await?;
    let names: Vec<_> = tools.iter().map(|tool| tool.name.as_ref()).collect();
    assert_eq!(
        names,
        [
            "account_status",
            "gpus_list",
            "pod_connect_info",
            "pod_get",
            "pods_list"
        ]
    );
    assert!(!names.contains(&"node_status"));

    let result = client
        .call_tool(
            CallToolRequestParams::new("pod_get")
                .with_arguments(json!({"pod_id": "pod-123"}).as_object().unwrap().clone()),
        )
        .await?;
    let encoded: Value = serde_json::to_value(result)?;
    let text = encoded["content"][0]["text"].as_str().unwrap();
    let payload: Value = serde_json::from_str(text)?;
    assert_eq!(payload["ok"], true);
    assert_eq!(payload["stdout"], "backend:get pod-123");

    client.cancel().await?;
    Ok(())
}

#[tokio::test]
async fn node_profile_does_not_expose_lifecycle_tools() -> anyhow::Result<()> {
    let directory = tempfile::tempdir()?;
    std::fs::write(directory.path().join("model.gguf"), b"model")?;

    let transport = TokioChildProcess::new(
        tokio::process::Command::new(env!("CARGO_BIN_EXE_water-spider-mcp")).configure(|command| {
            command
                .args(["--profile", "node", "--transport", "stdio"])
                .env("WATER_SPIDER_MODELS_DIR", directory.path());
        }),
    )?;
    let client = ().serve(transport).await?;

    let tools = client.list_all_tools().await?;
    let names: Vec<_> = tools.iter().map(|tool| tool.name.as_ref()).collect();
    assert_eq!(names, ["gpu_status", "models_list", "node_status"]);
    assert!(!names.contains(&"pods_list"));

    client.cancel().await?;
    Ok(())
}

#[tokio::test]
async fn streamable_http_serves_node_tools_on_loopback() -> anyhow::Result<()> {
    let probe = match std::net::TcpListener::bind("127.0.0.1:0") {
        Ok(listener) => listener,
        Err(error) if error.kind() == std::io::ErrorKind::PermissionDenied => {
            // Some repository sandboxes prohibit even loopback listeners. CI
            // and normal hosts execute the protocol path; restricted local
            // runs still exercise stdio and listener-address rejection.
            return Ok(());
        }
        Err(error) => return Err(error.into()),
    };
    let port = probe.local_addr()?.port();
    drop(probe);

    let mut server = tokio::process::Command::new(env!("CARGO_BIN_EXE_water-spider-mcp"))
        .args([
            "--profile",
            "node",
            "--transport",
            "http",
            "--listen",
            &format!("127.0.0.1:{port}"),
        ])
        .kill_on_drop(true)
        .spawn()?;

    let endpoint = format!("http://127.0.0.1:{port}/mcp");
    let mut connected = None;
    for _ in 0..40 {
        match ().serve(StreamableHttpClientTransport::from_uri(endpoint.clone())).await {
            Ok(client) => {
                connected = Some(client);
                break;
            }
            Err(_) => tokio::time::sleep(std::time::Duration::from_millis(25)).await,
        }
    }
    let client = connected.expect("Streamable HTTP server did not become ready");
    let tools = client.list_all_tools().await?;
    let names: Vec<_> = tools.iter().map(|tool| tool.name.as_ref()).collect();
    assert_eq!(names, ["gpu_status", "models_list", "node_status"]);
    client.cancel().await?;
    server.kill().await?;
    Ok(())
}

#[tokio::test]
async fn http_transport_rejects_non_loopback_listener() -> anyhow::Result<()> {
    let output = tokio::process::Command::new(env!("CARGO_BIN_EXE_water-spider-mcp"))
        .args([
            "--profile",
            "node",
            "--transport",
            "http",
            "--listen",
            "0.0.0.0:8765",
        ])
        .output()
        .await?;
    assert!(!output.status.success());
    assert!(String::from_utf8_lossy(&output.stderr).contains("refusing non-loopback"));
    Ok(())
}
