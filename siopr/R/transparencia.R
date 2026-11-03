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

# rbind tolerante a colunas diferentes entre lotes (a API omite campos vazios)
rbind_fill <- function(dfs) {
  dfs <- dfs[vapply(dfs, nrow, integer(1)) > 0]
  if (!length(dfs)) return(tibble::tibble())
  cols <- unique(unlist(lapply(dfs, names)))
  dfs <- lapply(dfs, function(d) { d[setdiff(cols, names(d))] <- NA; d[cols] })
  do.call(rbind, dfs)
}

# aplica `um()` a cada elemento e empilha, com barra de progresso nos loops longos
pt_varios <- function(x, um, .progress, rotulo) {
  if (length(x) == 0) return(tibble::tibble())
  if (length(x) == 1) return(um(x))
  if (.progress) cli::cli_progress_bar(rotulo, total = length(x))
  out <- lapply(x, function(xi) {
    if (.progress) cli::cli_progress_update(.envir = parent.frame(2))
    um(xi)
  })
  if (.progress) cli::cli_progress_done()
  rbind_fill(out)
}

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
#' @param autor Nome(s) de parlamentar (busca textual da API; um ou mais).
#'   Acentos são removidos e o nome vai em maiúsculas automaticamente — a
#'   busca da API não encontra nomes acentuados ("Túlio Gadêlha" vira
#'   "TULIO GADELHA"). Com vários autores, as buscas são feitas uma a uma e
#'   emendas repetidas (a busca é parcial) são deduplicadas pelo código.
#' @param tipo Tipo de emenda, como na API (ex.: `"Emenda Individual - Transferências
#'   com Finalidade Definida"`).
#' @param codigo,numero,funcao,subfuncao Demais filtros da API (texto).
#' @param max_paginas Limite de páginas (15 registros cada). Padrão: todas.
#' @param .progress Mostrar barra de progresso quando houver mais de um item.
#' @return Tibble; valores em R$ numéricos, nomes em `snake_case`.
#' @examples
#' \dontrun{
#' Sys.setenv(PORTAL_TRANSPARENCIA_API_KEY = "...")
#' pt_emendas(2025, autor = "NOME DO PARLAMENTAR")
#' }
#' @seealso [pt_emenda_documentos()], [emendas_execucao()]
#' @export
pt_emendas <- function(ano = NULL, autor = NULL, tipo = NULL, codigo = NULL, numero = NULL,
                       funcao = NULL, subfuncao = NULL, max_paginas = Inf, .progress = TRUE) {
  if (!is.null(autor)) autor <- toupper(sem_acento(autor))
  um <- function(a) {
    itens <- pt_get_paginado("/api-de-dados/emendas", ano = ano, nomeAutor = a, tipoEmenda = tipo,
                             codigoEmenda = codigo, numeroEmenda = numero, codigoFuncao = funcao,
                             codigoSubfuncao = subfuncao, max_paginas = max_paginas)
    pt_to_tibble(itens)
  }
  if (is.null(autor) || length(autor) == 1) {
    df <- um(if (is.null(autor)) NULL else autor)
  } else {
    df <- pt_varios(autor, um, .progress, "Emendas por autor")
    # a busca da API é parcial: "LULA DA FONTE" também responde a "DA FONTE"
    if ("codigo_emenda" %in% names(df)) df <- df[!duplicated(df$codigo_emenda), ]
  }
  if ("ano" %in% names(df)) df$ano <- as.integer(df$ano)
  df
}

#' Documentos de despesa ligados a emendas
#'
#' `GET /api-de-dados/emendas/documentos/{codigo}`: empenhos, liquidações e
#' pagamentos. Aceita um ou mais códigos e devolve um único tibble.
#' @param codigo_emenda Código(s) de emenda (coluna `codigo_emenda` de [pt_emendas()]).
#' @inheritParams pt_emendas
#' @return Tibble com `codigo_emenda`, `id`, `data`, `fase`, `codigo_documento`,
#'   `codigo_documento_resumido`, `especie_tipo`, `tipo_emenda`.
#' @export
pt_emenda_documentos <- function(codigo_emenda, max_paginas = Inf, .progress = TRUE) {
  um <- function(cod) {
    df <- pt_to_tibble(pt_get_paginado(paste0("/api-de-dados/emendas/documentos/", cod), max_paginas = max_paginas))
    if (nrow(df)) df <- tibble::add_column(df, codigo_emenda = as.character(cod), .before = 1)
    df
  }
  pt_varios(codigo_emenda, um, .progress, "Documentos por emenda")
}

#' Detalhe de documentos de despesa
#'
#' `GET /api-de-dados/despesas/documentos/{codigo}`: favorecido, UG, UO, órgão,
#' classificação funcional-programática, valor, autor da emenda. Aceita um ou
#' mais códigos e devolve um único tibble (uma linha por documento).
#' @param codigo_documento Código(s) completo(s) (UG + gestão + número), como em
#'   `codigo_documento` de [pt_emenda_documentos()].
#' @inheritParams pt_emendas
#' @return Tibble com uma linha por documento.
#' @export
pt_despesa_documento <- function(codigo_documento, .progress = TRUE) {
  um <- function(cod) pt_to_tibble(pt_get(paste0("/api-de-dados/despesas/documentos/", cod)))
  pt_varios(codigo_documento, um, .progress, "Detalhe dos documentos")
}

#' Documentos relacionados a documentos de despesa
#' @inheritParams pt_despesa_documento
#' @param fase 1 = empenho, 2 = liquidação, 3 = pagamento.
#' @export
pt_documentos_relacionados <- function(codigo_documento, fase, .progress = TRUE) {
  um <- function(cod) {
    df <- pt_to_tibble(pt_get("/api-de-dados/despesas/documentos-relacionados", codigoDocumento = cod, fase = fase))
    if (nrow(df)) df <- tibble::add_column(df, codigo_documento = as.character(cod), .before = 1)
    df
  }
  pt_varios(codigo_documento, um, .progress, "Documentos relacionados")
}

#' Favorecidos finais de documentos de despesa
#' @inheritParams pt_despesa_documento
#' @inheritParams pt_emendas
#' @export
pt_favorecidos_finais <- function(codigo_documento, max_paginas = Inf, .progress = TRUE) {
  um <- function(cod) {
    df <- pt_to_tibble(pt_get_paginado("/api-de-dados/despesas/favorecidos-finais-por-documento",
                                       codigoDocumento = cod, max_paginas = max_paginas))
    if (nrow(df)) df <- tibble::add_column(df, codigo_documento = as.character(cod), .before = 1)
    df
  }
  pt_varios(codigo_documento, um, .progress, "Favorecidos finais")
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
  emendas <- pt_emendas(ano, autor = autor, tipo = tipo, .progress = .progress)
  if (nrow(emendas) == 0) return(emendas)
  if (is.finite(max_emendas)) emendas <- utils::head(emendas, max_emendas)
  docs_df <- pt_emenda_documentos(emendas$codigo_emenda, .progress = .progress)
  if (nrow(docs_df) == 0) docs_df <- tibble::tibble(codigo_emenda = character())
  out <- merge(emendas, docs_df, by = "codigo_emenda", all.x = TRUE, suffixes = c("", "_doc"), sort = FALSE)
  if (detalhar && "codigo_documento" %in% names(out)) {
    cods <- unique(stats::na.omit(out$codigo_documento))
    det_df <- pt_despesa_documento(cods, .progress = .progress)
    if (nrow(det_df)) {
      names(det_df)[names(det_df) == "documento"] <- "codigo_documento"
      det_df <- det_df[!duplicated(det_df$codigo_documento), ]
      out <- merge(out, det_df, by = "codigo_documento", all.x = TRUE, suffixes = c("", "_det"), sort = FALSE)
    }
  }
  out <- out[order(out$codigo_emenda), c("codigo_emenda", setdiff(names(out), "codigo_emenda"))]
  tibble::as_tibble(out)
}
