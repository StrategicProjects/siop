siop_doc_base <- "https://www1.siop.planejamento.gov.br"

#' URL da página de Dados Abertos do SIOP
#' @keywords internal
siop_catalogo_url <- function() {
  getOption("siopr.catalogo_url", paste0(siop_doc_base, "/siopdoc/doku.php/acesso_publico:dados_abertos"))
}

categorias_catalogo <- c(
  rdf = "RDF da Execu", acompanhamento = "Acompanhamento F", cadastro_acoes = "Cadastro de A",
  creditos = "Cr[\u00e9e]ditos", regionalizacao = "Regionaliza"
)

#' Interpretar o HTML da página de Dados Abertos
#' @param html Texto HTML.
#' @return Tibble como em [siop_catalogo()].
#' @keywords internal
#' @export
siop_parse_catalogo <- function(html) {
  # tokens: cabecalhos h1-h3 e ancoras, na ordem do documento
  rx <- "<h[123][^>]*>(.*?)</h[123]>|<a\\s[^>]*href=\"([^\"]+)\"[^>]*>(.*?)</a>"
  m <- regmatches(html, gregexpr(rx, html, perl = TRUE))[[1]]
  secao <- ""
  rows <- list()
  limpar <- function(x) trimws(gsub("<[^>]+>", "", x))
  for (tok in m) {
    if (grepl("^<h[123]", tok)) {
      secao <- limpar(sub("^<h[123][^>]*>(.*)</h[123]>$", "\\1", tok, perl = TRUE))
      next
    }
    href <- sub("^<a\\s[^>]*href=\"([^\"]+)\".*$", "\\1", tok, perl = TRUE)
    titulo <- limpar(sub("^<a[^>]*>(.*)</a>$", "\\1", tok, perl = TRUE))
    if (!grepl("fetch\\.php|/downloads/rdf/", href)) next
    cat_idx <- which(vapply(categorias_catalogo, function(p) grepl(p, secao), logical(1)))
    if (length(cat_idx) == 0) next
    categoria <- names(categorias_catalogo)[cat_idx[1]]
    url <- if (grepl("^http", href)) href else paste0(siop_doc_base, href)
    ano <- regmatches(titulo, regexpr("20[0-9]{2}", titulo))
    if (length(ano) == 0) ano <- regmatches(url, regexpr("20[0-9]{2}", url))
    ext <- tolower(sub(".*\\.", "", url))
    tipo <- if (ext == "pdf") "dicionario" else "dados"
    subtipo <- NA_character_
    if (categoria == "cadastro_acoes" && tipo == "dados") {
      nome <- tolower(sub(".*:", "", url))
      subtipo <- if (grepl("localizador", nome)) "localizadores" else if (grepl("plano", nome)) "planos_orcamentarios" else "acoes"
    }
    rows[[length(rows) + 1]] <- tibble::tibble(
      categoria = categoria, subtipo = subtipo, tipo = tipo,
      exercicio = if (length(ano)) as.integer(ano) else NA_integer_,
      titulo = titulo, formato = ext, url = url
    )
  }
  if (length(rows) == 0) {
    return(tibble::tibble(categoria = character(), subtipo = character(), tipo = character(),
                          exercicio = integer(), titulo = character(), formato = character(), url = character()))
  }
  do.call(rbind, rows)
}

#' Catálogo dos arquivos publicados nos Dados Abertos do SIOP
#'
#' Raspa a página oficial (os nomes de arquivo são irregulares e mudam a cada
#' publicação) e devolve um tibble com `categoria` (`rdf`, `acompanhamento`,
#' `cadastro_acoes`, `creditos`, `regionalizacao`), `subtipo` (`acoes`,
#' `localizadores`, `planos_orcamentarios`), `tipo` (`dados`/`dicionario`),
#' `exercicio`, `titulo`, `formato` e `url`.
#' @return Tibble.
#' @export
siop_catalogo <- function() {
  resp <- siopr_request(siop_catalogo_url(), timeout = 60) |> httr2::req_perform()
  siop_parse_catalogo(httr2::resp_body_string(resp))
}

#' Diretório de cache dos downloads
#' @return Caminho (criado se necessário). Pode ser alterado com
#'   `options(siopr.cache_dir = ...)`.
#' @export
siop_cache_dir <- function() {
  d <- getOption("siopr.cache_dir", tools::R_user_dir("siopr", "cache"))
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

cache_path <- function(url) {
  nome <- sub(".*:", "", basename(url))
  h <- substr(rlang::hash(url), 1, 8)
  file.path(siop_cache_dir(), paste0(h, "_", nome))
}

#' Baixar um arquivo dos Dados Abertos (com cache em disco)
#' @param url URL (ver [siop_catalogo()]).
#' @param refresh Baixar novamente mesmo se já estiver no cache.
#' @return Caminho local do arquivo.
#' @export
siop_download <- function(url, refresh = FALSE) {
  dest <- cache_path(url)
  if (file.exists(dest) && !refresh) return(dest)
  resp <- siopr_request(url, timeout = 600) |> httr2::req_perform()
  writeBin(httr2::resp_body_raw(resp), dest)
  dest
}

ler_arquivo <- function(path) {
  raw <- readBin(path, "raw", file.info(path)$size)
  if (length(raw) >= 4 && identical(raw[1:2], as.raw(c(0x50, 0x4b)))) { # zip
    tmp <- tempfile("siopr_zip_")
    dir.create(tmp)
    arqs <- utils::unzip(path, exdir = tmp)
    arqs <- arqs[grepl("\\.(csv|txt)$", arqs, ignore.case = TRUE)]
    if (length(arqs) == 0) cli::cli_abort("Nenhum CSV dentro de {.file {basename(path)}}.")
    partes <- lapply(arqs, function(f) read_siop_csv(decode_bytes(readBin(f, "raw", file.info(f)$size))))
    return(do.call(rbind, partes))
  }
  if (grepl("\\.rar$", path, ignore.case = TRUE)) {
    cli::cli_abort("{.file {basename(path)}} \u00e9 .rar; extraia manualmente e leia com {.fn read_siop_csv}.")
  }
  read_siop_csv(decode_bytes(raw))
}

buscar_url <- function(cat, categoria, exercicio, subtipo = NULL) {
  sel <- cat[cat$categoria == categoria & cat$tipo == "dados" & !is.na(cat$exercicio) & cat$exercicio == exercicio, ]
  if (!is.null(subtipo)) sel <- sel[!is.na(sel$subtipo) & sel$subtipo == subtipo, ]
  if (nrow(sel) == 0) {
    disp <- sort(unique(stats::na.omit(cat$exercicio[cat$categoria == categoria & cat$tipo == "dados"])))
    cli::cli_abort("{categoria}{if (!is.null(subtipo)) paste0('/', subtipo)} {exercicio}: n\u00e3o publicado. Dispon\u00edveis: {.val {disp}}.")
  }
  sel$url[[1]]
}

dataset <- function(categoria, exercicio, subtipo = NULL, refresh = FALSE) {
  url <- buscar_url(siop_catalogo(), categoria, exercicio, subtipo)
  df <- ler_arquivo(siop_download(url, refresh = refresh))
  attr(df, "url") <- url
  df
}

#' Cadastro de ações, localizadores e planos orçamentários (CSV oficial)
#' @param exercicio Ano.
#' @param tipo `"acoes"`, `"localizadores"` ou `"planos_orcamentarios"`.
#' @param refresh Baixar novamente ignorando o cache.
#' @return Tibble com todas as colunas como texto (nomes originais do arquivo).
#' @export
siop_cadastro_acoes <- function(exercicio, tipo = c("acoes", "localizadores", "planos_orcamentarios"), refresh = FALSE) {
  tipo <- match.arg(tipo)
  dataset("cadastro_acoes", exercicio, tipo, refresh)
}

#' Alterações orçamentárias (créditos) de um exercício
#' @inheritParams siop_cadastro_acoes
#' @return Tibble; `val_acrescimo` e `val_reducao` numéricos.
#' @export
siop_creditos <- function(exercicio, refresh = FALSE) {
  brl_columns(dataset("creditos", exercicio, NULL, refresh), c("val_acrescimo", "val_reducao"))
}

#' Acompanhamento físico-financeiro das ações (CSV anual)
#' @inheritParams siop_cadastro_acoes
#' @export
siop_acompanhamento <- function(exercicio, refresh = FALSE) {
  dataset("acompanhamento", exercicio, NULL, refresh)
}

#' Regionalização das ações do Orçamento Federal
#' @inheritParams siop_cadastro_acoes
#' @return Tibble; colunas `Liquidado*`/`Realizado*` numéricas.
#' @export
siop_regionalizacao <- function(exercicio, refresh = FALSE) {
  df <- dataset("regionalizacao", exercicio, NULL, refresh)
  brl_columns(df, grep("^(Liquidado|Realizado)", names(df), value = TRUE))
}
