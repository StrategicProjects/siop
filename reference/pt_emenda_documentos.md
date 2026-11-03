# Documentos de despesa ligados a emendas

`GET /api-de-dados/emendas/documentos/{codigo}`: empenhos, liquidações e
pagamentos. Aceita um ou mais códigos e devolve um único tibble.

## Usage

``` r
pt_emenda_documentos(codigo_emenda, max_paginas = Inf, .progress = TRUE)
```

## Arguments

- codigo_emenda:

  Código(s) de emenda (coluna `codigo_emenda` de
  [`pt_emendas()`](https://strategicprojects.github.io/siop/reference/pt_emendas.md)).

- max_paginas:

  Limite de páginas (15 registros cada). Padrão: todas.

- .progress:

  Mostrar barra de progresso quando houver mais de um item.

## Value

Tibble com `codigo_emenda`, `id`, `data`, `fase`, `codigo_documento`,
`codigo_documento_resumido`, `especie_tipo`, `tipo_emenda`.
