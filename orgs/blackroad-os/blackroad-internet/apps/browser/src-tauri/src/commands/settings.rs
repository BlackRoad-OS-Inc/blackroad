use serde::{Deserialize, Serialize};
use tauri::command;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct BrowserSettings {
    pub verification_enabled: bool,
    pub sidebar_position: String,
    pub theme: String,
    pub default_search: String,
}

impl Default for BrowserSettings {
    fn default() -> Self {
        Self {
            verification_enabled: true,
            sidebar_position: "right".to_string(),
            theme: "dark".to_string(),
            default_search: "blackroad".to_string(),
        }
    }
}

#[command]
pub async fn get_settings() -> Result<BrowserSettings, String> {
    Ok(BrowserSettings::default())
}

#[command]
pub async fn update_settings(settings: BrowserSettings) -> Result<BrowserSettings, String> {
    // Phase 1: Just echo back. Phase 2: persist to SQLite.
    Ok(settings)
}
