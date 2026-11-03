# Package index

## Emendas e orçamento (SPARQL)

Linhas da LOA com classificação completa e execução, direto do RDF do
SIOP. Emendas são as linhas com Resultado Primário 6, 7, 8 ou 9.

- [`siop_emendas()`](https://strategicprojects.github.io/siop/reference/siop_emendas.md)
  : Dotações de emendas parlamentares na LOA (RP 6/7/8/9)
- [`siop_orcamento()`](https://strategicprojects.github.io/siop/reference/siop_orcamento.md)
  : Linhas de despesa do Orçamento Federal (RDF do SIOP)
- [`tipo_emenda_rp`](https://strategicprojects.github.io/siop/reference/tipo_emenda_rp.md)
  : Tipos de emenda e seus códigos de Resultado Primário (RP)
- [`siop_sparql()`](https://strategicprojects.github.io/siop/reference/siop_sparql.md)
  : Executar uma consulta SPARQL no endpoint do SIOP
- [`siop_montar_query()`](https://strategicprojects.github.io/siop/reference/siop_montar_query.md)
  : Montar a consulta SPARQL do orçamento

## Metadados do RDF

Órgãos, exercícios disponíveis e data da última carga.

- [`siop_orgaos()`](https://strategicprojects.github.io/siop/reference/siop_orgaos.md)
  : Órgãos orçamentários presentes no grafo de um exercício
- [`siop_exercicios()`](https://strategicprojects.github.io/siop/reference/siop_exercicios.md)
  [`siop_ultima_atualizacao()`](https://strategicprojects.github.io/siop/reference/siop_exercicios.md)
  : Exercícios disponíveis e data da última carga do RDF

## CSVs oficiais do SIOP

Tudo que está publicado na página de Dados Abertos, com cache em disco.

- [`siop_catalogo()`](https://strategicprojects.github.io/siop/reference/siop_catalogo.md)
  : Catálogo dos arquivos publicados nos Dados Abertos do SIOP
- [`siop_parse_catalogo()`](https://strategicprojects.github.io/siop/reference/siop_parse_catalogo.md)
  : Interpretar o HTML da página de Dados Abertos
- [`siop_download()`](https://strategicprojects.github.io/siop/reference/siop_download.md)
  : Baixar um arquivo dos Dados Abertos (com cache em disco)
- [`siop_cadastro_acoes()`](https://strategicprojects.github.io/siop/reference/siop_cadastro_acoes.md)
  : Cadastro de ações, localizadores e planos orçamentários (CSV
  oficial)
- [`siop_creditos()`](https://strategicprojects.github.io/siop/reference/siop_creditos.md)
  : Alterações orçamentárias (créditos) de um exercício
- [`siop_acompanhamento()`](https://strategicprojects.github.io/siop/reference/siop_acompanhamento.md)
  : Acompanhamento físico-financeiro das ações (CSV anual)
- [`siop_regionalizacao()`](https://strategicprojects.github.io/siop/reference/siop_regionalizacao.md)
  : Regionalização das ações do Orçamento Federal
- [`siop_cache_dir()`](https://strategicprojects.github.io/siop/reference/siop_cache_dir.md)
  : Diretório de cache dos downloads

## Portal da Transparência

Emendas por autor e documentos de despesa (SIAFI). Requer chave gratuita
em PORTAL_TRANSPARENCIA_API_KEY.

- [`pt_emendas()`](https://strategicprojects.github.io/siop/reference/pt_emendas.md)
  : Emendas parlamentares (Portal da Transparência)
- [`pt_emenda_documentos()`](https://strategicprojects.github.io/siop/reference/pt_emenda_documentos.md)
  : Documentos de despesa ligados a emendas
- [`pt_despesa_documento()`](https://strategicprojects.github.io/siop/reference/pt_despesa_documento.md)
  : Detalhe de documentos de despesa
- [`pt_documentos_relacionados()`](https://strategicprojects.github.io/siop/reference/pt_documentos_relacionados.md)
  : Documentos relacionados a documentos de despesa
- [`pt_favorecidos_finais()`](https://strategicprojects.github.io/siop/reference/pt_favorecidos_finais.md)
  : Favorecidos finais de documentos de despesa
- [`pt_set_key()`](https://strategicprojects.github.io/siop/reference/pt_set_key.md)
  [`pt_has_key()`](https://strategicprojects.github.io/siop/reference/pt_set_key.md)
  : Chave da API do Portal da Transparência

## Cruzamento

SIOP × Portal: uma linha por documento de despesa.

- [`emendas_execucao()`](https://strategicprojects.github.io/siop/reference/emendas_execucao.md)
  : Emendas com seus documentos e favorecidos (uma linha por documento)

## Apoio

Fontes públicas auxiliares, sem chave: deputados (Câmara), municípios
(IBGE) e sede de CNPJ (Minha Receita), além de utilitários de texto.

- [`camara_deputados()`](https://strategicprojects.github.io/siop/reference/camara_deputados.md)
  : Deputados federais (Dados Abertos da Câmara)
- [`ibge_municipios()`](https://strategicprojects.github.io/siop/reference/ibge_municipios.md)
  : Municípios (IBGE)
- [`cnpj_municipio()`](https://strategicprojects.github.io/siop/reference/cnpj_municipio.md)
  : Município da sede de um CNPJ (Minha Receita)
- [`sem_acento()`](https://strategicprojects.github.io/siop/reference/sem_acento.md)
  : Remover acentos
