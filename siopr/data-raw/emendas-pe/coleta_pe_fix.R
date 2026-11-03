# Passe de correcao: deputados cujo nome com acento falhou no TRANSLIT do macOS
pkgload::load_all("/Users/leite/Github/siop/siopr", quiet = TRUE)
out_dir <- dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)))

sem_acento <- function(x) {
  chartr("áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ",
         "aaaaeeioooucAAAEEIOOOUC", x) |> toupper()
}
# chartr acima exige mesmo comprimento; fazer manualmente:
sem_acento <- function(x) {
  de  <- c("á","à","â","ã","é","ê","í","ó","ô","õ","ú","ç")
  para <- c("a","a","a","a","e","e","i","o","o","o","u","c")
  x <- tolower(x)
  for (i in seq_along(de)) x <- gsub(de[[i]], para[[i]], x, fixed = TRUE)
  toupper(x)
}

alvos <- c("André Ferreira", "Clarissa Tércio", "Clodoaldo Magalhães",
           "Túlio Gadêlha", "Silvio Costa Filho")
buscas <- list(sem_acento(alvos[[1]]), sem_acento(alvos[[2]]), sem_acento(alvos[[3]]),
               sem_acento(alvos[[4]]), c("SILVIO COSTA FILHO", "SILVIO COSTA"))

emendas <- list()
for (i in seq_along(alvos)) {
  achou <- tibble::tibble()
  for (b in buscas[[i]]) {
    em <- tryCatch(pt_emendas(2025, autor = b), error = function(e) tibble::tibble())
    if (nrow(em)) { achou <- em; busca_ok <- b; break }
  }
  if (nrow(achou)) {
    achou <- achou[achou$autor == busca_ok, ]
    achou$deputado <- alvos[[i]]
    emendas[[alvos[[i]]]] <- achou
  }
  cat(sprintf("%-28s %3d emendas\n", alvos[[i]], nrow(achou)))
}
if (!length(emendas)) { cat("nada novo\n"); quit(save = "no") }
emendas <- do.call(rbind, emendas)
readr::write_csv(emendas, file.path(out_dir, "emendas_pe_2025_fix.csv"))

docs <- lapply(emendas$codigo_emenda, function(cod)
  tryCatch(pt_emenda_documentos(cod), error = function(e) tibble::tibble()))
docs <- do.call(rbind, docs[vapply(docs, nrow, 1L) > 0])
readr::write_csv(docs, file.path(out_dir, "docs_pe_2025_fix.csv"))
emp <- unique(docs$codigo_documento[docs$fase == "Empenho"])
cat("documentos:", nrow(docs), "| empenhos unicos:", length(emp), "\n")

det <- lapply(emp, function(cd) {
  d <- tryCatch(pt_despesa_documento(cd), error = function(e) tibble::tibble())
  d[, intersect(c("documento", "favorecido", "nome_favorecido", "uf_favorecido",
                  "valor", "funcao", "acao", "localizador_gasto", "modalidade",
                  "autor", "orgao_superior"), names(d))]
})
det <- do.call(rbind, det[vapply(det, nrow, 1L) > 0])
readr::write_csv(det, file.path(out_dir, "empenhos_pe_2025_fix.csv"))
cat("detalhes:", nrow(det), "\nOK\n")
