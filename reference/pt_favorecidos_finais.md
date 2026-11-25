# Favorecidos finais de documentos de despesa

Favorecidos finais de documentos de despesa

## Usage

``` r
pt_favorecidos_finais(codigo_documento, max_paginas = Inf, .progress = TRUE)
```

## Arguments

- codigo_documento:

  Código(s) completo(s) (UG + gestão + número), como em
  `codigo_documento` de
  [`pt_emenda_documentos()`](https://strategicprojects.github.io/siop/reference/pt_emenda_documentos.md).

- max_paginas:

  Limite de páginas (15 registros cada). Padrão: todas.

- .progress:

  Mostrar barra de progresso quando houver mais de um item.

## Value

Um tibble (`tbl_df`) com uma linha por favorecido final: a coluna
`codigo_documento` (o código consultado, texto) na frente, seguida dos
campos devolvidos pela API, com nomes em `snake_case` (identificação do
favorecido final e valor recebido). Tibble vazio (sem colunas) quando o
documento não tem favorecidos finais registrados.
