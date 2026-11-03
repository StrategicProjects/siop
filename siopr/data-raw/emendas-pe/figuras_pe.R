# Figuras da vinheta emendas-pe (pre-computadas; a vinheta nao roda isto no CRAN)
S <- "/private/tmp/claude-501/-Users-leite-Github-siop/4792f8dc-3fd8-4009-bfb1-90328a535cb9/scratchpad"
FIG <- "/Users/leite/Github/siop/siopr/vignettes/figures"
dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
library(ggplot2)

ink   <- "#1f2937"; ink2 <- "#6b7280"
pet_d <- "#0e3a53"; pet_m <- "#2c7da0"; pet_l <- "#e3eef5"

ag  <- readr::read_csv(file.path(S, "ag_municipio.csv"), show_col_types = FALSE)
tema <- theme_minimal(base_size = 12) + theme(
  text = element_text(color = ink),
  plot.title = element_text(face = "bold", size = 13, color = ink),
  plot.subtitle = element_text(color = ink2, size = 10),
  plot.caption = element_text(color = ink2, size = 8, hjust = 0),
  panel.grid.minor = element_blank(),
  plot.background = element_rect(fill = "white", color = NA))

# ---- mapa coropletico ----
pe <- geobr::read_municipality(code_muni = "PE", year = 2024, showProgress = FALSE)
pe <- pe[!grepl("Noronha", pe$name_muni), ]  # sem emendas em 2025; distorce o enquadramento
pe$name_muni_norm <- tolower(iconv(pe$name_muni, to = "ASCII//TRANSLIT"))
ag$mun_norm <- tolower(iconv(ag$municipio, to = "ASCII//TRANSLIT"))
m <- merge(pe, ag, by.x = "name_muni_norm", by.y = "mun_norm", all.x = TRUE)
cat("sem casar no shape:", sum(!ag$mun_norm %in% pe$name_muni_norm), "\n")
print(setdiff(ag$mun_norm, pe$name_muni_norm))

p1 <- ggplot(m) +
  geom_sf(aes(fill = valor / 1e6), color = "white", linewidth = 0.1) +
  scale_fill_gradient(low = pet_l, high = pet_d, na.value = "grey92",
                      name = "Empenhado\n(R$ milhões)",
                      labels = scales::label_number(decimal.mark = ",")) +
  labs(title = "Emendas individuais dos deputados federais de Pernambuco, 2025",
       subtitle = "Valor empenhado por município do favorecido — 180 dos 185 municípios receberam (cinza: sem registro)",
       caption = "Fontes: Portal da Transparência (CGU), Câmara dos Deputados e IBGE. Favorecidos municipais (86% do valor empenhado).\nFernando de Noronha, sem registro, foi omitido do mapa.") +
  tema + theme(axis.text = element_blank(), panel.grid = element_blank())
ggsave(file.path(FIG, "emendas-pe-mapa.png"), p1, width = 8.5, height = 4.3, dpi = 150)

# ---- barras: 15 maiores ----
top <- utils::head(ag, 15)
top$municipio <- factor(top$municipio, levels = rev(top$municipio))
p2 <- ggplot(top, aes(x = valor / 1e6, y = municipio)) +
  geom_col(fill = pet_m, width = 0.72) +
  geom_text(aes(label = paste0(format(round(valor / 1e6, 1), decimal.mark = ","),
                               "  (", n_deputados, " dep.)")),
            hjust = -0.06, size = 3.1, color = ink) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.22))) +
  labs(title = "Os 15 municípios que mais receberam emendas, 2025",
       subtitle = "Valor empenhado em R$ milhões; entre parênteses, quantos deputados destinaram recursos",
       x = NULL, y = NULL,
       caption = "Fonte: Portal da Transparência (CGU). Empenhos de emendas individuais de deputados federais de PE.") +
  tema + theme(panel.grid.major.y = element_blank(),
               axis.text.x = element_blank(), panel.grid.major.x = element_blank())
ggsave(file.path(FIG, "emendas-pe-top15.png"), p2, width = 8, height = 5.2, dpi = 150)
cat("figuras salvas em", FIG, "\n")
