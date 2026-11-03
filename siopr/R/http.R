#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang %||% .data
## usethis namespace: end
NULL

siopr_user_agent <- function() {
  paste0("siopr/", utils::packageVersion("siopr"), " (+https://github.com/StrategicProjects/siop)")
}

# Requisicao base com retries (429/5xx e falhas de transporte) e User-Agent.
siopr_request <- function(url, timeout = 300, max_tries = 4) {
  httr2::request(url) |>
    httr2::req_user_agent(siopr_user_agent()) |>
    httr2::req_timeout(timeout) |>
    httr2::req_retry(
      max_tries = max_tries,
      is_transient = function(resp) httr2::resp_status(resp) %in% c(429, 500, 502, 503, 504),
      backoff = function(i) min(60, 2^i + stats::runif(1, 0, 0.5))
    ) |>
    httr2::req_error(body = siopr_error_body)
}

siopr_error_body <- function(resp) {
  body <- tryCatch(httr2::resp_body_string(resp), error = function(e) "")
  c(paste0("URL: ", resp$url), substr(body, 1, 500))
}

# "1.234,56" -> 1234.56 ; "1234.5" -> 1234.5 ; "" -> NA
parse_brl <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  s <- trimws(as.character(x))
  s[s %in% c("", "-", "NA", "null")] <- NA_character_
  s <- gsub("R\\$|\\s", "", s)
  tem_virgula <- !is.na(s) & grepl(",", s, fixed = TRUE)
  s[tem_virgula] <- gsub(",", ".", gsub(".", "", s[tem_virgula], fixed = TRUE), fixed = TRUE)
  suppressWarnings(as.numeric(s))
}

brl_columns <- function(df, cols) {
  for (c in intersect(cols, names(df))) df[[c]] <- parse_brl(df[[c]])
  df
}

# bytes -> texto: UTF-8 (com/sem BOM) com fallback latin1 (os CSVs do SIOP variam)
decode_bytes <- function(raw) {
  txt <- rawToChar(raw)
  Encoding(txt) <- "UTF-8"
  if (!validUTF8(txt)) {
    txt <- rawToChar(raw)
    Encoding(txt) <- "latin1"
    txt <- enc2utf8(txt)
  }
  sub("^\ufeff", "", txt)
}

# CSV do SIOP: ';', tudo texto (codigos com zeros a esquerda)
read_siop_csv <- function(text) {
  readr::read_delim(
    I(text), delim = ";", col_types = readr::cols(.default = readr::col_character()),
    na = character(), trim_ws = FALSE, progress = FALSE, show_col_types = FALSE
  )
}
