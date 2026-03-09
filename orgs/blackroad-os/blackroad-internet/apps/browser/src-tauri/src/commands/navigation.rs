use serde::{Deserialize, Serialize};
use tauri::{command, State};

use crate::store::AppStore;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct PageInfo {
    pub url: String,
    pub title: String,
    pub is_secure: bool,
    pub is_search: bool,
}

fn normalize_url(input: &str) -> PageInfo {
    let trimmed = input.trim();

    // Internal pages
    if trimmed.starts_with("blackroad://") {
        return PageInfo {
            url: trimmed.to_string(),
            title: String::new(),
            is_secure: true,
            is_search: false,
        };
    }

    // Already a URL
    if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
        return PageInfo {
            url: trimmed.to_string(),
            title: String::new(),
            is_secure: trimmed.starts_with("https"),
            is_search: false,
        };
    }

    // Looks like a domain (has a dot, no spaces)
    if trimmed.contains('.') && !trimmed.contains(' ') {
        let url = format!("https://{}", trimmed);
        return PageInfo {
            url,
            title: String::new(),
            is_secure: true,
            is_search: false,
        };
    }

    // Treat as search query
    let encoded = urlencoding::encode(trimmed);
    PageInfo {
        url: format!("blackroad://search?q={}", encoded),
        title: String::new(),
        is_secure: true,
        is_search: true,
    }
}

#[command]
pub async fn navigate_to(url: String, store: State<'_, AppStore>) -> Result<PageInfo, String> {
    let page_info = normalize_url(&url);

    // Record in history
    if !page_info.url.starts_with("blackroad://") {
        let db = store.db.lock().map_err(|e| e.to_string())?;
        db.execute(
            "INSERT INTO history (url, title) VALUES (?1, ?2)",
            rusqlite::params![page_info.url, page_info.title],
        )
        .map_err(|e| e.to_string())?;
    }

    Ok(page_info)
}

#[command]
pub async fn go_back() -> Result<Option<String>, String> {
    // Navigation stack managed by frontend in Phase 1
    Ok(None)
}

#[command]
pub async fn go_forward() -> Result<Option<String>, String> {
    Ok(None)
}

#[command]
pub async fn refresh_page() -> Result<(), String> {
    Ok(())
}
