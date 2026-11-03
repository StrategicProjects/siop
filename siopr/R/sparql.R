#' Endpoint SPARQL dos Dados Abertos do Orçamento Federal
#' @keywords internal
siop_sparql_endpoint <- function() {
  getOption("siopr.sparql_endpoint", "https://www1.siop.planejamento.gov.br/sparql/")
}

siop_graph_base <- "http://orcamento.dados.gov.br/"

siop_prefixes <- paste(
  "PREFIX loa: <http://vocab.e.gov.br/2013/09/loa#>",
  "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>",
  "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>",
  sep = "\n"
)

#' Executar uma consulta SPARQL no endpoint do SIOP
#'
#' Consulta o endpoint Virtuoso dos Dados Abertos do Orçamento Federal
#' (`https://www1.siop.planejamento.gov.br/sparql/`) e devolve um tibble.
#'
#' @details
#' Por padrão o resultado é pedido em `text/csv`, bem mais leve que JSON. Com
#' `format = "json"` usa-se `application/sparql-results+json`.
#'
#' O Virtuoso limita `ORDER BY` + `LIMIT/OFFSET` a 10 000 linhas ordenadas (erro
#' SR353). Evite `ORDER BY` em consultas grandes e particione por órgão/UO em vez de
#' paginar por `OFFSET` — é o que [siop_orcamento()] faz.
#'
#' @param query Texto da consulta SPARQL. Os prefixos `loa:`, `rdfs:` e `rdf:` são
#'   adicionados automaticamente se ausentes.
#' @param format `"csv"` (padrão) ou `"json"`.
#' @param timeout Segundos.
#' @return Um tibble com uma coluna por variável da consulta, todas como texto.
#' @examples
#' \dontrun{
#' siop_sparql("SELECT ?exercicio ?data WHERE { GRAPH ?g {
#'   ?e a loa:Exercicio ; loa:identificador ?exercicio ; loa:dataUltimaAtualizacao ?data } }")
#' }
#' @export
siop_sparql <- function(query, format = c("csv", "json"), timeout = 300) {
  format <- match.arg(format)
  if (!grepl("PREFIX\\s+loa:", query)) query <- paste(siop_prefixes, query, sep = "\n")
  req <- siopr_request(siop_sparql_endpoint(), timeout = timeout)
  if (format == "csv") {
    resp <- req |>
      httr2::req_url_query(query = query, format = "text/csv") |>
      httr2::req_perform()
    txt <- httr2::resp_body_string(resp)
    out <- readr::read_csv(
      I(txt), col_types = readr::cols(.default = readr::col_character()),
      na = character(), progress = FALSE, show_col_types = FALSE
    )
    return(tibble::as_tibble(out))
  }
  resp <- req |>
    httr2::req_url_query(query = query, format = "application/sparql-results+json") |>
    httr2::req_headers(Accept = "application/sparql-results+json") |>
    httr2::req_perform()
  bindings_to_tibble(httr2::resp_body_json(resp))
}

bindings_to_tibble <- function(payload) {
  vars <- unlist(payload$head$vars)
  rows <- payload$results$bindings
  cols <- lapply(vars, function(v) {
    vapply(rows, function(b) if (is.null(b[[v]])) NA_character_ else as.character(b[[v]]$value), character(1))
  })
  names(cols) <- vars
  tibble::as_tibble(cols)
}

#' Ler o template SPARQL do pacote
#' @keywords internal
sparql_template <- function(name = "orcamento") {
  path <- system.file("sparql", paste0(name, ".rq"), package = "siopr", mustWork = TRUE)
  paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}
