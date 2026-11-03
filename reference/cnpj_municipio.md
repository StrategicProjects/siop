# Município da sede de um CNPJ (Minha Receita)

Consulta <https://minhareceita.org> (espelho aberto do cadastro CNPJ da
Receita Federal) e devolve o município e a UF da sede de cada CNPJ.
Resolve favorecidos de nome genérico ("FUNDO MUNICIPAL DE SAUDE") nos
documentos de despesa.

## Usage

``` r
cnpj_municipio(cnpj)
```

## Arguments

- cnpj:

  Vetor de CNPJs, com ou sem pontuação.

## Value

Tibble com `cnpj` (como informado), `municipio` e `uf`; linhas não
encontradas vêm com `NA`.

## See also

[`pt_despesa_documento()`](https://strategicprojects.github.io/siop/reference/pt_despesa_documento.md),
que traz o CNPJ do favorecido.

## Examples

``` r
if (FALSE) { # interactive()
cnpj_municipio("00.394.460/0058-87")
}
```
