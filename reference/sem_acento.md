# Remover acentos

Troca caracteres acentuados do português pelos equivalentes ASCII, sem
depender do [`iconv()`](https://rdrr.io/r/base/iconv.html) da plataforma
(o `//TRANSLIT` do macOS gera marcas como `"ANDR'E"`). Útil para casar
nomes entre fontes — a busca textual do Portal da Transparência, por
exemplo, não encontra nomes acentuados.

## Usage

``` r
sem_acento(x)
```

## Arguments

- x:

  Vetor de texto.

## Value

Vetor de texto sem acentos, preservando maiúsculas/minúsculas.

## Examples

``` r
sem_acento(c("Túlio Gadêlha", "São João"))
#> [1] "Tulio Gadelha" "Sao Joao"     
```
