# Emendas parlamentares (Portal da Transparência)

Consulta `GET /api-de-dados/emendas` percorrendo todas as páginas. Traz
código, ano, tipo, autor, número, localidade do gasto, função/subfunção
e os valores empenhado, liquidado, pago e de restos a pagar (inscrito,
cancelado, pago).

## Usage

``` r
pt_emendas(
  ano = NULL,
  autor = NULL,
  tipo = NULL,
  codigo = NULL,
  numero = NULL,
  funcao = NULL,
  subfuncao = NULL,
  max_paginas = Inf,
  .progress = TRUE
)
```

## Arguments

- ano:

  Ano da emenda.

- autor:

  Nome(s) de parlamentar (busca textual da API; um ou mais). Acentos são
  removidos e o nome vai em maiúsculas automaticamente — a busca da API
  não encontra nomes acentuados ("Túlio Gadêlha" vira "TULIO GADELHA").
  Com vários autores, as buscas são feitas uma a uma e emendas repetidas
  (a busca é parcial) são deduplicadas pelo código.

- tipo:

  Tipo de emenda, como na API (ex.:
  `"Emenda Individual - Transferências com Finalidade Definida"`).

- codigo, numero, funcao, subfuncao:

  Demais filtros da API (texto).

- max_paginas:

  Limite de páginas (15 registros cada). Padrão: todas.

- .progress:

  Mostrar barra de progresso quando houver mais de um item.

## Value

Tibble; valores em R\$ numéricos, nomes em `snake_case`.

## See also

[`pt_emenda_documentos()`](https://strategicprojects.github.io/siop/reference/pt_emenda_documentos.md),
[`emendas_execucao()`](https://strategicprojects.github.io/siop/reference/emendas_execucao.md)

## Examples

``` r
if (FALSE) { # \dontrun{
Sys.setenv(PORTAL_TRANSPARENCIA_API_KEY = "...")
pt_emendas(2025, autor = "NOME DO PARLAMENTAR")
} # }
```
