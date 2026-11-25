# Documentos relacionados a documentos de despesa

Documentos relacionados a documentos de despesa

## Usage

``` r
pt_documentos_relacionados(codigo_documento, fase, .progress = TRUE)
```

## Arguments

- codigo_documento:

  Código(s) completo(s) (UG + gestão + número), como em
  `codigo_documento` de
  [`pt_emenda_documentos()`](https://strategicprojects.github.io/siop/reference/pt_emenda_documentos.md).

- fase:

  1 = empenho, 2 = liquidação, 3 = pagamento.

- .progress:

  Mostrar barra de progresso quando houver mais de um item.

## Value

Um tibble (`tbl_df`) com uma linha por documento relacionado e as
colunas `codigo_documento` (o código consultado), `data`, `fase`,
`documento`, `documento_resumido`, `especie`, `orgao_superior`,
`orgao_vinculado`, `unidade_gestora`, `elemento_despesa` e `favorecido`
(texto) e `valor` (numérico, em reais). Tibble vazio (sem colunas)
quando não há documentos relacionados.
