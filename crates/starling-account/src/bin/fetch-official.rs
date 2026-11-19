//! Fetch the pinned game's official files from Mojang's public servers, as
//! the Starling Android app does for a player who plays offline: every file
//! checked against the hash its manifest gives. Lays them out the official
//! launcher's way, ready for horizon-prepare.
//!
//! Usage: fetch-official ROOT

use std::path::PathBuf;

fn main() {
    let root = match std::env::args().nth(1) {
        Some(path) => PathBuf::from(path),
        None => {
            eprintln!("Usage: fetch-official ROOT");
            std::process::exit(2);
        }
    };
    let pins = starling_account::files::Pins::starling();
    let wanted = starling_account::files::Wanted {
        server: true,
        libraries: true,
        assets: true,
    };
    let progress = |p: starling_account::files::Progress| {
        if p.bytes_total > 0 {
            let pct = p.bytes as f64 / p.bytes_total as f64 * 100.0;
            eprintln!(
                "{pct:5.1}%  {}/{} files, {:.0}/{:.0} MB",
                p.files,
                p.files_total,
                p.bytes as f64 / 1e6,
                p.bytes_total as f64 / 1e6
            );
        } else {
            eprintln!("  {}/{} files", p.files, p.files_total);
        }
    };
    let cancelled = || false;
    match starling_account::files::download(
        &starling_account::files::Sources::live(),
        &pins,
        &root,
        wanted,
        &progress,
        &cancelled,
    ) {
        Ok(installed) => {
            println!(
                "fetched: root {} client {} server {}",
                installed.root.display(),
                installed.client_jar.display(),
                installed.server_jar.map_or(
                    "-".into(),
                    |p: PathBuf| p.display().to_string()
                )
            );
        }
        Err(e) => {
            eprintln!("fetch failed: {e}");
            std::process::exit(1);
        }
    }
}
