# State

Updated: 2026-08-16T11:06:09-05:00

water-spider release automation is active with exact-tag no-op protection and isolated bump tests. CI covers the full shell surface at ShellCheck 0.10.0. GitHub fleet-default protection blocks deletion and force-push of main; git-ops governs task worktrees. WATERS-020 connects local Mayfly and OpenCode workers to a tunneled, loopback-only v2 llama.cpp tool endpoint. A Community RTX A4000 run proved the endpoint/template path but found the published image missing CUDA architecture 8.6; the build default now includes it, pending release and live GPU revalidation. Remaining billable product validation includes this recheck and WATERS-003.
