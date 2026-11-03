# Emendas parlamentares: do RDF do SIOP ao Portal da Transparência

A mesma vinheta do pacote R
[`siopr`](https://strategicprojects.github.io/siop/articles/emendas.html),
em Python.

## Duas fontes, dois recortes

O orçamento federal marca as emendas pelo classificador **Resultado
Primário**: 6 (individuais), 7 (bancada), 8 (comissão) e 9 (relator). O RDF
publicado pela SOF traz essas linhas com toda a classificação e a execução
(empenhado, liquidado, pago), mas **sem autor nem número de emenda**. Esses
atributos — e os documentos SIAFI de cada emenda — estão na API do Portal da
Transparência.

```python
import siopy

em = siopy.siop_emendas(2025, tipo=["individual", "bancada"])
(
    em.groupby(["tipo_emenda", "desc_funcao"], as_index=False)[
        ["loa", "empenhado", "pago"]
    ].sum()
)
```

## Por autor, com execução documento a documento

```python
import os

os.environ["PORTAL_TRANSPARENCIA_API_KEY"] = "sua-chave"

ex = siopy.emendas_execucao(2025, autor="NOME DO PARLAMENTAR")
(
    ex.groupby(["nome_favorecido", "uf_favorecido"])["valor"]
    .sum()
    .sort_values(ascending=False)
)
```

## Cruzando as duas fontes

A chave natural entre elas é a classificação funcional-programática
(`cod_funcao`, `cod_acao`, `cod_localizador`) do RDF e os campos
`funcao`/`acao`/`localizador_gasto` do detalhe do documento no Portal (que
vêm como `"código - descrição"`).

```python
ex["cod_acao"] = ex["acao"].str.replace(r" - .*$", "", regex=True)
ex.merge(em, on="cod_acao", suffixes=("_pt", "_siop"))
```

## Quão atuais são os dados?

```python
siopy.siop_ultima_atualizacao()
```
