# Changelog

## siopr 0.1.0

Primeira versão.

- Fontes SIOP Dados Abertos (sem credencial):
  - [`siop_emendas()`](https://strategicprojects.github.io/siop/reference/siop_emendas.md)
    e
    [`siop_orcamento()`](https://strategicprojects.github.io/siop/reference/siop_orcamento.md)
    — linhas da LOA via SPARQL, com classificação completa e valores
    (PLOA, LOA, lei + créditos, empenhado, liquidado, pago); emendas
    identificadas pelo Resultado Primário (6 individual, 7 bancada, 8
    comissão, 9 relator). Sem filtro, o orçamento inteiro é particionado
    por órgão (o Virtuoso limita OFFSET ordenado a 10 000 linhas).
  - [`siop_sparql()`](https://strategicprojects.github.io/siop/reference/siop_sparql.md)
    — consulta SPARQL crua, resultado em tibble (transporte CSV).
  - [`siop_orgaos()`](https://strategicprojects.github.io/siop/reference/siop_orgaos.md),
    [`siop_exercicios()`](https://strategicprojects.github.io/siop/reference/siop_exercicios.md),
    [`siop_ultima_atualizacao()`](https://strategicprojects.github.io/siop/reference/siop_exercicios.md)
    — metadados do RDF.
  - [`siop_catalogo()`](https://strategicprojects.github.io/siop/reference/siop_catalogo.md),
    [`siop_download()`](https://strategicprojects.github.io/siop/reference/siop_download.md),
    [`siop_cadastro_acoes()`](https://strategicprojects.github.io/siop/reference/siop_cadastro_acoes.md),
    [`siop_creditos()`](https://strategicprojects.github.io/siop/reference/siop_creditos.md),
    [`siop_acompanhamento()`](https://strategicprojects.github.io/siop/reference/siop_acompanhamento.md),
    [`siop_regionalizacao()`](https://strategicprojects.github.io/siop/reference/siop_regionalizacao.md)
    — CSVs oficiais raspados da página de Dados Abertos, com cache em
    disco
    ([`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html)),
    extração de zip e detecção de encoding (UTF-8 com fallback latin1).
- Portal da Transparência (chave gratuita em
  `PORTAL_TRANSPARENCIA_API_KEY`):
  - [`pt_emendas()`](https://strategicprojects.github.io/siop/reference/pt_emendas.md),
    [`pt_emenda_documentos()`](https://strategicprojects.github.io/siop/reference/pt_emenda_documentos.md),
    [`pt_despesa_documento()`](https://strategicprojects.github.io/siop/reference/pt_despesa_documento.md),
    [`pt_documentos_relacionados()`](https://strategicprojects.github.io/siop/reference/pt_documentos_relacionados.md),
    [`pt_favorecidos_finais()`](https://strategicprojects.github.io/siop/reference/pt_favorecidos_finais.md)
    — com paginação automática e rate limit interno de 90 req/min.
  - [`emendas_execucao()`](https://strategicprojects.github.io/siop/reference/emendas_execucao.md)
    — junta emendas e documentos: uma linha por documento de despesa,
    com favorecido, UG e UO.
- Valores “1.234,56” convertidos para numérico; códigos sempre texto
  (zeros à esquerda preservados); colunas em `snake_case`.
- Testes offline com
  [`httr2::local_mocked_responses()`](https://httr2.r-lib.org/reference/with_mocked_responses.html);
  testes ao vivo opt-in com `SIOPR_LIVE=true`.
