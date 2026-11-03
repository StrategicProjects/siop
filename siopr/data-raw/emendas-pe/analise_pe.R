# Analise: municipio de destino dos empenhos (casamento com lista IBGE)
S <- "/private/tmp/claude-501/-Users-leite-Github-siop/4792f8dc-3fd8-4009-bfb1-90328a535cb9/scratchpad"

sem_acento <- function(x) {
  de <- c("á","à","â","ã","é","ê","í","ó","ô","õ","ú","ü","ç")
  pa <- c("a","a","a","a","e","e","i","o","o","o","u","u","c")
  x <- tolower(x)
  for (i in seq_along(de)) x <- gsub(de[[i]], pa[[i]], x, fixed = TRUE)
  toupper(x)
}

ler <- function(nome) {
  arqs <- file.path(S, c(nome, sub("\\.csv$", "_fix.csv", nome)))
  do.call(rbind, lapply(arqs[file.exists(arqs)], readr::read_csv, show_col_types = FALSE))
}
emendas <- ler("emendas_pe_2025.csv")
docs    <- ler("docs_pe_2025.csv")
det     <- ler("empenhos_pe_2025.csv")
cat("emendas:", nrow(emendas), "| docs:", nrow(docs), "| empenhos:", nrow(det), "\n")

# municipios de PE (IBGE)
mun <- httr2::request("https://servicodados.ibge.gov.br/api/v1/localidades/estados/PE/municipios") |>
  httr2::req_perform() |> httr2::resp_body_json()
mun_pe <- vapply(mun, `[[`, "", "nome")
cat("municipios PE (IBGE):", length(mun_pe), "\n")
mun_norm <- sem_acento(mun_pe)

# casar: favorecido municipal -> municipio (nome IBGE mais longo contido na string)
fav <- unique(det$nome_favorecido)
fav_norm <- sem_acento(fav)
ord <- order(nchar(mun_norm), decreasing = TRUE)  # "SAO JOSE DO EGITO" antes de "EGITO"
casa <- function(s) {
  for (i in ord) if (grepl(paste0("\\b", mun_norm[[i]], "\\b"), s)) return(mun_pe[[i]])
  NA_character_
}
municipal <- grepl("^MUNICIPIO|^PREFEITURA|FUNDO MUNICIPAL|CAMARA MUNICIPAL", fav_norm)
# truncamentos e grafias do SIAFI que a lista do IBGE nao cobre
fav_norm <- sub("CABO DE SANTO$", "CABO DE SANTO AGOSTINHO", fav_norm)
fav_norm <- sub("STA\\. CRUZ DO CAPIBARIBE", "SANTA CRUZ DO CAPIBARIBE", fav_norm)
fav_norm <- sub("\\bIGUARACI\\b", "IGUARACY", fav_norm)
mapa <- tibble::tibble(nome_favorecido = fav,
                       municipio = ifelse(municipal, vapply(fav_norm, casa, ""), NA))
nao_casou <- mapa$nome_favorecido[municipal & is.na(mapa$municipio)]
cat("favorecidos municipais sem municipio no nome:", length(nao_casou), "\n")
print(utils::head(nao_casou, 15))

# juntar: emenda (deputado) -> documentos de empenho -> detalhe -> municipio
emp <- docs[docs$fase == "Empenho", c("codigo_emenda", "codigo_documento")]
emp <- unique(merge(emp, emendas[, c("codigo_emenda", "deputado")], by = "codigo_emenda"))
det2 <- merge(det, mapa, by = "nome_favorecido")
base <- tibble::as_tibble(merge(emp, det2, by.x = "codigo_documento", by.y = "documento"))
cat("linhas base:", nrow(base), "| valor:", round(sum(base$valor)/1e6), "mi\n")
readr::write_csv(base, file.path(S, "base_pe_2025.csv"))

# agregados
ag_mun <- dplyr::summarise(base[!is.na(base$municipio), ],
  valor = sum(valor), n_deputados = dplyr::n_distinct(deputado),
  .by = municipio) |> dplyr::arrange(dplyr::desc(valor))
cat("\nmunicipios distintos:", nrow(ag_mun), "de", length(mun_pe), "\n")
print(utils::head(ag_mun, 15), n = 15)
pct <- sum(ag_mun$valor) / sum(base$valor)
cat(sprintf("\nvalor com municipio identificado: %.0f%%\n", 100 * pct))
readr::write_csv(ag_mun, file.path(S, "ag_municipio.csv"))
ag_dep <- dplyr::summarise(base, valor = sum(valor),
  n_municipios = dplyr::n_distinct(municipio, na.rm = TRUE), .by = deputado) |>
  dplyr::arrange(dplyr::desc(valor))
print(ag_dep, n = 30)
readr::write_csv(ag_dep, file.path(S, "ag_deputado.csv"))
