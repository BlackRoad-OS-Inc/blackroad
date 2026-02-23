use std::io::{self, Write};

pub async fn run(agent: &str, gateway: &str) {
    println!("\x1b[35m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1b[0m");
    println!("\x1b[35m  {} Agent Shell — BlackRoad OS\x1b[0m", agent);
    println!("\x1b[35m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1b[0m");
    println!("  Gateway: {}", gateway);
    println!("  Type 'exit' to quit\n");

    loop {
        print!("\x1b[36m{} ❯\x1b[0m ", agent);
        io::stdout().flush().unwrap();

        let mut input = String::new();
        if io::stdin().read_line(&mut input).is_err() { break; }
        let input = input.trim();

        if input == "exit" || input == "quit" { break; }
        if input.is_empty() { continue; }

        // Try gateway, fall back to echo
        let response = try_gateway(gateway, agent, input).await
            .unwrap_or_else(|_| format!("[{}] Gateway offline. Message queued: '{}'", agent, input));

        println!("\x1b[35m{}\x1b[0m {}\n", agent, response);
    }
    println!("\x1b[36mSession ended.\x1b[0m");
}

async fn try_gateway(gateway: &str, agent: &str, message: &str) -> Result<String, Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();
    let resp = client.post(&format!("{}/chat", gateway))
        .json(&serde_json::json!({
            "agent": agent,
            "message": message
        }))
        .timeout(std::time::Duration::from_secs(10))
        .send()
        .await?;
    let body: serde_json::Value = resp.json().await?;
    Ok(body["response"].as_str().unwrap_or("...").to_string())
}
