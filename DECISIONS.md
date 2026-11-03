# DECISIONS.md — siopr / siopy

Registro de decisões de projeto. Formato: data · decisão · contexto/alternativas · consequências.

## 2026-11-03 · Escopo: apenas fontes públicas (sem API GraphQL autenticada do SIOP)

**Contexto.** As APIs listadas no Conecta gov.br ("Emendas Individuais SIOP",
`/modulo/impositivo/itens/api` etc.) são GraphQL e exigem `Authorization: Bearer <token>`
obtido em `POST /modulo/login/rest/login` com usuário/senha do SIOP (validade 48 h). Sem token:
HTTP 401. Segundo `controle_acesso:solicitacao_acesso`, o cadastro de usuários é feito por
Cadastradores Locais de órgãos federais (Portaria 130/2012); integrações de sistemas só para
órgãos do SIPOF via Central de Atendimento SIOP. Pesquisadores externos são direcionados ao
SIOP-Acesso Público / Dados Abertos. Além disso, `itens` só retorna emendas de autores/órgãos
vinculados ao usuário — mesmo com credencial, não daria uma visão completa.

**Decisão.** Os pacotes cobrem (1) SIOP Dados Abertos (SPARQL + CSVs) e (2) API REST do Portal
da Transparência (CGU), módulo de emendas e documentos de despesa. Os schemas GraphQL obtidos por
introspecção ficam em `schemas/` como referência para um futuro módulo autenticado.

**Alternativas descartadas.** Cliente GraphQL completo contra schema sem possibilidade de teste
ao vivo (risco alto de API inútil na prática).

## 2026-11-03 · Nomes: `siopr` (R) e `siopy` (Python); prefixos `siop_` e `pt_`

`siop_*` → SIOP Dados Abertos; `pt_*` → Portal da Transparência. Funções espelhadas nos dois
pacotes com os mesmos nomes e colunas (snake_case, português, sem acentos).

## 2026-11-03 · SPARQL: CSV como formato de transporte, sem ORDER BY, particionamento por órgão

- O endpoint Virtuoso (`https://www1.siop.planejamento.gov.br/sparql/`) aceita `format=text/csv`.
  JSON (`application/sparql-results+json`) é ~5× maior (4,9 MB para 24 k linhas × 2 colunas).
- Virtuoso limita `ORDER BY ... LIMIT/OFFSET` a 10 000 linhas ordenadas (erro SR353). Sem
  ORDER BY não há limite observado (50 000 linhas OK). Portanto: **nunca** paginar por OFFSET;
  consultas grandes (orçamento inteiro, ~390 k linhas/ano) são particionadas por órgão.
- Emendas (RP 6/7/8/9) cabem numa única consulta (2025: 23 963 linhas RP6 em ~9 s).

## 2026-11-03 · Emendas no RDF = linhas com Resultado Primário 6, 7, 8, 9

Doc oficial: RP6 = individuais (desde 2014), RP7 = bancada (desde 2017). Observado no grafo 2025
também RP8 (comissão) e, em 2020–2022, RP9 (relator). O RDF **não** traz autor nem número da
emenda — isso só existe no Portal da Transparência.

## 2026-11-03 · CSVs do SIOP: catálogo raspado da página de Dados Abertos

Os nomes de arquivo são irregulares (datas de publicação embutidas, `.zip`/`.rar`, caminhos
diferentes por ano). Em vez de hard-codar URLs, `siop_catalogo()` raspa
`acesso_publico:dados_abertos` e devolve (categoria, exercicio, titulo, url). Downloads são
cacheados em disco (`tools::R_user_dir("siopr","cache")` / `platformdirs.user_cache_dir("siopy")`),
com `refresh = TRUE` para forçar nova baixa. Encoding varia (latin1 no cadastro de ações, UTF-8
com BOM nos créditos): detectar tentando UTF-8 e caindo para latin1. Separador `;`, decimal `,`.

## 2026-11-03 · Portal da Transparência: chave só por variável de ambiente

`PORTAL_TRANSPARENCIA_API_KEY`. Nunca gravada em arquivo pelo pacote. Rate limit interno
conservador (90 req/min; 300 entre 00:00 e 05:59 BRT, mas usamos 90 sempre). Paginação automática
até página vazia; `max_paginas` como válvula. Valores monetários "1.234,56" → numérico.

## 2026-11-03 · Testes: fixtures gravadas + testes ao vivo opt-in

R: `httr2::local_mocked_responses()` (sem httptest2). Python: `respx`. Testes ao vivo rodam
apenas com `SIOPR_LIVE=true` / `SIOPY_LIVE=true` (e a chave, para `pt_*`).

## 2026-11-03 · Dependências mínimas

R: httr2, tibble, readr, cli, rlang (Suggests: testthat, knitr). Python: httpx, pandas,
platformdirs (dev: pytest, respx). Sem rdflib/SPARQLWrapper — parse direto do CSV/JSON.

## 2026-11-03 · RESOLVIDO: desempenho da consulta completa por órgão

Medido em 2026-11-03 via pacote (não navegador): `siop_emendas(2025, tipo = c("individual",
"bancada"), orgao = "26000")` → 5.956 linhas em 20,4 s; `siop_orcamento(2025, orgao = "26000")`
→ 127.970 linhas em 91,3 s, ponta a ponta, sem timeout. O >45 s observado no navegador não se
reproduz no cliente. Desempenho aceitável; as mitigações (a)/(b) abaixo ficam como opções
futuras, não necessárias.

## 2026-11-03 · (histórico) Pendência: desempenho da consulta completa por órgão

O template `orcamento.rq` (42 colunas, com rótulos de todos os classificadores) foi validado
ponta a ponta com `LIMIT 5` e com os filtros `FILTER(?cod_rp IN (...))`. A execução sem LIMIT
para um órgão grande (MEC, RP 6/7, 2025) ultrapassou 45 s no navegador e não pôde ser medida
até o fim nesta sessão. Se ficar lento na prática, as opções são: (a) remover os `OPTIONAL`
de rótulos raramente usados (`desc_po`, `desc_fonte`, `desc_elemento`, `desc_iduso`,
`desc_rp`) e resolvê-los depois com uma consulta de dicionário por exercício; (b) particionar
também por UO. Os testes ao vivo (`SIOPR_LIVE`/`SIOPY_LIVE`) cobrem esse caso.

## 2026-11-03 · Publicação: repo StrategicProjects/siop, CRAN e PyPI

Monorepo público `github.com/StrategicProjects/siop` (padrão da org, como `misocial`):
`siopr/` + `siopy/` + workflows na raiz (`siopr.yaml` R CMD check, `siopy.yaml` pytest+ruff,
`pkgdown.yaml` site em gh-pages, `pypi.yaml` trusted publishing em tags `siopy-v*`).
Site pkgdown em <https://strategicprojects.github.io/siop/>. Identidade visual: hexágono
petróleo (#0e3a53→#2c7da0) com documento da LOA, linha de emenda em âmbar e três moedas
E/L/P (empenhado, liquidado, pago); diagramas `architecture.svg` e `fluxo-emendas.svg` em
`siopr/man/figures/`, compartilhados pelos dois READMEs (o siopy referencia por URL raw).
DESCRIPTION com Title/Description em inglês (prática CRAN da org) e `Language: pt-BR` para a
documentação em português. Nomes conferidos livres em 2026-11-03: `siopr` não existe no CRAN,
`siopy` não existe no PyPI. Publicação no PyPI por trusted publishing (configurar o publisher
pendente no PyPI: owner StrategicProjects, repo siop, workflow pypi.yaml, environment pypi).

## 2026-11-03 · PyPI: distribuição `siopy-br`, import `siopy`

O PyPI recusou o nome `siopy`: a checagem de similaridade ultranormaliza nomes dobrando
caracteres confundíveis (i≡l, o≡0) e `siopy` colide com o projeto existente `slopy`.
Alternativas conferidas livres: siopy-br, siopbr, pysiop, emendaspy (sioppy colide com sloppy).
Escolhido **`siopy-br`** (pending publisher criado pelo usuário: repo StrategicProjects/siop,
workflow pypi.yaml, environment pypi): muda só o nome de distribuição; o pacote importável
continua `siopy`, preservando código, docs, site e o espelho com `siopr`. Precedente na org:
`pixbr`.

## 2026-11-03 · Funções de apoio: `camara_deputados`, `ibge_municipios`, `cnpj_municipio`, `sem_acento`

A vinheta/guia "Em que municípios..." exigia chamadas cruas a três APIs públicas sem chave;
viraram funções espelhadas nos dois pacotes (prefixo = fonte, como `siop_`/`pt_`): Câmara dos
Deputados (`/deputados`, com paginação por `links.next`), IBGE localidades (grafia oficial dos
municípios) e Minha Receita (município da sede de um CNPJ — resolve favorecidos genéricos tipo
"FUNDO MUNICIPAL DE SAUDE"). `sem_acento()` é exportada (a busca textual do Portal não encontra
nomes acentuados e o `iconv //TRANSLIT` do macOS gera marcas) e `pt_emendas()` normaliza o
`autor` automaticamente. No código R, strings não-ASCII só com escapes `\uxxxx` (R CMD check
avisa mesmo com Encoding: UTF-8).
