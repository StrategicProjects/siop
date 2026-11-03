# Detalhe de documentos de despesa

`GET /api-de-dados/despesas/documentos/{codigo}`: favorecido, UG, UO,
órgão, classificação funcional-programática, valor, autor da emenda.
Aceita um ou mais códigos e devolve um único tibble (uma linha por
documento).

## Usage

``` r
pt_despesa_documento(codigo_documento, .progress = TRUE)
```

## Arguments

- codigo_documento:

  Código(s) completo(s) (UG + gestão + número), como em
  `codigo_documento` de
  [`pt_emenda_documentos()`](https://strategicprojects.github.io/siop/reference/pt_emenda_documentos.md).

- .progress:

  Mostrar barra de progresso quando houver mais de um item.

## Value

Tibble com uma linha por documento.
