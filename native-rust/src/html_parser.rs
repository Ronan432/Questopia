use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParsedSpan {
    pub start: usize,
    pub end: usize,
    pub is_bold: bool,
    pub is_italic: bool,
    pub is_underline: bool,
    pub color: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FastParsedText {
    pub plain_text: String,
    pub image_urls: Vec<String>,
    pub spans: Vec<ParsedSpan>,
}

/// Ultra-fast scanner that strips tags, extracts images, and records formatting spans.
pub fn parse_qsp_html(input: &str) -> FastParsedText {
    let mut plain_text = String::with_capacity(input.len());
    let mut image_urls = Vec::new();
    let mut spans = Vec::new();

    let mut in_tag = false;
    let mut current_tag = String::with_capacity(32);
    
    let mut bold_start: Option<usize> = None;
    let mut italic_start: Option<usize> = None;
    let mut underline_start: Option<usize> = None;

    let chars: Vec<char> = input.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        if c == '<' {
            in_tag = true;
            current_tag.clear();
        } else if c == '>' && in_tag {
            in_tag = false;
            let tag_lower = current_tag.trim().to_lowercase();
            
            // Check for image tag
            if tag_lower.starts_with("img ") || tag_lower.starts_with("img\t") {
                if let Some(src_pos) = tag_lower.find("src=") {
                    let after_src = &current_tag[src_pos + 4..];
                    let trimmed = after_src.trim();
                    let quote = trimmed.chars().next();
                    if quote == Some('"') || quote == Some('\'') {
                        let q = quote.unwrap();
                        if let Some(end_quote) = trimmed[1..].find(q) {
                            let url = &trimmed[1..=end_quote];
                            image_urls.push(url.to_string());
                        }
                    } else {
                        let url = trimmed.split_whitespace().next().unwrap_or("");
                        if !url.is_empty() {
                            image_urls.push(url.to_string());
                        }
                    }
                }
            } else if tag_lower == "b" || tag_lower == "strong" {
                bold_start = Some(plain_text.len());
            } else if tag_lower == "/b" || tag_lower == "/strong" {
                if let Some(start) = bold_start.take() {
                    spans.push(ParsedSpan {
                        start,
                        end: plain_text.len(),
                        is_bold: true,
                        is_italic: false,
                        is_underline: false,
                        color: None,
                    });
                }
            } else if tag_lower == "i" || tag_lower == "em" {
                italic_start = Some(plain_text.len());
            } else if tag_lower == "/i" || tag_lower == "/em" {
                if let Some(start) = italic_start.take() {
                    spans.push(ParsedSpan {
                        start,
                        end: plain_text.len(),
                        is_bold: false,
                        is_italic: true,
                        is_underline: false,
                        color: None,
                    });
                }
            } else if tag_lower == "u" {
                underline_start = Some(plain_text.len());
            } else if tag_lower == "/u" {
                if let Some(start) = underline_start.take() {
                    spans.push(ParsedSpan {
                        start,
                        end: plain_text.len(),
                        is_bold: false,
                        is_italic: false,
                        is_underline: true,
                        color: None,
                    });
                }
            } else if tag_lower == "br" || tag_lower == "br/" || tag_lower == "br /" {
                plain_text.push('\n');
            } else if tag_lower == "p" || tag_lower == "/p" {
                if !plain_text.is_empty() && !plain_text.ends_with('\n') {
                    plain_text.push('\n');
                }
            }
        } else if in_tag {
            current_tag.push(c);
        } else {
            // HTML Entity replacement (fast in-place)
            if c == '&' && i + 3 < chars.len() {
                let rest: String = chars[i..std::cmp::min(i + 8, chars.len())].iter().collect();
                if rest.starts_with("&quot;") {
                    plain_text.push('"');
                    i += 5;
                } else if rest.starts_with("&amp;") {
                    plain_text.push('&');
                    i += 4;
                } else if rest.starts_with("&lt;") {
                    plain_text.push('<');
                    i += 3;
                } else if rest.starts_with("&gt;") {
                    plain_text.push('>');
                    i += 3;
                } else if rest.starts_with("&nbsp;") {
                    plain_text.push(' ');
                    i += 5;
                } else {
                    plain_text.push(c);
                }
            } else {
                plain_text.push(c);
            }
        }
        i += 1;
    }

    FastParsedText {
        plain_text,
        image_urls,
        spans,
    }
}
