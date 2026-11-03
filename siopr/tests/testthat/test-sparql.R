test_that("siop_montar_query injeta grafo e filtros sem ORDER BY", {
  q <- siop_montar_query(2025, orgao = c("26000", "22000"), rp = "6")
  expect_match(q, "GRAPH <http://orcamento.dados.gov.br/2025/>", fixed = TRUE)
  expect_match(q, 'FILTER(?cod_orgao IN ("26000", "22000"))', fixed = TRUE)
  expect_match(q, 'FILTER(?cod_rp IN ("6"))', fixed = TRUE)
  expect_false(grepl("ORDER BY", q))
  expect_error(siop_montar_query(2025, orgaoX = "1"), "desconhecido")
})

test_that("siop_sparql (csv) preserva códigos como texto", {
  reqs <- mock_queue(resp_csv("sparql_orgaos.csv"))
  df <- siop_sparql("SELECT ?cod_orgao ?desc_orgao WHERE {}")
  expect_s3_class(df, "tbl_df")
  expect_equal(df$cod_orgao, c("26000", "22000"))
  url <- reqs()[[1]]$url
  expect_match(url, "format=text%2Fcsv")
  expect_match(url, "PREFIX%20loa")
})

test_that("siop_sparql (json) converte bindings", {
  js <- '{"head":{"vars":["a","b"]},"results":{"bindings":[{"a":{"type":"literal","value":"1"}}]}}'
  mock_queue(resp_json_text(js))
  df <- siop_sparql("SELECT ...", format = "json")
  expect_equal(dim(df), c(1L, 2L))
  expect_true(is.na(df$b))
})

test_that("siop_emendas filtra RP, tipa colunas e adiciona tipo_emenda", {
  reqs <- mock_queue(resp_csv("sparql_emendas_2025.csv"))
  df <- siop_emendas(2025, tipo = c("individual", "bancada"))
  expect_match(utils::URLdecode(reqs()[[1]]$url), 'FILTER(?cod_rp IN ("6", "7"))', fixed = TRUE)
  expect_equal(nrow(df), 4L)
  expect_equal(df$tipo_emenda, c("individual", "individual", "individual", "bancada"))
  expect_type(df$loa, "double")
  expect_equal(df$loa[[3]], 6000001)
  expect_type(df$exercicio, "integer")
  expect_s3_class(df$data_atualizacao, "POSIXct")
  expect_equal(format(df$data_atualizacao[[1]], "%Y-%m-%d %H:%M", tz = "UTC"), "2026-10-28 04:34")
  expect_error(siop_emendas(2025, tipo = "xyz"))
})

test_that("siop_orcamento particiona por órgão quando sem filtro", {
  reqs <- mock_queue(resp_csv("sparql_orgaos.csv"), resp_csv("sparql_emendas_2025.csv"), resp_csv("sparql_emendas_2025.csv"))
  df <- siop_orcamento(2025, .progress = FALSE)
  expect_length(reqs(), 3L)
  expect_equal(nrow(df), 8L)
  expect_match(utils::URLdecode(reqs()[[2]]$url), 'IN ("22000")', fixed = TRUE)
})

test_that("siop_orcamento não particiona com filtro", {
  reqs <- mock_queue(resp_csv("sparql_emendas_2025.csv"))
  siop_orcamento(2025, orgao = "26000")
  expect_length(reqs(), 1L)
})

test_that("siop_ultima_atualizacao", {
  mock_queue(resp_csv("sparql_exercicios.csv"))
  df <- siop_ultima_atualizacao(2025)
  expect_equal(nrow(df), 1L)
  expect_equal(df$exercicio, 2025L)
})

test_that("requisições têm política de retry para 429/5xx", {
  req <- siopr_request("https://example.org")
  expect_equal(req$policies$retry_max_tries, 4)
  expect_true(req$policies$retry_is_transient(httr2::response(503)))
  expect_true(req$policies$retry_is_transient(httr2::response(429)))
  expect_false(req$policies$retry_is_transient(httr2::response(404)))
})
