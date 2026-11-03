# Executar uma consulta SPARQL no endpoint do SIOP

Consulta o endpoint Virtuoso dos Dados Abertos do Orçamento Federal
(`https://www1.siop.planejamento.gov.br/sparql/`) e devolve um tibble.

## Usage

``` r
siop_sparql(query, format = c("csv", "json"), timeout = 300)
```

## Arguments

- query:

  Texto da consulta SPARQL. Os prefixos `loa:`, `rdfs:` e `rdf:` são
  adicionados automaticamente se ausentes.

- format:

  `"csv"` (padrão) ou `"json"`.

- timeout:

  Segundos.

## Value

Um tibble com uma coluna por variável da consulta, todas como texto.

## Details

Por padrão o resultado é pedido em `text/csv`, bem mais leve que JSON.
Com `format = "json"` usa-se `application/sparql-results+json`.

O Virtuoso limita `ORDER BY` + `LIMIT/OFFSET` a 10 000 linhas ordenadas
(erro SR353). Evite `ORDER BY` em consultas grandes e particione por
órgão/UO em vez de paginar por `OFFSET` — é o que
[`siop_orcamento()`](https://strategicprojects.github.io/siop/reference/siop_orcamento.md)
faz.

## Examples

``` r
if (FALSE) { # \dontrun{
siop_sparql("SELECT ?exercicio ?data WHERE { GRAPH ?g {
  ?e a loa:Exercicio ; loa:identificador ?exercicio ; loa:dataUltimaAtualizacao ?data } }")
} # }
```
