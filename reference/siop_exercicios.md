# Exercícios disponíveis e data da última carga do RDF

Exercícios disponíveis e data da última carga do RDF

## Usage

``` r
siop_exercicios()

siop_ultima_atualizacao(exercicio = NULL)
```

## Arguments

- exercicio:

  Opcional: restringir a um ano.

## Value

Tibble com `exercicio` (inteiro) e `data_atualizacao` (POSIXct, UTC), do
mais recente para o mais antigo.
