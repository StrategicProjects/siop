# Tipos de emenda e seus códigos de Resultado Primário (RP)

No orçamento federal as emendas parlamentares são identificadas pelo
classificador Resultado Primário: 6 = individuais (desde 2014), 7 =
bancada (desde 2017), 8 = comissão e 9 = relator (observados a partir de
2020).

## Usage

``` r
tipo_emenda_rp
```

## Format

Vetor nomeado de texto.

## Value

Um vetor de texto (`character`) nomeado, de comprimento 4: os nomes são
os tipos de emenda (`individual`, `bancada`, `comissao`, `relator`) e os
valores, os códigos de Resultado Primário correspondentes (`"6"`, `"7"`,
`"8"`, `"9"`). Não é uma função: é um objeto exportado, usado por
[`siop_emendas()`](https://strategicprojects.github.io/siop/reference/siop_emendas.md).
