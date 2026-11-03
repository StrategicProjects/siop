test_that("sem_acento", {
  expect_equal(sem_acento(c("Túlio Gadêlha", "São João", "MENDONÇA")),
               c("Tulio Gadelha", "Sao Joao", "MENDONCA"))
})

CAMARA_P1 <- '{"dados":[{"id":204454,"nome":"André Ferreira","siglaPartido":"PL","siglaUf":"PE","idLegislatura":57,"email":"dep@camara.leg.br"}],
"links":[{"rel":"self","href":"https://x/deputados?pagina=1"},{"rel":"next","href":"https://x/deputados?pagina=2"}]}'
CAMARA_P2 <- '{"dados":[{"id":74573,"nome":"Pedro Campos","siglaPartido":"PSB","siglaUf":"PE","idLegislatura":57,"email":null}],
"links":[{"rel":"self","href":"https://x/deputados?pagina=2"}]}'

test_that("camara_deputados filtra por UF e segue a paginacao", {
  reqs <- mock_queue(resp_json_text(CAMARA_P1), resp_json_text(CAMARA_P2))
  df <- camara_deputados(uf = "PE", legislatura = 57)
  expect_length(reqs(), 2L)
  expect_match(reqs()[[1]]$url, "siglaUf=PE")
  expect_match(reqs()[[1]]$url, "idLegislatura=57")
  expect_match(reqs()[[2]]$url, "pagina=2")
  expect_equal(df$nome, c("André Ferreira", "Pedro Campos"))
  expect_equal(df$sigla_partido, c("PL", "PSB"))
  expect_true(is.na(df$email[[2]]))
})

IBGE_PE <- '[{"id":2611606,"nome":"Recife","microrregiao":{"mesorregiao":{"UF":{"sigla":"PE"}}}},
{"id":2613909,"nome":"Surubim","microrregiao":null,"regiao-imediata":{"regiao-intermediaria":{"UF":{"sigla":"PE"}}}}]'

test_that("ibge_municipios devolve codigo texto, nome e uf", {
  reqs <- mock_queue(resp_json_text(IBGE_PE))
  df <- ibge_municipios("PE")
  expect_match(reqs()[[1]]$url, "estados/PE/municipios")
  expect_equal(df$codigo, c("2611606", "2613909"))
  expect_equal(df$nome, c("Recife", "Surubim"))
  expect_equal(df$uf, c("PE", "PE"))
})

test_that("cnpj_municipio limpa a pontuacao e devolve NA em 404", {
  nao_achou <- function(req) httr2::response(404, body = charToRaw("{}"))
  reqs <- mock_queue(
    resp_json_text('{"cnpj":"10298546000124","municipio":"SURUBIM","uf":"PE"}'),
    nao_achou
  )
  df <- cnpj_municipio(c("10.298.546/0001-24", "00.000.000/0000-00"))
  expect_match(reqs()[[1]]$url, "/10298546000124$")
  expect_equal(df$municipio, c("SURUBIM", NA))
  expect_equal(df$uf, c("PE", NA))
  expect_equal(df$cnpj[[1]], "10.298.546/0001-24")
})
