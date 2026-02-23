use std::time::Duration;
use tokio::time::sleep;

pub async fn run(interval: u64) {
    println!("\x1b[36m● BlackRoad OS — Live Monitor ({}s refresh)\x1b[0m\n", interval);
    let mut tick = 0u64;
    loop {
        // Clear screen and move to top
        print!("\x1b[2J\x1b[H");
        println!("\x1b[36m╔══════════════════════════════════════════╗\x1b[0m");
        println!("\x1b[36m║  \x1b[1mBlackRoad OS — Watch Mode\x1b[0m             \x1b[36m║\x1b[0m");
        println!("\x1b[36m╠══════════════════════════════════════════╣\x1b[0m");

        // System stats via shell commands
        let load = std::process::Command::new("sh")
            .arg("-c").arg("uptime | awk -F'load average:' '{print $2}'")
            .output().map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or("?".into());

        let mem = std::process::Command::new("sh")
            .arg("-c").arg("vm_stat 2>/dev/null | awk '/Pages active/{print $3+0}' || free -m 2>/dev/null | awk '/Mem:/{print $3\"MB\"}'")
            .output().map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or("?".into());

        println!("\x1b[36m║\x1b[0m  Load: {:35} \x1b[36m║\x1b[0m", load);
        println!("\x1b[36m║\x1b[0m  Mem:  {:35} \x1b[36m║\x1b[0m", mem);
        println!("\x1b[36m║\x1b[0m  Tick: {:35} \x1b[36m║\x1b[0m", tick);
        println!("\x1b[36m╚══════════════════════════════════════════╝\x1b[0m");
        println!("  Press Ctrl+C to stop");

        tick += 1;
        sleep(Duration::from_secs(interval)).await;
    }
}
