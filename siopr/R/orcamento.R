#' Tipos de emenda e seus códigos de Resultado Primário (RP)
#'
#' No orçamento federal as emendas parlamentares são identificadas pelo classificador
#' Resultado Primário: 6 = individuais (desde 2014), 7 = bancada (desde 2017),
#' 8 = comissão e 9 = relator (observados a partir de 2020).
#' @format Vetor nomeado de texto.
#' @export
tipo_emenda_rp <- c(individual = "6", bancada = "7", comissao = "8", relator = "9")

# filtro -> variavel ?cod_* do template orcamento.rq
filtros_sparql <- c(
  esfera = "cod_esfera", orgao = "cod_orgao", uo = "cod_uo", funcao = "cod_funcao",
  subfuncao = "cod_subfuncao", programa = "cod_programa", acao = "cod_acao",
  localizador = "cod_localizador", po = "cod_po", fonte = "cod_fonte",
  categoria = "cod_categoria", gnd = "cod_gnd", modalidade = "cod_modalidade",
  elemento = "cod_elemento", iduso = "cod_iduso", rp = "cod_rp"
)

valor_cols <- c("ploa", "autografo", "loa", "lei_mais_credito", "empenhado", "liquidado", "pago")

montar_filtros <- function(filtros) {
  filtros <- filtros[!vapply(filtros, function(v) is.null(v) || length(v) == 0, logical(1))]
  if (length(filtros) == 0) return("")
  desconhecidos <- setdiff(names(filtros), names(filtros_sparql))
  if (length(desconhecidos)) {
    cli::cli_abort(c("Filtro desconhecido: {.val {desconhecidos}}.", i = "Filtros aceitos: {.val {names(filtros_sparql)}}."))
  }
  linhas <- vapply(names(filtros), function(nome) {
    vals <- gsub('"', '\\\\"', as.character(filtros[[nome]]))
    sprintf('    FILTER(?%s IN (%s))', filtros_sparql[[nome]], paste0('"', vals, '"', collapse = ", "))
  }, character(1))
  paste(linhas, collapse = "\n")
}

#' Montar a consulta SPARQL do orçamento
#'
#' Preenche o template `inst/sparql/orcamento.rq` com o exercício e os filtros.
#' Útil para inspecionar ou adaptar a consulta antes de executá-la com [siop_sparql()].
#'
#' @param exercicio Ano da LOA (grafo `http://orcamento.dados.gov.br/<ano>/`).
#' @param ... Filtros por código (texto, vetorizável): `esfera, orgao, uo, funcao,
#'   subfuncao, programa, acao, localizador, po, fonte, categoria, gnd, modalidade,
#'   elemento, iduso, rp`.
#' @return Texto da consulta.
#' @export
siop_montar_query <- function(exercicio, ...) {
  tpl <- sparql_template("orcamento")
  tpl <- sub("{{exercicio}}", as.character(as.integer(exercicio)), tpl, fixed = TRUE)
  sub("{{filtros}}", montar_filtros(list(...)), tpl, fixed = TRUE)
}

tidy_orcamento <- function(df) {
  if (nrow(df) == 0) return(df)
  df$exercicio <- as.integer(df$exercicio)
  for (c in intersect(valor_cols, names(df))) df[[c]] <- as.numeric(df[[c]])
  if ("data_atualizacao" %in% names(df)) {
    df$data_atualizacao <- as.POSIXct(sub("(\\.\\d+)?([+-]\\d{2}):(\\d{2})$", "\\2\\3", df$data_atualizacao),
                                      format = "%Y-%m-%dT%H:%M:%S%z", tz = "UTC")
  }
  df
}

#' Linhas de despesa do Orçamento Federal (RDF do SIOP)
#'
#' Devolve as linhas `loa:ItemDespesa` de um exercício com a classificação completa
#' (esfera, órgão, UO, função, subfunção, programa, ação, localizador, PO, fonte,
#' categoria, GND, modalidade, elemento, IdUso, RP) e os valores: `ploa`, `autografo`,
#' `loa` (dotação inicial), `lei_mais_credito`, `empenhado`, `liquidado`, `pago`.
#'
#' @inheritParams siop_montar_query
#' @param particionar Consultar órgão a órgão? Padrão: `TRUE` quando nenhum filtro é
#'   informado (o orçamento inteiro tem ~390 mil linhas/ano), `FALSE` caso contrário.
#' @param .progress Mostrar barra de progresso ao particionar.
#' @return Tibble; códigos como texto, valores numéricos (R$).
#' @examples
#' \dontrun{
#' siop_orcamento(2025, orgao = "26000")
#' siop_orcamento(2025, funcao = "10", rp = c("6", "7"))
#' }
#' @seealso [siop_emendas()], [siop_sparql()]
#' @export
siop_orcamento <- function(exercicio, ..., particionar = NULL, .progress = TRUE) {
  filtros <- list(...)
  tem_filtro <- any(vapply(filtros, function(v) length(v) > 0, logical(1)))
  particionar <- particionar %||% !tem_filtro
  if (!particionar) {
    return(tidy_orcamento(siop_sparql(siop_montar_query(exercicio, ...))))
  }
  orgaos <- siop_orgaos(exercicio)
  partes <- vector("list", nrow(orgaos))
  if (.progress) cli::cli_progress_bar("Consultando \u00f3rg\u00e3os", total = nrow(orgaos))
  for (i in seq_len(nrow(orgaos))) {
    args <- c(list(exercicio), filtros, list(orgao = orgaos$cod_orgao[[i]]))
    partes[[i]] <- siop_sparql(do.call(siop_montar_query, args))
    if (.progress) cli::cli_progress_update()
  }
  tidy_orcamento(tibble::as_tibble(do.call(rbind, partes)))
}

#' Dotações de emendas parlamentares na LOA (RP 6/7/8/9)
#'
#' Atalho de [siop_orcamento()] filtrando o Resultado Primário das emendas e
#' acrescentando a coluna `tipo_emenda`.
#'
#' O RDF do SIOP **não** traz autor nem número da emenda; para isso use
#' [pt_emendas()] (Portal da Transparência).
#'
#' @inheritParams siop_montar_query
#' @param tipo Um ou mais de `"individual"`, `"bancada"`, `"comissao"`, `"relator"`.
#' @return Tibble como em [siop_orcamento()], com `tipo_emenda`.
#' @examples
#' \dontrun{
#' em <- siop_emendas(2025, tipo = c("individual", "bancada"))
#' dplyr::count(em, tipo_emenda, wt = loa)
#' }
#' @export
siop_emendas <- function(exercicio, tipo = names(tipo_emenda_rp), ...) {
  tipo <- rlang::arg_match(tipo, names(tipo_emenda_rp), multiple = TRUE)
  df <- siop_orcamento(exercicio, ..., rp = unname(tipo_emenda_rp[tipo]), particionar = FALSE)
  if (nrow(df) == 0) return(df)
  inv <- stats::setNames(names(tipo_emenda_rp), tipo_emenda_rp)
  pos <- match("cod_rp", names(df))
  tibble::add_column(df, tipo_emenda = unname(inv[df$cod_rp]), .before = pos)
}

#' Órgãos orçamentários presentes no grafo de um exercício
#' @inheritParams siop_montar_query
#' @return Tibble com `cod_orgao`, `desc_orgao`.
#' @export
siop_orgaos <- function(exercicio) {
  q <- sprintf(
    "SELECT DISTINCT ?cod_orgao ?desc_orgao WHERE { GRAPH <%s%d/> { ?i a loa:ItemDespesa ; loa:temUnidadeOrcamentaria ?uo . ?uo loa:temOrgao ?org . ?org loa:codigo ?cod_orgao ; rdfs:label ?desc_orgao } }",
    siop_graph_base, as.integer(exercicio)
  )
  df <- siop_sparql(q)
  df[order(df$cod_orgao), ]
}

#' Exercícios disponíveis e data da última carga do RDF
#'
#' @return Tibble com `exercicio` (inteiro) e `data_atualizacao` (POSIXct, UTC),
#'   do mais recente para o mais antigo.
#' @export
siop_exercicios <- function() {
  q <- "SELECT ?exercicio ?data_atualizacao WHERE { GRAPH ?g { ?e a loa:Exercicio ; loa:identificador ?exercicio ; loa:dataUltimaAtualizacao ?data_atualizacao } }"
  df <- tidy_orcamento(siop_sparql(q))
  df[order(-df$exercicio), ]
}

#' @rdname siop_exercicios
#' @param exercicio Opcional: restringir a um ano.
#' @export
siop_ultima_atualizacao <- function(exercicio = NULL) {
  df <- siop_exercicios()
  if (!is.null(exercicio)) df <- df[df$exercicio == as.integer(exercicio), ]
  df
}
