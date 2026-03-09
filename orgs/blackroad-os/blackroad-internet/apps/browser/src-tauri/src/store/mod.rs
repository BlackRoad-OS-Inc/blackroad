use rusqlite::Connection;
use std::sync::Mutex;
use tauri::AppHandle;
use tauri::Manager;

pub struct AppStore {
    pub db: Mutex<Connection>,
}

pub fn init(app: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
    let app_dir = app.path().app_data_dir()?;
    std::fs::create_dir_all(&app_dir)?;

    let db_path = app_dir.join("blackroad-internet.db");
    let conn = Connection::open(db_path)?;

    conn.execute_batch(
        "
        CREATE TABLE IF NOT EXISTS history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            title TEXT DEFAULT '',
            visited_at TEXT DEFAULT (datetime('now')),
            verification_score REAL
        );

        CREATE TABLE IF NOT EXISTS bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL UNIQUE,
            title TEXT DEFAULT '',
            folder TEXT DEFAULT 'default',
            created_at TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS source_reputation (
            domain TEXT PRIMARY KEY,
            score REAL DEFAULT 0.5,
            total_checks INTEGER DEFAULT 0,
            last_checked TEXT,
            category TEXT
        );

        CREATE TABLE IF NOT EXISTS verification_cache (
            url TEXT PRIMARY KEY,
            result_json TEXT NOT NULL,
            cached_at TEXT DEFAULT (datetime('now')),
            expires_at TEXT
        );

        CREATE INDEX IF NOT EXISTS idx_history_url ON history(url);
        CREATE INDEX IF NOT EXISTS idx_history_visited ON history(visited_at);
    ",
    )?;

    app.manage(AppStore {
        db: Mutex::new(conn),
    });
    Ok(())
}
