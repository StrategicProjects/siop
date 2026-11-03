# Emendas com seus documentos e favorecidos (uma linha por documento)

Combina
[`pt_emendas()`](https://strategicprojects.github.io/siop/reference/pt_emendas.md),
[`pt_emenda_documentos()`](https://strategicprojects.github.io/siop/reference/pt_emenda_documentos.md)
e, se `detalhar = TRUE`,
[`pt_despesa_documento()`](https://strategicprojects.github.io/siop/reference/pt_despesa_documento.md).
Custo em requisições: 1 por página de emendas + 1 ou mais por emenda (+
1 por documento ao detalhar); o limite de 90 req/min é respeitado
automaticamente.

## Usage

``` r
emendas_execucao(
  ano,
  autor = NULL,
  tipo = NULL,
  detalhar = TRUE,
  max_emendas = Inf,
  .progress = TRUE
)
```

## Arguments

- ano:

  Ano da emenda.

- autor:

  Nome do parlamentar (busca textual da API). Acentos são removidos e o
  nome vai em maiúsculas automaticamente — a busca da API não encontra
  nomes acentuados ("Túlio Gadêlha" vira "TULIO GADELHA").

- tipo:

  Tipo de emenda, como na API (ex.:
  `"Emenda Individual - Transferências com Finalidade Definida"`).

- detalhar:

  Buscar o detalhe (favorecido, UG, UO...) de cada documento.

- max_emendas:

  Limitar o número de emendas processadas (útil para explorar).

- .progress:

  Mostrar progresso.

## Value

Tibble.
