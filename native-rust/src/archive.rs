use std::fs::File;
use std::io::Read;
use std::path::{Path, PathBuf};
use zip::ZipArchive;

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct ArchiveEntryInfo {
    pub name: String,
    pub size: u64,
    pub is_dir: bool,
}

/// Lists all files inside a ZIP archive without decompressing them to disk.
pub fn list_archive_contents(archive_path: &str) -> Result<Vec<ArchiveEntryInfo>, String> {
    let file = File::open(archive_path).map_err(|e| format!("Failed to open archive: {e}"))?;
    let mut zip = ZipArchive::new(file).map_err(|e| format!("Invalid ZIP archive: {e}"))?;
    
    let mut entries = Vec::with_capacity(zip.len());
    for i in 0..zip.len() {
        if let Ok(entry) = zip.by_index(i) {
            entries.push(ArchiveEntryInfo {
                name: entry.name().to_string(),
                size: entry.size(),
                is_dir: entry.is_dir(),
            });
        }
    }
    Ok(entries)
}

/// Reads a specific file directly from a ZIP archive into memory without full disk extraction.
pub fn read_file_from_archive(archive_path: &str, relative_file_path: &str) -> Result<Vec<u8>, String> {
    let file = File::open(archive_path).map_err(|e| format!("Failed to open archive: {e}"))?;
    let mut zip = ZipArchive::new(file).map_err(|e| format!("Invalid ZIP archive: {e}"))?;
    
    let mut entry = zip.by_name(relative_file_path).map_err(|e| format!("File not found in archive: {e}"))?;
    let mut buffer = Vec::with_capacity(entry.size() as usize);
    entry.read_to_end(&mut buffer).map_err(|e| format!("Failed to read entry: {e}"))?;
    Ok(buffer)
}

/// High-throughput streaming extraction of an entire archive with security checks against Zip Slip.
pub fn extract_archive_to_dir(archive_path: &str, target_dir: &str) -> Result<usize, String> {
    let file = File::open(archive_path).map_err(|e| format!("Failed to open archive: {e}"))?;
    let mut zip = ZipArchive::new(file).map_err(|e| format!("Invalid ZIP archive: {e}"))?;
    let base_path = Path::new(target_dir);
    std::fs::create_dir_all(base_path).map_err(|e| format!("Cannot create target dir: {e}"))?;

    let mut extracted_count = 0;
    for i in 0..zip.len() {
        let mut entry = zip.by_index(i).map_err(|e| format!("Corrupted entry {i}: {e}"))?;
        let entry_name = entry.name().replace('\\', "/");
        
        // Security check against directory traversal
        let mut out_path = PathBuf::from(base_path);
        for component in Path::new(&entry_name).components() {
            match component {
                std::path::Component::Normal(c) => out_path.push(c),
                _ => {} // Ignore parent dirs, root prefixes
            }
        }

        if entry.is_dir() {
            std::fs::create_dir_all(&out_path).ok();
        } else {
            if let Some(parent) = out_path.parent() {
                std::fs::create_dir_all(parent).ok();
            }
            let mut out_file = File::create(&out_path).map_err(|e| format!("Failed to create {out_path:?}: {e}"))?;
            std::io::copy(&mut entry, &mut out_file).map_err(|e| format!("Failed to write {out_path:?}: {e}"))?;
            extracted_count += 1;
        }
    }
    Ok(extracted_count)
}
