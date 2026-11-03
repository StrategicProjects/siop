# Detalhe de um documento de despesa

`GET /api-de-dados/despesas/documentos/{codigo}`: favorecido, UG, UO,
órgão, classificação funcional-programática, valor, autor da emenda.

## Usage

``` r
pt_despesa_documento(codigo_documento)
```

## Arguments

- codigo_documento:

  Código completo (UG + gestão + número), como em `codigo_documento` de
  [`pt_emenda_documentos()`](https://strategicprojects.github.io/siop/reference/pt_emenda_documentos.md).

## Value

Tibble de uma linha.
