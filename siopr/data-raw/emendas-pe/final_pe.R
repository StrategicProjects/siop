# Consolidacao final: base + municipios via CNPJ -> agregados da vinheta
S <- "/private/tmp/claude-501/-Users-leite-Github-siop/4792f8dc-3fd8-4009-bfb1-90328a535cb9/scratchpad"
sem_acento <- function(x) {
  de <- c("á","à","â","ã","é","ê","í","ó","ô","õ","ú","ü","ç")
  pa <- c("a","a","a","a","e","e","i","o","o","o","u","u","c")
  x <- tolower(x)
  for (i in seq_along(de)) x <- gsub(de[[i]], pa[[i]], x, fixed = TRUE)
  toupper(x)
}
base <- readr::read_csv(file.path(S, "base_pe_2025.csv"), show_col_types = FALSE)
cnpj <- readr::read_csv(file.path(S, "cnpj_municipio.csv"), show_col_types = FALSE)

# municipio do CNPJ (MAIUSCULO sem acento) -> grafia IBGE
mun <- httr2::request("https://servicodados.ibge.gov.br/api/v1/localidades/estados/PE/municipios") |>
  httr2::req_perform() |> httr2::resp_body_json()
mun_pe <- vapply(mun, `[[`, "", "nome")
ibge <- stats::setNames(mun_pe, sem_acento(mun_pe))
cnpj$municipio_cnpj <- unname(ibge[sem_acento(cnpj$municipio_cnpj)])
cat("cnpjs sem grafia IBGE:", sum(is.na(cnpj$municipio_cnpj)), "\n")

base$cnpj <- sub(" - .*$", "", base$favorecido)
base <- merge(base, cnpj[, c("cnpj", "municipio_cnpj")], by = "cnpj", all.x = TRUE)
base$municipio <- ifelse(is.na(base$municipio), base$municipio_cnpj, base$municipio)
base <- tibble::as_tibble(base)

tipo <- dplyr::case_when(
  !is.na(base$municipio) ~ "municipal",
  grepl("CAIXA ECONOMICA", base$nome_favorecido) ~ "caixa",
  grepl("^ESTADO D|^FUNDO ESTADUAL", base$nome_favorecido) ~ "estadual",
  TRUE ~ "outros")
cat("cobertura por valor:\n"); print(round(100 * tapply(base$valor, tipo, sum) / sum(base$valor), 1))
readr::write_csv(base, file.path(S, "base_final_pe_2025.csv"))

ag_mun <- dplyr::summarise(base[!is.na(base$municipio), ], valor = sum(valor),
  n_deputados = dplyr::n_distinct(deputado), .by = municipio) |>
  dplyr::arrange(dplyr::desc(valor))
cat("\nmunicipios distintos:", nrow(ag_mun), "de 185 | valor municipal:",
    round(sum(ag_mun$valor)/1e6), "mi de", round(sum(base$valor)/1e6), "mi\n")
print(utils::head(ag_mun, 20), n = 20)
readr::write_csv(ag_mun, file.path(S, "ag_municipio.csv"))

ag_dep <- dplyr::summarise(base, valor = sum(valor),
  valor_municipal = sum(valor[!is.na(municipio)]),
  n_municipios = dplyr::n_distinct(municipio, na.rm = TRUE), .by = deputado) |>
  dplyr::arrange(dplyr::desc(n_municipios))
print(ag_dep, n = 30)
readr::write_csv(ag_dep, file.path(S, "ag_deputado.csv"))

# concentracao: quantos municipios para 50% do valor municipal
v <- cumsum(ag_mun$valor) / sum(ag_mun$valor)
cat("\nmunicipios para 50% do valor:", which(v >= .5)[1],
    "| top10 =", round(100 * v[10]), "%\n")
