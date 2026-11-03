# Municípios (IBGE)

Consulta a API de localidades do IBGE: os municípios de uma ou mais UFs
(ou todos, se `uf = NULL`), com a grafia oficial dos nomes.

## Usage

``` r
ibge_municipios(uf = NULL)
```

## Arguments

- uf:

  Sigla(s) de UF (ex.: `"PE"`); `NULL` para o Brasil inteiro.

## Value

Tibble com `codigo` (7 dígitos, texto), `nome` e `uf`.

## Examples

``` r
if (FALSE) { # interactive()
ibge_municipios("PE")
}
```
