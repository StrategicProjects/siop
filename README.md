# siop-sdk — `siopr` (R) e `siopy` (Python)

Pacotes irmãos, com a mesma superfície, para obter **emendas parlamentares e o orçamento
federal** a partir de fontes públicas:

| Prefixo | Fonte | Credencial |
|---|---|---|
| `siop_*` | SIOP Dados Abertos (SOF/MPO): endpoint SPARQL do RDF da LOA + CSVs oficiais | nenhuma |
| `pt_*` | API REST do Portal da Transparência (CGU): emendas por autor, documentos de despesa | chave gratuita (`PORTAL_TRANSPARENCIA_API_KEY`) |

```
siop-sdk/
├── siopr/        pacote R   (httr2 + tibble)      — R CMD check OK, 28 testes
├── siopy/        pacote Python (httpx + pandas)   — 23 testes (+4 live opt-in)
├── fixtures/     amostras reais (SPARQL) e sintéticas (Portal) usadas nos testes
├── schemas/      schemas GraphQL da API autenticada do SIOP (referência futura)
└── DECISIONS.md  decisões de projeto e seus porquês
```

## Superfície (idêntica nos dois pacotes)

| Função | O que devolve |
|---|---|
| `siop_emendas(ano, tipo, ...)` | linhas da LOA com RP 6/7/8/9 (individual/bancada/comissão/relator), classificação completa e valores (ploa, loa, lei+créditos, empenhado, liquidado, pago) |
| `siop_orcamento(ano, ...)` | idem sem filtro de RP; filtros por `orgao`, `uo`, `funcao`, `acao`, `rp`...; particiona por órgão quando sem filtro |
| `siop_sparql(query)` | SPARQL cru → tibble/DataFrame (CSV por padrão) |
| `siop_orgaos(ano)`, `siop_exercicios()`, `siop_ultima_atualizacao()` | metadados do RDF |
| `siop_catalogo()` | tudo que está publicado na página de Dados Abertos (URLs raspadas) |
| `siop_cadastro_acoes(ano, tipo)`, `siop_creditos(ano)`, `siop_acompanhamento(ano)`, `siop_regionalizacao(ano)` | CSVs oficiais com cache em disco |
| `pt_emendas(ano, autor, ...)` | emendas com autor, número, valores (todas as páginas) |
| `pt_emenda_documentos(codigo)` | empenhos/liquidações/pagamentos da emenda |
| `pt_despesa_documento(codigo)`, `pt_documentos_relacionados()`, `pt_favorecidos_finais()` | detalhe dos documentos SIAFI |
| `emendas_execucao(ano, autor)` | tudo unido: uma linha por documento com favorecido/UG/UO |

## Limitações conhecidas

* O RDF do SIOP não identifica autor nem número de emenda (só RP). Autor vem do Portal.
* O Virtuoso limita `ORDER BY`+`OFFSET` a 10 000 linhas; as consultas do pacote não ordenam e,
  para o orçamento inteiro, particionam por órgão. Consultas com todos os rótulos para um órgão
  grande podem levar dezenas de segundos.
* A API autenticada do SIOP (GraphQL, Conecta gov.br) exige usuário cadastrado por um órgão
  federal — fora do escopo; schemas em `schemas/`.

## Próximos passos sugeridos

1. Obter a chave do Portal e rodar os testes ao vivo (`SIOPR_LIVE=true` / `SIOPY_LIVE=true`).
2. Gravar fixtures reais do Portal (hoje sintéticas, fiéis ao OpenAPI v3) com `httptest2`/`respx`.
3. Função de cruzamento RDF × Portal por classificação funcional-programática (ver vignette).
4. pkgdown + GitHub Actions (R CMD check, pytest) e publicação no CRAN/PyPI.
