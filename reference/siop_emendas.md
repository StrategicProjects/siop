# Dotações de emendas parlamentares na LOA (RP 6/7/8/9)

Atalho de
[`siop_orcamento()`](https://strategicprojects.github.io/siop/reference/siop_orcamento.md)
filtrando o Resultado Primário das emendas e acrescentando a coluna
`tipo_emenda`.

## Usage

``` r
siop_emendas(exercicio, tipo = names(tipo_emenda_rp), ...)
```

## Arguments

- exercicio:

  Ano da LOA (grafo `http://orcamento.dados.gov.br/<ano>/`).

- tipo:

  Um ou mais de `"individual"`, `"bancada"`, `"comissao"`, `"relator"`.

- ...:

  Filtros por código (texto, vetorizável):
  `esfera, orgao, uo, funcao, subfuncao, programa, acao, localizador, po, fonte, categoria, gnd, modalidade, elemento, iduso, rp`.

## Value

Tibble como em
[`siop_orcamento()`](https://strategicprojects.github.io/siop/reference/siop_orcamento.md),
com `tipo_emenda`.

## Details

O RDF do SIOP **não** traz autor nem número da emenda; para isso use
[`pt_emendas()`](https://strategicprojects.github.io/siop/reference/pt_emendas.md)
(Portal da Transparência).

## Examples

``` r
if (FALSE) { # \dontrun{
em <- siop_emendas(2025, tipo = c("individual", "bancada"))
dplyr::count(em, tipo_emenda, wt = loa)
} # }
```
