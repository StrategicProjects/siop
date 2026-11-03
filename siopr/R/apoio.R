# Fontes publicas de apoio ao estudo de emendas: Camara dos Deputados, IBGE e
# Minha Receita. Nenhuma exige chave.

camara_base <- function() getOption("siopr.camara_base", "https://dadosabertos.camara.leg.br/api/v2")
ibge_base <- function() getOption("siopr.ibge_base", "https://servicodados.ibge.gov.br/api/v1")
cnpj_base <- function() getOption("siopr.cnpj_base", "https://minhareceita.org")

#' Remover acentos
#'
#' Troca caracteres acentuados do português pelos equivalentes ASCII, sem
#' depender do `iconv()` da plataforma (o `//TRANSLIT` do macOS gera marcas
#' como `"ANDR'E"`). Útil para casar nomes entre fontes — a busca textual do
#' Portal da Transparência, por exemplo, não encontra nomes acentuados.
#'
#' @param x Vetor de texto.
#' @return Vetor de texto sem acentos, preservando maiúsculas/minúsculas.
#' @examples
#' sem_acento(c("Túlio Gadêlha", "São João"))
#' @export
sem_acento <- function(x) {
  chartr(
    paste0(
      "\u00e1\u00e0\u00e2\u00e3\u00e4\u00e9\u00e8\u00ea\u00eb",
      "\u00ed\u00ec\u00ee\u00ef\u00f3\u00f2\u00f4\u00f5\u00f6",
      "\u00fa\u00f9\u00fb\u00fc\u00e7",
      "\u00c1\u00c0\u00c2\u00c3\u00c4\u00c9\u00c8\u00ca\u00cb",
      "\u00cd\u00cc\u00ce\u00cf\u00d3\u00d2\u00d4\u00d5\u00d6",
      "\u00da\u00d9\u00db\u00dc\u00c7"
    ),
    "aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC",
    x
  )
}

#' Deputados federais (Dados Abertos da Câmara)
#'
#' Consulta `GET /deputados` da API de Dados Abertos da Câmara dos Deputados,
#' seguindo a paginação. Sem filtros, devolve os deputados em exercício.
#'
#' @param uf Sigla(s) de UF (ex.: `"PE"`).
#' @param legislatura Número(s) de legislatura (ex.: `57`).
#' @return Tibble com `id`, `nome`, `sigla_partido`, `sigla_uf`,
#'   `id_legislatura` e `email`.
#' @examplesIf interactive()
#' camara_deputados(uf = "PE")
#' @seealso [pt_emendas()] para as emendas de cada autor.
#' @export
camara_deputados <- function(uf = NULL, legislatura = NULL) {
  url <- paste0(camara_base(), "/deputados")
  itens <- list()
  repeat {
    req <- siopr_request(url) |>
      httr2::req_headers(Accept = "application/json")
    if (!grepl("?", url, fixed = TRUE)) {
      req <- httr2::req_url_query(
        req,
        siglaUf = paste(uf, collapse = ","),
        idLegislatura = paste(legislatura, collapse = ","),
        ordem = "ASC", ordenarPor = "nome"
      )
    }
    corpo <- httr2::resp_body_json(httr2::req_perform(req))
    itens <- c(itens, corpo$dados)
    links <- vapply(corpo$links, `[[`, "", "href")
    names(links) <- vapply(corpo$links, `[[`, "", "rel")
    if (is.na(links["next"]) || identical(links[["next"]], url)) break
    url <- links[["next"]]
  }
  col <- function(campo) vapply(itens, function(it) {
    v <- it[[campo]]
    if (is.null(v)) NA_character_ else as.character(v)
  }, "")
  tibble::tibble(
    id = col("id"),
    nome = col("nome"),
    sigla_partido = col("siglaPartido"),
    sigla_uf = col("siglaUf"),
    id_legislatura = col("idLegislatura"),
    email = col("email")
  )
}

#' Municípios (IBGE)
#'
#' Consulta a API de localidades do IBGE: os municípios de uma ou mais UFs
#' (ou todos, se `uf = NULL`), com a grafia oficial dos nomes.
#'
#' @param uf Sigla(s) de UF (ex.: `"PE"`); `NULL` para o Brasil inteiro.
#' @return Tibble com `codigo` (7 dígitos, texto), `nome` e `uf`.
#' @examplesIf interactive()
#' ibge_municipios("PE")
#' @export
ibge_municipios <- function(uf = NULL) {
  caminho <- if (is.null(uf)) {
    "/localidades/municipios"
  } else {
    paste0("/localidades/estados/", paste(uf, collapse = "|"), "/municipios")
  }
  itens <- siopr_request(paste0(ibge_base(), caminho)) |>
    httr2::req_headers(Accept = "application/json") |>
    httr2::req_perform() |>
    httr2::resp_body_json()
  sigla_uf <- vapply(itens, function(it) {
    s <- it$microrregiao$mesorregiao$UF$sigla %||%
      it$`regiao-imediata`$`regiao-intermediaria`$UF$sigla
    s %||% NA_character_
  }, "")
  tibble::tibble(
    codigo = vapply(itens, function(it) as.character(it$id), ""),
    nome = vapply(itens, `[[`, "", "nome"),
    uf = sigla_uf
  )
}

#' Município da sede de um CNPJ (Minha Receita)
#'
#' Consulta <https://minhareceita.org> (espelho aberto do cadastro CNPJ da
#' Receita Federal) e devolve o município e a UF da sede de cada CNPJ.
#' Resolve favorecidos de nome genérico ("FUNDO MUNICIPAL DE SAUDE") nos
#' documentos de despesa.
#'
#' @param cnpj Vetor de CNPJs, com ou sem pontuação.
#' @return Tibble com `cnpj` (como informado), `municipio` e `uf`; linhas
#'   não encontradas vêm com `NA`.
#' @examplesIf interactive()
#' cnpj_municipio("00.394.460/0058-87")
#' @seealso [pt_despesa_documento()], que traz o CNPJ do favorecido.
#' @export
cnpj_municipio <- function(cnpj) {
  linhas <- lapply(unique(cnpj), function(c) {
    corpo <- tryCatch(
      siopr_request(paste0(cnpj_base(), "/", gsub("\\D", "", c))) |>
        httr2::req_headers(Accept = "application/json") |>
        httr2::req_perform() |>
        httr2::resp_body_json(),
      httr2_http_404 = function(e) NULL
    )
    tibble::tibble(
      cnpj = c,
      municipio = as.character(corpo$municipio %||% NA),
      uf = as.character(corpo$uf %||% NA)
    )
  })
  do.call(rbind, linhas)
}
