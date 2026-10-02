use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct ParsedRemoteGame {
    pub id: i64,
    pub list_id: i32,
    pub author: String,
    pub ported_by: String,
    pub version: String,
    pub title: String,
    pub lang: String,
    pub player: String,
    pub icon: String,
    pub image: String,
    pub file_url: String,
    pub file_size: i64,
    pub file_ext: String,
    pub desc_url: String,
    pub pub_date: String,
    pub mod_date: String,
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct ParsedRemoteList {
    pub games: Vec<ParsedRemoteGame>,
}

pub fn parse_stock_xml_fast(xml_str: &str) -> Result<ParsedRemoteList, String> {
    use quick_xml::events::Event;
    use quick_xml::reader::Reader;

    let mut reader = Reader::from_str(xml_str);
    reader.config_mut().trim_text(true);

    let mut list = ParsedRemoteList::default();
    let mut current_game: Option<ParsedRemoteGame> = None;
    let mut current_tag = String::new();

    let mut buf = Vec::new();
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).to_string();
                if name.eq_ignore_ascii_case("game") {
                    current_game = Some(ParsedRemoteGame::default());
                }
                current_tag = name.to_ascii_lowercase();
            }
            Ok(Event::Text(ref e)) => {
                let text = match e.unescape() {
                    Ok(t) => t.into_owned(),
                    Err(_) => String::from_utf8_lossy(e.as_ref()).to_string(),
                };
                if let Some(ref mut game) = current_game {
                    match current_tag.as_str() {
                        "id" => game.id = text.parse::<i64>().unwrap_or(0),
                        "list_id" => game.list_id = text.parse::<i32>().unwrap_or(0),
                        "author" => game.author = text,
                        "ported_by" => game.ported_by = text,
                        "version" => game.version = text,
                        "title" => game.title = text,
                        "lang" => game.lang = text,
                        "player" => game.player = text,
                        "icon" => game.icon = text,
                        "image" => game.image = text,
                        "file_url" => game.file_url = text,
                        "file_size" => game.file_size = text.parse::<i64>().unwrap_or(0),
                        "file_ext" => game.file_ext = text,
                        "desc_url" => game.desc_url = text,
                        "pub_date" => game.pub_date = text,
                        "mod_date" => game.mod_date = text,
                        _ => {}
                    }
                }
            }
            Ok(Event::End(ref e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref());
                if name.eq_ignore_ascii_case("game") {
                    if let Some(game) = current_game.take() {
                        if !game.title.is_empty() {
                            list.games.push(game);
                        }
                    }
                }
                current_tag.clear();
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(format!("XML parse error: {}", e)),
            _ => {}
        }
        buf.clear();
    }

    Ok(list)
}
