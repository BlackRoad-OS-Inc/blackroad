mod commands;
mod store;
mod verification;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_http::init())
        .invoke_handler(tauri::generate_handler![
            commands::navigation::navigate_to,
            commands::navigation::go_back,
            commands::navigation::go_forward,
            commands::navigation::refresh_page,
            commands::verification::verify_page,
            commands::verification::get_verification_status,
            commands::verification::verify_claim,
            commands::settings::get_settings,
            commands::settings::update_settings,
        ])
        .setup(|app| {
            store::init(app.handle())?;
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running BlackRoad Internet");
}
