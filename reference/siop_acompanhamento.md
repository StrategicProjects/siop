# Acompanhamento físico-financeiro das ações (CSV anual)

Acompanhamento físico-financeiro das ações (CSV anual)

## Usage

``` r
siop_acompanhamento(exercicio, refresh = FALSE)
```

## Arguments

- exercicio:

  Ano.

- refresh:

  Baixar novamente ignorando o cache.

## Value

Um tibble (`tbl_df`) com uma linha por registro do arquivo oficial de
acompanhamento físico-financeiro do exercício (metas físicas e valores
financeiros previstos e realizados por ação e localizador). Todas as
colunas são texto e mantêm os nomes originais do arquivo; o atributo
`"url"` guarda o endereço de onde o arquivo foi baixado.
