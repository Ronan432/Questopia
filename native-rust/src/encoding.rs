use encoding_rs::Encoding;

pub fn decode_bytes_with_charset(bytes: &[u8], charset: &str) -> String {
    let encoding = Encoding::for_label(charset.as_bytes()).unwrap_or(encoding_rs::UTF_8);
    let (cow, _, _) = encoding.decode(bytes);
    cow.into_owned()
}
