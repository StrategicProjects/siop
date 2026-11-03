# Coleta: emendas 2025 dos deputados federais de PE, documento a documento
pkgload::load_all("/Users/leite/Github/siop/siopr", quiet = TRUE)
out_dir <- dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)))

# 1. Deputados de PE (API da Camara)
dep <- httr2::request("https://dadosabertos.camara.leg.br/api/v2/deputados") |>
  httr2::req_url_query(siglaUf = "PE", ordem = "ASC", ordenarPor = "nome") |>
  httr2::req_headers(Accept = "application/json") |>
  httr2::req_perform() |> httr2::resp_body_json()
nomes <- vapply(dep$dados, `[[`, "", "nome")
busca <- toupper(iconv(nomes, to = "ASCII//TRANSLIT"))
cat("deputados:", length(nomes), "\n")

# 2. Emendas por autor
emendas <- list()
for (i in seq_along(busca)) {
  em <- tryCatch(pt_emendas(2025, autor = busca[[i]]), error = function(e) {
    message(busca[[i]], ": ", conditionMessage(e)); tibble::tibble()
  })
  if (nrow(em)) {
    em <- em[em$autor == busca[[i]], ]  # busca textual: exige igualdade exata
    if (nrow(em)) { em$deputado <- nomes[[i]]; emendas[[busca[[i]]]] <- em }
  }
  cat(sprintf("%-28s %3d emendas\n", busca[[i]], nrow(em)))
}
emendas <- do.call(rbind, emendas)
readr::write_csv(emendas, file.path(out_dir, "emendas_pe_2025.csv"))
cat("total emendas:", nrow(emendas), "\n")

# 3. Documentos de cada emenda; detalhe dos empenhos
docs <- lapply(emendas$codigo_emenda, function(cod)
  tryCatch(pt_emenda_documentos(cod), error = function(e) tibble::tibble()))
docs <- do.call(rbind, docs[vapply(docs, nrow, 1L) > 0])
readr::write_csv(docs, file.path(out_dir, "docs_pe_2025.csv"))
emp <- unique(docs$codigo_documento[docs$fase == "Empenho"])
cat("documentos:", nrow(docs), "| empenhos unicos:", length(emp), "\n")

det <- lapply(emp, function(cd) {
  d <- tryCatch(pt_despesa_documento(cd), error = function(e) tibble::tibble())
  d[, intersect(c("documento", "favorecido", "nome_favorecido", "uf_favorecido",
                  "valor", "funcao", "acao", "localizador_gasto", "modalidade",
                  "autor", "orgao_superior"), names(d))]
})
det <- do.call(rbind, det[vapply(det, nrow, 1L) > 0])
readr::write_csv(det, file.path(out_dir, "empenhos_pe_2025.csv"))
cat("detalhes:", nrow(det), "\nOK\n")
