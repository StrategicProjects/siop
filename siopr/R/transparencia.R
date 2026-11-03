pt_base <- function() getOption("siopr.pt_base", "https://api.portaldatransparencia.gov.br")
pt_key_env <- "PORTAL_TRANSPARENCIA_API_KEY"
pt_header <- "chave-api-dados"

.pt_state <- new.env(parent = emptyenv())
.pt_state$key <- NULL
.pt_state$ts <- numeric()

#' Chave da API do Portal da Transparência
#'
#' A chave é gratuita: <https://portaldatransparencia.gov.br/api-de-dados/cadastrar-email>.
#' Informe-a na variável de ambiente `PORTAL_TRANSPARENCIA_API_KEY` (por exemplo no
#' `.Renviron`) ou, para a sessão, com `pt_set_key()`. O pacote nunca grava a chave em disco.
#'
#' @param key Texto da chave; `NULL` para voltar a usar a variável de ambiente.
#' @return `pt_set_key()` devolve `NULL` invisivelmente; `pt_has_key()` um lógico.
#' @export
pt_set_key <- function(key) {
  .pt_state$key <- key
  invisible(NULL)
}

#' @rdname pt_set_key
#' @export
pt_has_key <- function() {
  nzchar(.pt_state$key %||% Sys.getenv(pt_key_env, ""))
}

pt_get_key <- function() {
  key <- .pt_state$key %||% Sys.getenv(pt_key_env, "")
  if (!nzchar(key)) {
    cli::cli_abort(c(
      "Chave da API do Portal da Transpar\u00eancia ausente.",
      i = "Defina {.envvar {pt_key_env}} ou chame {.fn pt_set_key}.",
      i = "Cadastro: {.url https://portaldatransparencia.gov.br/api-de-dados/cadastrar-email}"
    ))
  }
  key
}

# janela deslizante: no maximo n requisicoes por `periodo` segundos (padrao 90/min)
pt_rate_limit <- function(n = getOption("siopr.pt_rate", 90), periodo = 60) {
  now <- as.numeric(Sys.time())
  .pt_state$ts <- .pt_state$ts[now - .pt_state$ts <= periodo]
  if (length(.pt_state$ts) >= n) Sys.sleep(periodo - (now - .pt_state$ts[[1]]) + 0.05)
  .pt_state$ts <- c(.pt_state$ts, as.numeric(Sys.time()))
}

pt_get <- function(path, ...) {
  params <- list(...)
  params <- params[!vapply(params, is.null, logical(1))]
  pt_rate_limit()
  req <- siopr_request(paste0(pt_base(), path), timeout = 60) |>
    httr2::req_headers(!!!stats::setNames(list(pt_get_key()), pt_header), Accept = "application/json")
  if (length(params)) req <- httr2::req_url_query(req, !!!params)
  httr2::resp_body_json(httr2::req_perform(req), simplifyVector = FALSE)
}

pt_get_paginado <- function(path, ..., max_paginas = Inf) {
  itens <- list()
  pagina <- 1L
  repeat {
    lote <- pt_get(path, pagina = pagina, ...)
    if (length(lote) == 0) break
    itens <- c(itens, lote)
    pagina <- pagina + 1L
    if (pagina > max_paginas) break
  }
  itens
}

pt_valor_cols <- c("valorEmpenhado", "valorLiquidado", "valorPago", "valorRestoInscrito",
                   "valorRestoCancelado", "valorRestoPago", "valor", "valorFinal")

# camelCase -> snake_case (conservando siglas usuais)
to_snake <- function(x) {
  x <- gsub("([a-z0-9])([A-Z])", "\\1_\\2", x)
  x <- gsub("([A-Z]+)([A-Z][a-z])", "\\1_\\2", x)
  tolower(x)
}

pt_to_tibble <- function(itens) {
  if (length(itens) == 0) return(tibble::tibble())
  if (!is.null(names(itens)) && !is.list(itens[[1]])) itens <- list(itens) # objeto \u00fanico
  campos <- unique(unlist(lapply(itens, names)))
  cols <- lapply(campos, function(f) {
    vals <- lapply(itens, function(it) it[[f]])
    if (all(vapply(vals, function(v) is.null(v) || length(v) <= 1, logical(1)))) {
      unlist(lapply(vals, function(v) if (is.null(v)) NA else v))
    } else {
      vals
    }
  })
  names(cols) <- campos
  df <- tibble::as_tibble(cols)
  df <- brl_columns(df, pt_valor_cols)
  names(df) <- to_snake(names(df))
  names(df)[names(df) == "localidade_do_gasto"] <- "localidade_gasto"
  df
}

#' Emendas parlamentares (Portal da Transparência)
#'
#' Consulta `GET /api-de-dados/emendas` percorrendo todas as páginas. Traz código,
#' ano, tipo, autor, número, localidade do gasto, função/subfunção e os valores
#' empenhado, liquidado, pago e de restos a pagar (inscrito, cancelado, pago).
#'
#' @param ano Ano da emenda.
#' @param autor Nome do parlamentar (busca textual da API). Acentos são
#'   removidos e o nome vai em maiúsculas automaticamente — a busca da API
#'   não encontra nomes acentuados ("Túlio Gadêlha" vira "TULIO GADELHA").
#' @param tipo Tipo de emenda, como na API (ex.: `"Emenda Individual - Transferências
#'   com Finalidade Definida"`).
#' @param codigo,numero,funcao,subfuncao Demais filtros da API (texto).
#' @param max_paginas Limite de páginas (15 registros cada). Padrão: todas.
#' @return Tibble; valores em R$ numéricos, nomes em `snake_case`.
#' @examples
#' \dontrun{
#' Sys.setenv(PORTAL_TRANSPARENCIA_API_KEY = "...")
#' pt_emendas(2025, autor = "NOME DO PARLAMENTAR")
#' }
#' @seealso [pt_emenda_documentos()], [emendas_execucao()]
#' @export
pt_emendas <- function(ano = NULL, autor = NULL, tipo = NULL, codigo = NULL, numero = NULL,
                       funcao = NULL, subfuncao = NULL, max_paginas = Inf) {
  if (!is.null(autor)) autor <- toupper(sem_acento(autor))
  itens <- pt_get_paginado("/api-de-dados/emendas", ano = ano, nomeAutor = autor, tipoEmenda = tipo,
                           codigoEmenda = codigo, numeroEmenda = numero, codigoFuncao = funcao,
                           codigoSubfuncao = subfuncao, max_paginas = max_paginas)
  df <- pt_to_tibble(itens)
  if ("ano" %in% names(df)) df$ano <- as.integer(df$ano)
  df
}

#' Documentos de despesa ligados a uma emenda
#'
#' `GET /api-de-dados/emendas/documentos/{codigo}`: empenhos, liquidações e pagamentos.
#' @param codigo_emenda Código da emenda (coluna `codigo_emenda` de [pt_emendas()]).
#' @inheritParams pt_emendas
#' @return Tibble com `codigo_emenda`, `id`, `data`, `fase`, `codigo_documento`,
#'   `codigo_documento_resumido`, `especie_tipo`, `tipo_emenda`.
#' @export
pt_emenda_documentos <- function(codigo_emenda, max_paginas = Inf) {
  df <- pt_to_tibble(pt_get_paginado(paste0("/api-de-dados/emendas/documentos/", codigo_emenda), max_paginas = max_paginas))
  if (nrow(df)) df <- tibble::add_column(df, codigo_emenda = as.character(codigo_emenda), .before = 1)
  df
}

#' Detalhe de um documento de despesa
#'
#' `GET /api-de-dados/despesas/documentos/{codigo}`: favorecido, UG, UO, órgão,
#' classificação funcional-programática, valor, autor da emenda.
#' @param codigo_documento Código completo (UG + gestão + número), como em
#'   `codigo_documento` de [pt_emenda_documentos()].
#' @return Tibble de uma linha.
#' @export
pt_despesa_documento <- function(codigo_documento) {
  pt_to_tibble(pt_get(paste0("/api-de-dados/despesas/documentos/", codigo_documento)))
}

#' Documentos relacionados a um documento de despesa
#' @inheritParams pt_despesa_documento
#' @param fase 1 = empenho, 2 = liquidação, 3 = pagamento.
#' @export
pt_documentos_relacionados <- function(codigo_documento, fase) {
  pt_to_tibble(pt_get("/api-de-dados/despesas/documentos-relacionados", codigoDocumento = codigo_documento, fase = fase))
}

#' Favorecidos finais de um documento de despesa
#' @inheritParams pt_despesa_documento
#' @inheritParams pt_emendas
#' @export
pt_favorecidos_finais <- function(codigo_documento, max_paginas = Inf) {
  pt_to_tibble(pt_get_paginado("/api-de-dados/despesas/favorecidos-finais-por-documento",
                               codigoDocumento = codigo_documento, max_paginas = max_paginas))
}

#' Emendas com seus documentos e favorecidos (uma linha por documento)
#'
#' Combina [pt_emendas()], [pt_emenda_documentos()] e, se `detalhar = TRUE`,
#' [pt_despesa_documento()]. Custo em requisições: 1 por página de emendas + 1 ou
#' mais por emenda (+ 1 por documento ao detalhar); o limite de 90 req/min é
#' respeitado automaticamente.
#'
#' @inheritParams pt_emendas
#' @param detalhar Buscar o detalhe (favorecido, UG, UO...) de cada documento.
#' @param max_emendas Limitar o número de emendas processadas (útil para explorar).
#' @param .progress Mostrar progresso.
#' @return Tibble.
#' @export
emendas_execucao <- function(ano, autor = NULL, tipo = NULL, detalhar = TRUE, max_emendas = Inf, .progress = TRUE) {
  emendas <- pt_emendas(ano, autor = autor, tipo = tipo)
  if (nrow(emendas) == 0) return(emendas)
  if (is.finite(max_emendas)) emendas <- utils::head(emendas, max_emendas)
  if (.progress) cli::cli_progress_bar("Documentos por emenda", total = nrow(emendas))
  docs <- lapply(emendas$codigo_emenda, function(cod) {
    if (.progress) cli::cli_progress_update(.envir = parent.frame(2))
    pt_emenda_documentos(cod)
  })
  docs <- docs[vapply(docs, nrow, integer(1)) > 0]
  docs_df <- if (length(docs)) do.call(rbind, docs) else tibble::tibble(codigo_emenda = character())
  out <- merge(emendas, docs_df, by = "codigo_emenda", all.x = TRUE, suffixes = c("", "_doc"), sort = FALSE)
  if (detalhar && "codigo_documento" %in% names(out)) {
    cods <- unique(stats::na.omit(out$codigo_documento))
    det <- lapply(cods, pt_despesa_documento)
    det <- det[vapply(det, nrow, integer(1)) > 0]
    if (length(det)) {
      det_df <- do.call(rbind, det)
      names(det_df)[names(det_df) == "documento"] <- "codigo_documento"
      det_df <- det_df[!duplicated(det_df$codigo_documento), ]
      out <- merge(out, det_df, by = "codigo_documento", all.x = TRUE, suffixes = c("", "_det"), sort = FALSE)
    }
  }
  out <- out[order(out$codigo_emenda), c("codigo_emenda", setdiff(names(out), "codigo_emenda"))]
  tibble::as_tibble(out)
}
