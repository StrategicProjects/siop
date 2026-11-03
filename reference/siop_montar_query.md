# Montar a consulta SPARQL do orçamento

Preenche o template `inst/sparql/orcamento.rq` com o exercício e os
filtros. Útil para inspecionar ou adaptar a consulta antes de executá-la
com
[`siop_sparql()`](https://strategicprojects.github.io/siop/reference/siop_sparql.md).

## Usage

``` r
siop_montar_query(exercicio, ...)
```

## Arguments

- exercicio:

  Ano da LOA (grafo `http://orcamento.dados.gov.br/<ano>/`).

- ...:

  Filtros por código (texto, vetorizável):
  `esfera, orgao, uo, funcao, subfuncao, programa, acao, localizador, po, fonte, categoria, gnd, modalidade, elemento, iduso, rp`.

## Value

Texto da consulta.
