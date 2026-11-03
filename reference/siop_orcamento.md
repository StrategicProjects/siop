# Linhas de despesa do Orçamento Federal (RDF do SIOP)

Devolve as linhas `loa:ItemDespesa` de um exercício com a classificação
completa (esfera, órgão, UO, função, subfunção, programa, ação,
localizador, PO, fonte, categoria, GND, modalidade, elemento, IdUso, RP)
e os valores: `ploa`, `autografo`, `loa` (dotação inicial),
`lei_mais_credito`, `empenhado`, `liquidado`, `pago`.

## Usage

``` r
siop_orcamento(exercicio, ..., particionar = NULL, .progress = TRUE)
```

## Arguments

- exercicio:

  Ano da LOA (grafo `http://orcamento.dados.gov.br/<ano>/`).

- ...:

  Filtros por código (texto, vetorizável):
  `esfera, orgao, uo, funcao, subfuncao, programa, acao, localizador, po, fonte, categoria, gnd, modalidade, elemento, iduso, rp`.

- particionar:

  Consultar órgão a órgão? Padrão: `TRUE` quando nenhum filtro é
  informado (o orçamento inteiro tem ~390 mil linhas/ano), `FALSE` caso
  contrário.

- .progress:

  Mostrar barra de progresso ao particionar.

## Value

Tibble; códigos como texto, valores numéricos (R\$).

## See also

[`siop_emendas()`](https://strategicprojects.github.io/siop/reference/siop_emendas.md),
[`siop_sparql()`](https://strategicprojects.github.io/siop/reference/siop_sparql.md)

## Examples

``` r
if (FALSE) { # \dontrun{
siop_orcamento(2025, orgao = "26000")
siop_orcamento(2025, funcao = "10", rp = c("6", "7"))
} # }
```
