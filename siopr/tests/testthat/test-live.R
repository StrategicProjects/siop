skip_if_not(identical(tolower(Sys.getenv("SIOPR_LIVE")), "true"), "SIOPR_LIVE != true")

test_that("ultima atualizacao (live)", {
  df <- siop_ultima_atualizacao()
  expect_true(2025L %in% df$exercicio)
})

test_that("emendas de bancada do MEC (live)", {
  df <- siop_emendas(2025, tipo = "bancada", orgao = "26000")
  expect_gt(nrow(df), 0)
  expect_true(all(df$cod_rp == "7"))
})

test_that("pt_emendas (live)", {
  skip_if_not(pt_has_key(), "sem PORTAL_TRANSPARENCIA_API_KEY")
  df <- pt_emendas(2025, max_paginas = 1)
  expect_gt(nrow(df), 0)
})
