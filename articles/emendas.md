# Emendas parlamentares: do RDF do SIOP ao Portal da Transparência

## Duas fontes, dois recortes

O orçamento federal marca as emendas pelo classificador **Resultado
Primário**: 6 (individuais), 7 (bancada), 8 (comissão) e 9 (relator). O
RDF publicado pela SOF traz essas linhas com toda a classificação e a
execução (empenhado, liquidado, pago), mas **sem autor nem número de
emenda**. Esses atributos — e os documentos SIAFI de cada emenda — estão
na API do Portal da Transparência.

``` r

library(siopr)

em <- siop_emendas(2025, tipo = c("individual", "bancada"))
dplyr::summarise(em, loa = sum(loa), empenhado = sum(empenhado), pago = sum(pago),
                 .by = c(tipo_emenda, desc_funcao))
```

## Por autor, com execução documento a documento

``` r

Sys.setenv(PORTAL_TRANSPARENCIA_API_KEY = "sua-chave")
ex <- emendas_execucao(2025, autor = "NOME DO PARLAMENTAR")
dplyr::count(ex, nome_favorecido, uf_favorecido, wt = valor, sort = TRUE)
```

## Cruzando as duas fontes

A chave natural entre elas é a classificação funcional-programática
(`cod_funcao`, `cod_acao`, `cod_localizador`) do RDF e os campos
`funcao`/`acao`/`localizador_gasto` do detalhe do documento no Portal
(que vêm como `"código - descrição"`).

``` r

ex$cod_acao <- sub(" - .*$", "", ex$acao)
dplyr::inner_join(ex, em, by = c("cod_acao"), suffix = c("_pt", "_siop"))
```

## Quão atuais são os dados?

``` r

siop_ultima_atualizacao()
```
