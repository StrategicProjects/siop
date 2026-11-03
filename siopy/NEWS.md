# siopy 0.1.0

Primeira versão. Mesma superfície do pacote R
[`siopr`](https://github.com/StrategicProjects/siop/tree/main/siopr):
mesmos nomes de função, mesmas colunas.

* Fontes SIOP Dados Abertos (sem credencial):
  * `siop_emendas()` e `siop_orcamento()` — linhas da LOA via SPARQL, com
    classificação completa e valores (PLOA, LOA, lei + créditos, empenhado,
    liquidado, pago); emendas identificadas pelo Resultado Primário
    (6 individual, 7 bancada, 8 comissão, 9 relator). Sem filtro, o
    orçamento inteiro é particionado por órgão.
  * `siop_sparql()` — consulta SPARQL crua, resultado em DataFrame
    (transporte CSV).
  * `siop_orgaos()`, `siop_exercicios()`, `siop_ultima_atualizacao()` —
    metadados do RDF.
  * `siop_catalogo()`, `siop_download()`, `siop_cadastro_acoes()`,
    `siop_creditos()`, `siop_acompanhamento()`, `siop_regionalizacao()` —
    CSVs oficiais com cache em disco (`platformdirs`), extração de zip e
    detecção de encoding (UTF-8 com fallback latin1).
* Portal da Transparência (chave gratuita em
  `PORTAL_TRANSPARENCIA_API_KEY`):
  * `pt_emendas()`, `pt_emenda_documentos()`, `pt_despesa_documento()`,
    `pt_documentos_relacionados()`, `pt_favorecidos_finais()` — com
    paginação automática e rate limit interno de 90 req/min.
  * `emendas_execucao()` — junta emendas e documentos: uma linha por
    documento de despesa, com favorecido, UG e UO.
* Valores "1.234,56" convertidos para numérico; códigos sempre texto;
  colunas em `snake_case`.
* Testes offline com `respx`; testes ao vivo opt-in com `SIOPY_LIVE=true`.
