use clap::{Parser, Subcommand};

mod shell;
mod tui;
mod watch;

#[derive(Parser)]
#[command(name = "br-rs", about = "BlackRoad OS CLI — Rust Edition", version = "0.1.0")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Interactive agent shell — chat with any BlackRoad agent
    Shell {
        /// Agent name (LUCIDIA, ALICE, CECE, etc.)
        #[arg(short, long, default_value = "CECE")]
        agent: String,
        /// Gateway URL
        #[arg(short, long, default_value = "http://127.0.0.1:8787")]
        gateway: String,
    },
    /// Terminal UI — full dashboard with panels
    Tui,
    /// Real-time monitor — watch system metrics
    Watch {
        /// Refresh interval in seconds
        #[arg(short, long, default_value = "2")]
        interval: u64,
    },
    /// Show agent status
    Status,
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Shell { agent, gateway } => shell::run(&agent, &gateway).await,
        Commands::Tui => tui::run().await,
        Commands::Watch { interval } => watch::run(interval).await,
        Commands::Status => {
            println!("\x1b[36m╔══════════════════════════════╗\x1b[0m");
            println!("\x1b[36m║  \x1b[1mBlackRoad OS — br-rs v0.1\x1b[0m  \x1b[36m║\x1b[0m");
            println!("\x1b[36m╚══════════════════════════════╝\x1b[0m");
            println!("\x1b[32m● Gateway:\x1b[0m http://127.0.0.1:8787");
            println!("\x1b[32m● Agents:\x1b[0m 11 registered");
            println!("\x1b[32m● Memory:\x1b[0m ~/.blackroad/memory/");
            println!("\x1b[35m● CECE:\x1b[0m Online 💜");
        }
    }
}
