# Catálogo dos arquivos publicados nos Dados Abertos do SIOP

Raspa a página oficial (os nomes de arquivo são irregulares e mudam a
cada publicação) e devolve um tibble com `categoria` (`rdf`,
`acompanhamento`, `cadastro_acoes`, `creditos`, `regionalizacao`),
`subtipo` (`acoes`, `localizadores`, `planos_orcamentarios`), `tipo`
(`dados`/`dicionario`), `exercicio`, `titulo`, `formato` e `url`.

## Usage

``` r
siop_catalogo()
```

## Value

Tibble.
