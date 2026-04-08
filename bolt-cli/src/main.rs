//! bolt-cli: Non-core CLI consumer for bolt-daemon IPC.
//!
//! NONCORE-ADOPTER-1 validation artifact. All IPC types are independently
//! defined from docs/IPC_CONTRACT.md — no bolt-daemon or bolt-core imports.

use std::io::{self, BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;

// ── IPC Types (independently defined from IPC_CONTRACT.md) ─────

#[allow(dead_code)] // Fields exist for contract completeness per IPC_CONTRACT.md
mod ipc {
    use serde::{Deserialize, Serialize};

    /// Top-level IPC message envelope.
    #[derive(Serialize, Deserialize, Debug, Clone)]
    pub struct IpcMessage {
        pub id: String,
        pub kind: IpcKind,
        #[serde(rename = "type")]
        pub msg_type: String,
        pub ts_ms: u64,
        pub payload: serde_json::Value,
    }

    /// Message direction.
    #[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq)]
    #[serde(rename_all = "snake_case")]
    pub enum IpcKind {
        Event,
        Decision,
    }

    /// Decision variants.
    #[derive(Serialize, Deserialize, Debug, Clone, Copy)]
    #[serde(rename_all = "snake_case")]
    pub enum Decision {
        AllowOnce,
        AllowAlways,
        DenyOnce,
        DenyAlways,
    }

    // ── Event Payloads (daemon → consumer) ──

    #[derive(Deserialize, Debug)]
    pub struct VersionStatusPayload {
        pub daemon_version: String,
        pub compatible: bool,
    }

    #[derive(Deserialize, Debug)]
    pub struct DaemonStatusPayload {
        pub connected_peers: u32,
        pub ui_connected: bool,
        pub version: String,
    }

    #[derive(Deserialize, Debug)]
    pub struct SessionConnectedPayload {
        pub remote_peer_id: String,
        pub negotiated_capabilities: Vec<String>,
    }

    #[derive(Deserialize, Debug)]
    pub struct SessionSasPayload {
        pub sas: String,
        pub remote_identity_pk_b64: String,
    }

    #[derive(Deserialize, Debug)]
    pub struct SessionErrorPayload {
        pub reason: String,
    }

    #[derive(Deserialize, Debug)]
    pub struct SessionEndedPayload {
        pub reason: String,
    }

    #[derive(Deserialize, Debug)]
    pub struct PairingRequestPayload {
        pub request_id: String,
        pub remote_device_name: String,
        pub remote_device_type: String,
        pub remote_identity_pk_b64: String,
        pub sas: String,
        pub capabilities_requested: Vec<String>,
    }

    #[derive(Deserialize, Debug)]
    pub struct TransferIncomingRequestPayload {
        pub request_id: String,
        pub from_device_name: String,
        pub from_identity_pk_b64: String,
        pub file_name: String,
        pub file_size_bytes: u64,
        pub sha256_hex: Option<String>,
        pub mime: Option<String>,
    }

    #[derive(Deserialize, Debug)]
    pub struct TransferStartedPayload {
        pub transfer_id: String,
        pub file_name: String,
        pub file_size_bytes: u64,
        pub direction: String,
    }

    #[derive(Deserialize, Debug)]
    pub struct TransferProgressPayload {
        pub transfer_id: String,
        pub bytes_transferred: u64,
        pub total_bytes: u64,
        pub progress: f32,
    }

    #[derive(Deserialize, Debug)]
    pub struct TransferCompletePayload {
        pub transfer_id: String,
        pub file_name: String,
        pub bytes_transferred: u64,
        pub verified: bool,
    }

    // ── Decision Payloads (consumer → daemon) ──

    #[derive(Serialize, Debug)]
    pub struct DecisionPayload {
        pub request_id: String,
        pub decision: Decision,
        pub note: Option<String>,
    }

    // ── Helpers ──

    fn now_ms() -> u64 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis() as u64
    }

    static MSG_COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

    impl IpcMessage {
        /// Create a new decision message.
        pub fn new_decision(msg_type: &str, payload: serde_json::Value) -> Self {
            let n = MSG_COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
            Self {
                id: format!("cli-{n}"),
                kind: IpcKind::Decision,
                msg_type: msg_type.to_string(),
                ts_ms: now_ms(),
                payload,
            }
        }

        /// Serialize to NDJSON line (with trailing newline).
        pub fn to_ndjson(&self) -> Result<String, serde_json::Error> {
            let mut s = serde_json::to_string(self)?;
            s.push('\n');
            Ok(s)
        }
    }
}

// ── CLI ────────────────────────────────────────────────────────

const DEFAULT_SOCKET: &str = "/tmp/bolt-daemon.sock";
const CLI_VERSION: &str = env!("CARGO_PKG_VERSION");

fn main() {
    let socket_path = parse_args();

    eprintln!("[bolt-cli] connecting to {socket_path}");

    let stream = match UnixStream::connect(&socket_path) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("[bolt-cli] connection failed: {e}");
            eprintln!("[bolt-cli] is bolt-daemon running? check: ls -la {socket_path}");
            std::process::exit(1);
        }
    };

    eprintln!("[bolt-cli] connected");

    // Clone for writer; original becomes reader.
    let write_stream = match stream.try_clone() {
        Ok(s) => s,
        Err(e) => {
            eprintln!("[bolt-cli] failed to clone stream: {e}");
            std::process::exit(1);
        }
    };

    let mut reader = BufReader::new(stream);
    let mut writer = io::BufWriter::new(write_stream);

    // ── Phase 1: Version Handshake ──
    if !do_handshake(&mut reader, &mut writer) {
        std::process::exit(1);
    }

    // ── Phase 2: Event Loop ──
    event_loop(&mut reader, &mut writer);
}

fn parse_args() -> String {
    let args: Vec<String> = std::env::args().collect();
    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--socket" => {
                i += 1;
                if i < args.len() {
                    return args[i].clone();
                }
                eprintln!("--socket requires a path argument");
                std::process::exit(1);
            }
            "--help" | "-h" => {
                println!("bolt-cli — non-core CLI consumer for bolt-daemon IPC");
                println!();
                println!("Usage: bolt-cli [--socket <path>]");
                println!();
                println!("Options:");
                println!("  --socket <path>  Unix socket path (default: {DEFAULT_SOCKET})");
                println!("  --help, -h       Show this help");
                std::process::exit(0);
            }
            other => {
                eprintln!("unknown argument: {other}");
                eprintln!("usage: bolt-cli [--socket <path>]");
                std::process::exit(1);
            }
        }
    }
    DEFAULT_SOCKET.to_string()
}

fn do_handshake(
    reader: &mut BufReader<UnixStream>,
    writer: &mut io::BufWriter<UnixStream>,
) -> bool {
    // Send version.handshake
    let handshake = ipc::IpcMessage::new_decision(
        "version.handshake",
        serde_json::json!({ "app_version": CLI_VERSION }),
    );
    if let Err(e) = send_message(writer, &handshake) {
        eprintln!("[bolt-cli] failed to send handshake: {e}");
        return false;
    }

    // Read version.status response
    let msg = match read_message(reader) {
        Some(m) => m,
        None => {
            eprintln!("[bolt-cli] no response to handshake — daemon may be incompatible");
            return false;
        }
    };

    if msg.msg_type != "version.status" {
        eprintln!(
            "[bolt-cli] expected version.status, got {} — aborting",
            msg.msg_type
        );
        return false;
    }

    let status: ipc::VersionStatusPayload = match serde_json::from_value(msg.payload) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("[bolt-cli] malformed version.status: {e}");
            return false;
        }
    };

    if !status.compatible {
        eprintln!(
            "[bolt-cli] version incompatible — cli={CLI_VERSION} daemon={}",
            status.daemon_version
        );
        return false;
    }

    eprintln!(
        "[bolt-cli] handshake OK — daemon v{}",
        status.daemon_version
    );

    // Read daemon.status
    if let Some(ds_msg) = read_message(reader) {
        if ds_msg.msg_type == "daemon.status" {
            if let Ok(ds) =
                serde_json::from_value::<ipc::DaemonStatusPayload>(ds_msg.payload)
            {
                println!(
                    "[status] daemon v{} | peers: {} | ui: connected",
                    ds.version, ds.connected_peers
                );
            }
        }
    }

    true
}

fn event_loop(reader: &mut BufReader<UnixStream>, writer: &mut io::BufWriter<UnixStream>) {
    println!("[bolt-cli] listening for events (Ctrl+C to quit)");
    println!();

    loop {
        let msg = match read_message(reader) {
            Some(m) => m,
            None => {
                eprintln!("[bolt-cli] daemon disconnected");
                return;
            }
        };

        handle_event(msg, writer);
    }
}

fn handle_event(msg: ipc::IpcMessage, writer: &mut io::BufWriter<UnixStream>) {
    match msg.msg_type.as_str() {
        "daemon.status" => {
            if let Ok(p) =
                serde_json::from_value::<ipc::DaemonStatusPayload>(msg.payload)
            {
                println!(
                    "[status] peers: {} | ui: {}",
                    p.connected_peers,
                    if p.ui_connected { "connected" } else { "disconnected" }
                );
            }
        }

        "session.connected" => {
            if let Ok(p) =
                serde_json::from_value::<ipc::SessionConnectedPayload>(msg.payload)
            {
                let key_prefix = &p.remote_peer_id[..8.min(p.remote_peer_id.len())];
                println!(
                    "[session] peer connected — key: {}... caps: {:?}",
                    key_prefix, p.negotiated_capabilities
                );
            }
        }

        "session.sas" => {
            if let Ok(p) = serde_json::from_value::<ipc::SessionSasPayload>(msg.payload)
            {
                let key_prefix =
                    &p.remote_identity_pk_b64[..8.min(p.remote_identity_pk_b64.len())];
                println!();
                println!("  ┌─────────────────────────────────┐");
                println!("  │  Verification Code:  {}  │", p.sas);
                println!("  │  Remote key: {}...           │", key_prefix);
                println!("  └─────────────────────────────────┘");
                println!();
            }
        }

        "session.error" => {
            if let Ok(p) =
                serde_json::from_value::<ipc::SessionErrorPayload>(msg.payload)
            {
                println!("[session] ERROR: {}", p.reason);
            }
        }

        "session.ended" => {
            if let Ok(p) =
                serde_json::from_value::<ipc::SessionEndedPayload>(msg.payload)
            {
                println!("[session] ended: {}", p.reason);
            }
        }

        "pairing.request" => {
            if let Ok(p) =
                serde_json::from_value::<ipc::PairingRequestPayload>(msg.payload)
            {
                println!();
                println!("  ╔═══════════════════════════════════╗");
                println!("  ║        PAIRING REQUEST            ║");
                println!("  ╠═══════════════════════════════════╣");
                println!("  ║  Device: {:<25} ║", p.remote_device_name);
                println!("  ║  Type:   {:<25} ║", p.remote_device_type);
                println!("  ║  SAS:    {:<25} ║", p.sas);
                println!("  ╚═══════════════════════════════════╝");
                println!();

                let decision = prompt_decision("Accept pairing?");
                let payload = ipc::DecisionPayload {
                    request_id: p.request_id,
                    decision,
                    note: None,
                };
                let resp = ipc::IpcMessage::new_decision(
                    "pairing.decision",
                    serde_json::to_value(&payload).unwrap(),
                );
                if let Err(e) = send_message(writer, &resp) {
                    eprintln!("[bolt-cli] failed to send pairing decision: {e}");
                }
            }
        }

        "transfer.incoming.request" => {
            if let Ok(p) = serde_json::from_value::<ipc::TransferIncomingRequestPayload>(
                msg.payload,
            ) {
                let size = format_bytes(p.file_size_bytes);
                println!();
                println!("  ╔═══════════════════════════════════╗");
                println!("  ║      INCOMING TRANSFER            ║");
                println!("  ╠═══════════════════════════════════╣");
                println!("  ║  From: {:<27} ║", p.from_device_name);
                println!("  ║  File: {:<27} ║", p.file_name);
                println!("  ║  Size: {:<27} ║", size);
                if let Some(ref mime) = p.mime {
                    println!("  ║  Type: {:<27} ║", mime);
                }
                println!("  ╚═══════════════════════════════════╝");
                println!();

                let decision = prompt_decision("Accept transfer?");
                let payload = ipc::DecisionPayload {
                    request_id: p.request_id,
                    decision,
                    note: None,
                };
                let resp = ipc::IpcMessage::new_decision(
                    "transfer.incoming.decision",
                    serde_json::to_value(&payload).unwrap(),
                );
                if let Err(e) = send_message(writer, &resp) {
                    eprintln!("[bolt-cli] failed to send transfer decision: {e}");
                }
            }
        }

        "transfer.started" => {
            if let Ok(p) =
                serde_json::from_value::<ipc::TransferStartedPayload>(msg.payload)
            {
                let size = format_bytes(p.file_size_bytes);
                println!(
                    "[transfer] started: {} ({}) [{}]",
                    p.file_name, size, p.direction
                );
            }
        }

        "transfer.progress" => {
            if let Ok(p) =
                serde_json::from_value::<ipc::TransferProgressPayload>(msg.payload)
            {
                let pct = (p.progress * 100.0) as u32;
                let transferred = format_bytes(p.bytes_transferred);
                let total = format_bytes(p.total_bytes);
                // Overwrite line for progress updates
                print!("\r[transfer] {transferred} / {total} ({pct}%)    ");
                let _ = io::stdout().flush();
            }
        }

        "transfer.complete" => {
            if let Ok(p) =
                serde_json::from_value::<ipc::TransferCompletePayload>(msg.payload)
            {
                println!(); // newline after progress overwrites
                let verified_str = if p.verified { "verified" } else { "UNVERIFIED" };
                let size = format_bytes(p.bytes_transferred);
                println!(
                    "[transfer] complete: {} ({}) [{}]",
                    p.file_name, size, verified_str
                );
            }
        }

        "version.status" => {
            // May arrive again in some flows; log it.
            if let Ok(p) =
                serde_json::from_value::<ipc::VersionStatusPayload>(msg.payload)
            {
                eprintln!(
                    "[bolt-cli] version.status: daemon={} compatible={}",
                    p.daemon_version, p.compatible
                );
            }
        }

        other => {
            eprintln!("[bolt-cli] unknown event: {other}");
        }
    }
}

// ── I/O Helpers ────────────────────────────────────────────────

fn read_message(reader: &mut BufReader<UnixStream>) -> Option<ipc::IpcMessage> {
    let mut line = String::new();
    match reader.read_line(&mut line) {
        Ok(0) => None, // EOF
        Ok(_) => {
            let trimmed = line.trim();
            if trimmed.is_empty() {
                // Skip empty lines, try again
                return read_message(reader);
            }
            match serde_json::from_str::<ipc::IpcMessage>(trimmed) {
                Ok(msg) => Some(msg),
                Err(e) => {
                    eprintln!("[bolt-cli] malformed message: {e}");
                    eprintln!("[bolt-cli] raw: {trimmed}");
                    // Continue reading
                    read_message(reader)
                }
            }
        }
        Err(e) => {
            eprintln!("[bolt-cli] read error: {e}");
            None
        }
    }
}

fn send_message(
    writer: &mut io::BufWriter<UnixStream>,
    msg: &ipc::IpcMessage,
) -> io::Result<()> {
    let line = msg
        .to_ndjson()
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
    writer.write_all(line.as_bytes())?;
    writer.flush()
}

fn prompt_decision(prompt: &str) -> ipc::Decision {
    print!("{prompt} [y/n]: ");
    let _ = io::stdout().flush();

    let mut input = String::new();
    if io::stdin().read_line(&mut input).is_err() {
        eprintln!("[bolt-cli] stdin read error — denying");
        return ipc::Decision::DenyOnce;
    }

    match input.trim().to_lowercase().as_str() {
        "y" | "yes" => ipc::Decision::AllowOnce,
        _ => ipc::Decision::DenyOnce,
    }
}

fn format_bytes(bytes: u64) -> String {
    if bytes < 1024 {
        format!("{bytes} B")
    } else if bytes < 1024 * 1024 {
        format!("{:.1} KB", bytes as f64 / 1024.0)
    } else if bytes < 1024 * 1024 * 1024 {
        format!("{:.1} MB", bytes as f64 / (1024.0 * 1024.0))
    } else {
        format!("{:.2} GB", bytes as f64 / (1024.0 * 1024.0 * 1024.0))
    }
}
