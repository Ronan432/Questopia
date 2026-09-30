pub mod archive;
pub mod audio_mixer;
pub mod html_parser;

use jni::objects::{JClass, JString};
use jni::sys::{jbyteArray, jint, jstring};
use jni::JNIEnv;

// ============================================================================
// Android JNI Exports: org.qp.android.helpers.native_core.RustEngineCore
// ============================================================================

#[no_mangle]
pub extern "system" fn Java_org_qp_android_helpers_native_1core_RustEngineCore_parseHtml(
    mut env: JNIEnv,
    _class: JClass,
    input: JString,
) -> jstring {
    let input_str: String = match env.get_string(&input) {
        Ok(s) => s.into(),
        Err(_) => return env.new_string("").unwrap().into_raw(),
    };

    let result = html_parser::parse_qsp_html(&input_str);
    let json = serde_json::to_string(&result).unwrap_or_default();
    env.new_string(json).unwrap().into_raw()
}

#[no_mangle]
pub extern "system" fn Java_org_qp_android_helpers_native_1core_RustEngineCore_extractArchive(
    mut env: JNIEnv,
    _class: JClass,
    archive_path: JString,
    target_dir: JString,
) -> jint {
    let path: String = match env.get_string(&archive_path) {
        Ok(s) => s.into(),
        Err(_) => return -1,
    };
    let dir: String = match env.get_string(&target_dir) {
        Ok(s) => s.into(),
        Err(_) => return -1,
    };

    match archive::extract_archive_to_dir(&path, &dir) {
        Ok(count) => count as jint,
        Err(_) => -1,
    }
}

#[no_mangle]
pub extern "system" fn Java_org_qp_android_helpers_native_1core_RustEngineCore_readArchiveFile(
    mut env: JNIEnv,
    _class: JClass,
    archive_path: JString,
    entry_path: JString,
) -> jbyteArray {
    let a_path: String = match env.get_string(&archive_path) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };
    let e_path: String = match env.get_string(&entry_path) {
        Ok(s) => s.into(),
        Err(_) => return std::ptr::null_mut(),
    };

    match archive::read_file_from_archive(&a_path, &e_path) {
        Ok(bytes) => {
            let byte_array = env.byte_array_from_slice(&bytes).unwrap();
            byte_array.into_raw()
        }
        Err(_) => std::ptr::null_mut(),
    }
}

// ============================================================================
// Desktop JNI Exports: org.qp.desktop.engine.RustEngineCore
// ============================================================================

#[no_mangle]
pub extern "system" fn Java_org_qp_desktop_engine_RustEngineCore_parseHtml(
    env: JNIEnv,
    _class: JClass,
    input: JString,
) -> jstring {
    Java_org_qp_android_helpers_native_1core_RustEngineCore_parseHtml(env, _class, input)
}

#[no_mangle]
pub extern "system" fn Java_org_qp_desktop_engine_RustEngineCore_extractArchive(
    env: JNIEnv,
    _class: JClass,
    archive_path: JString,
    target_dir: JString,
) -> jint {
    Java_org_qp_android_helpers_native_1core_RustEngineCore_extractArchive(env, _class, archive_path, target_dir)
}

#[no_mangle]
pub extern "system" fn Java_org_qp_desktop_engine_RustEngineCore_readArchiveFile(
    env: JNIEnv,
    _class: JClass,
    archive_path: JString,
    entry_path: JString,
) -> jbyteArray {
    Java_org_qp_android_helpers_native_1core_RustEngineCore_readArchiveFile(env, _class, archive_path, entry_path)
}
