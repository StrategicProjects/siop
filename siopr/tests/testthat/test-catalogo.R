test_that("siop_parse_catalogo", {
  df <- siop_parse_catalogo(HTML_CAT)
  expect_setequal(unique(df$categoria), c("rdf", "cadastro_acoes", "creditos", "regionalizacao"))
  ca <- df[df$categoria == "cadastro_acoes", ]
  expect_equal(ca$subtipo, c("acoes", "localizadores", "planos_orcamentarios"))
  expect_true(all(df$exercicio[df$tipo == "dados"] == 2025L))
  expect_true(is.na(df$exercicio[df$tipo == "dicionario"]))
  expect_equal(df$formato[df$tipo == "dicionario"], "pdf")
  expect_true(all(startsWith(df$url, "https://www1.siop.planejamento.gov.br")))
})

test_that("decode_bytes: latin1 e UTF-8 com BOM", {
  lat <- iconv("Exercício;Ação\n2025;x\n", to = "latin1", toRaw = TRUE)[[1]]
  expect_match(decode_bytes(lat), "Ação")
  bom <- c(as.raw(c(0xef, 0xbb, 0xbf)), charToRaw("ano;val\n2025;1,5\n"))
  df <- read_siop_csv(decode_bytes(bom))
  expect_equal(names(df)[1], "ano")
  expect_equal(df$val, "1,5")
})

test_that("siop_cadastro_acoes baixa, lê latin1 e usa cache", {
  withr::local_options(siopr.cache_dir = withr::local_tempdir())
  lat <- iconv("Exercício;Esfera;UO;Ação;Título\r\n2025;10;01101;4061;Processo Legislativo\r\n", to = "latin1", toRaw = TRUE)[[1]]
  n_csv <- 0
  mock_queue(function(req) {
    if (grepl("dados_acao2025", req$url)) { n_csv <<- n_csv + 1; return(httr2::response(200, body = lat)) }
    resp_html(HTML_CAT)
  })
  df <- siop_cadastro_acoes(2025)
  expect_equal(df$`Título`, "Processo Legislativo")
  expect_equal(df$UO, "01101")
  siop_cadastro_acoes(2025)
  expect_equal(n_csv, 1)
  siop_cadastro_acoes(2025, refresh = TRUE)
  expect_equal(n_csv, 2)
})

test_that("siop_creditos lê zip e converte valores", {
  withr::local_options(siopr.cache_dir = withr::local_tempdir())
  tmp <- withr::local_tempdir()
  csv <- file.path(tmp, "creditos.csv")
  writeBin(c(as.raw(c(0xef, 0xbb, 0xbf)), charToRaw("ano;acao;val_acrescimo;val_reducao\r\n2025;20GP;0,00;1630282,00\r\n")), csv)
  zipf <- file.path(tmp, "c.zip")
  withr::with_dir(tmp, utils::zip(zipf, "creditos.csv", flags = "-q"))
  zraw <- readBin(zipf, "raw", file.info(zipf)$size)
  mock_queue(function(req) if (grepl("alteracoesorcamentarias_2025", req$url)) httr2::response(200, body = zraw) else resp_html(HTML_CAT))
  df <- siop_creditos(2025)
  expect_equal(df$val_reducao, 1630282)
})

test_that("exercício inexistente lista os disponíveis", {
  withr::local_options(siopr.cache_dir = withr::local_tempdir())
  mock_queue(resp_html(HTML_CAT))
  expect_error(siop_creditos(2019), "2025")
  expect_equal(nrow(siop_catalogo()), 7L)
})
