# API REST do Portal da Transparência (CGU) — recorte "Emendas parlamentares"

Base: https://api.portaldatransparencia.gov.br
Auth: header `chave-api-dados: <chave>` (cadastro gratuito em portaldatransparencia.gov.br/api-de-dados/cadastrar-email)
Licença: Decreto 8.777/2016. Contato: listaapitransparencia@cgu.gov.br
Paginação: `pagina` (obrigatório, default 1); páginas de até 15 registros (padrão do portal). Fim = array vazio.
Limites conhecidos (doc do portal): 90 req/min (06:00–23:59) e 300 req/min (00:00–05:59).

## GET /api-de-dados/emendas
Parâmetros (query, todos opcionais exceto pagina):
  codigoEmenda:string, numeroEmenda:string, nomeAutor:string, tipoEmenda:string,
  ano:int, codigoFuncao:string, codigoSubfuncao:string, pagina:int*
Resposta: [ConsultaEmendasDTO]
  codigoEmenda, ano:int, tipoEmenda, autor, nomeAutor, numeroEmenda, localidadeDoGasto,
  funcao, subfuncao, valorEmpenhado, valorLiquidado, valorPago, valorRestoInscrito,
  valorRestoCancelado, valorRestoPago   (valores como string "1.234,56")

## GET /api-de-dados/emendas/documentos/{codigo}?pagina=
Resposta: [DocumentoRelacionadoEmendaDTO]
  id:int, data, fase, codigoDocumento, codigoDocumentoResumido, especieTipo, tipoEmenda

## Encadeamento para "detalhes" (documentos de despesa)
GET /api-de-dados/despesas/documentos/{codigo}            -> DespesasPorDocumentoDTO (favorecido, UG, UO, órgão, função/subfunção/programa/ação/localizador, valor, autor, ...)
GET /api-de-dados/despesas/documentos-relacionados?codigoDocumento=&fase=(1 empenho|2 liquidação|3 pagamento)
GET /api-de-dados/despesas/favorecidos-finais-por-documento?codigoDocumento=&pagina=
