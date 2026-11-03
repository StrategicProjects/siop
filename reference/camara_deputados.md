# Deputados federais (Dados Abertos da Câmara)

Consulta `GET /deputados` da API de Dados Abertos da Câmara dos
Deputados, seguindo a paginação. Sem filtros, devolve os deputados em
exercício.

## Usage

``` r
camara_deputados(uf = NULL, legislatura = NULL)
```

## Arguments

- uf:

  Sigla(s) de UF (ex.: `"PE"`).

- legislatura:

  Número(s) de legislatura (ex.: `57`).

## Value

Tibble com `id`, `nome`, `sigla_partido`, `sigla_uf`, `id_legislatura` e
`email`.

## See also

[`pt_emendas()`](https://strategicprojects.github.io/siop/reference/pt_emendas.md)
para as emendas de cada autor.

## Examples

``` r
if (FALSE) { # interactive()
camara_deputados(uf = "PE")
}
```
