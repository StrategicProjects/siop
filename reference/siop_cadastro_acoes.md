# Cadastro de ações, localizadores e planos orçamentários (CSV oficial)

Cadastro de ações, localizadores e planos orçamentários (CSV oficial)

## Usage

``` r
siop_cadastro_acoes(
  exercicio,
  tipo = c("acoes", "localizadores", "planos_orcamentarios"),
  refresh = FALSE
)
```

## Arguments

- exercicio:

  Ano.

- tipo:

  `"acoes"`, `"localizadores"` ou `"planos_orcamentarios"`.

- refresh:

  Baixar novamente ignorando o cache.

## Value

Tibble com todas as colunas como texto (nomes originais do arquivo).
