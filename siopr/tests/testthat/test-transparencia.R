local_pt_key <- function(env = parent.frame()) {
  withr::local_envvar(PORTAL_TRANSPARENCIA_API_KEY = "chave-teste", .local_envir = env)
  pt_set_key(NULL)
  .pt_state$ts <- numeric()
}

test_that("parse_brl", {
  expect_equal(parse_brl(c("1.500.000,00", "750.000,50", "1234.5", "")), c(1500000, 750000.5, 1234.5, NA))
})

test_that("chave ausente gera erro claro", {
  withr::local_envvar(PORTAL_TRANSPARENCIA_API_KEY = "")
  pt_set_key(NULL)
  expect_false(pt_has_key())
  expect_error(pt_emendas(2025), "PORTAL_TRANSPARENCIA_API_KEY")
})

test_that("pt_emendas pagina, envia cabeçalho e converte valores", {
  local_pt_key()
  reqs <- mock_queue(resp_json("pt_emendas_p1.json"), resp_json("pt_vazio.json"))
  df <- pt_emendas(2025, autor = "PARLAMENTAR EXEMPLO")
  expect_length(reqs(), 2L)
  r1 <- reqs()[[1]]
  expect_equal(r1$headers[["chave-api-dados"]], "chave-teste")
  expect_match(r1$url, "pagina=1")
  expect_match(r1$url, "ano=2025")
  expect_match(r1$url, "nomeAutor=PARLAMENTAR%20EXEMPLO")
  expect_false(grepl("tipoEmenda", r1$url))
  expect_match(reqs()[[2]]$url, "pagina=2")
  expect_equal(names(df)[1:3], c("codigo_emenda", "ano", "tipo_emenda"))
  expect_equal(df$valor_empenhado, c(1500000, 300000))
  expect_equal(df$valor_liquidado[[1]], 750000.5)
  expect_type(df$ano, "integer")
})

test_that("max_paginas limita", {
  local_pt_key()
  reqs <- mock_queue(resp_json("pt_emendas_p1.json"))
  df <- pt_emendas(2025, max_paginas = 2)
  expect_length(reqs(), 2L)
  expect_equal(nrow(df), 4L)
})

test_that("pt_emenda_documentos e pt_despesa_documento", {
  local_pt_key()
  mock_queue(resp_json("pt_emenda_documentos.json"), resp_json("pt_vazio.json"), resp_json("pt_despesa_documento.json"))
  docs <- pt_emenda_documentos("202512340001")
  expect_equal(unique(docs$codigo_emenda), "202512340001")
  expect_equal(docs$codigo_documento[[1]], "257001257012025NE000123")
  det <- pt_despesa_documento("257001257012025NE000123")
  expect_equal(nrow(det), 1L)
  expect_equal(det$valor, 1500000)
  expect_equal(det$uf_favorecido, "PE")
  expect_false(det$favorecido_intermediario)
})

test_that("emendas_execucao une emendas, documentos e detalhe", {
  local_pt_key()
  mock_queue(function(req) {
    u <- req$url
    if (grepl("/emendas/documentos/202512340001", u) && grepl("pagina=1", u)) return(resp_json("pt_emenda_documentos.json"))
    if (grepl("/emendas/documentos/", u)) return(resp_json("pt_vazio.json"))
    if (grepl("/despesas/documentos/", u)) return(resp_json("pt_despesa_documento.json"))
    if (grepl("/api-de-dados/emendas", u) && grepl("pagina=1", u)) return(resp_json("pt_emendas_p1.json"))
    resp_json("pt_vazio.json")
  })
  df <- emendas_execucao(2025, autor = "PARLAMENTAR EXEMPLO", .progress = FALSE)
  expect_equal(nrow(df), 3L)
  expect_equal(df$codigo_emenda, c("202512340001", "202512340001", "202512340002"))
  expect_true("nome_favorecido" %in% names(df))
  expect_equal(df$nome_favorecido[[1]], "MUNICIPIO EXEMPLO")
  expect_true(is.na(df$codigo_documento[[3]]))
})

test_that("401 vira erro httr2", {
  local_pt_key()
  mock_queue(httr2::response(401, body = charToRaw("{}")))
  expect_error(pt_emendas(2025), "401")
})
