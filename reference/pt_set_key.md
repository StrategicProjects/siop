# Chave da API do Portal da Transparência

A chave é gratuita:
<https://portaldatransparencia.gov.br/api-de-dados/cadastrar-email>.
Informe-a na variável de ambiente `PORTAL_TRANSPARENCIA_API_KEY` (por
exemplo no `.Renviron`) ou, para a sessão, com `pt_set_key()`. O pacote
nunca grava a chave em disco.

## Usage

``` r
pt_set_key(key)

pt_has_key()
```

## Arguments

- key:

  Texto da chave; `NULL` para voltar a usar a variável de ambiente.

## Value

`pt_set_key()` devolve `NULL` invisivelmente; `pt_has_key()` um lógico.
