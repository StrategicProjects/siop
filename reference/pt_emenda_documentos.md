# Documentos de despesa ligados a uma emenda

`GET /api-de-dados/emendas/documentos/{codigo}`: empenhos, liquidações e
pagamentos.

## Usage

``` r
pt_emenda_documentos(codigo_emenda, max_paginas = Inf)
```

## Arguments

- codigo_emenda:

  Código da emenda (coluna `codigo_emenda` de
  [`pt_emendas()`](https://strategicprojects.github.io/siop/reference/pt_emendas.md)).

- max_paginas:

  Limite de páginas (15 registros cada). Padrão: todas.

## Value

Tibble com `codigo_emenda`, `id`, `data`, `fase`, `codigo_documento`,
`codigo_documento_resumido`, `especie_tipo`, `tipo_emenda`.
