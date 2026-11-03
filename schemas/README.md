# SIOP GraphQL — schemas extraídos por introspecção (2026-11-03)

Origem: https://www.siop.planejamento.gov.br/modulo/<endpoint>/api  (POST, GraphQL)
Autenticação: `Authorization: Bearer <token>`; token via
  POST https://www.siop.planejamento.gov.br/modulo/login/rest/login  {"cpf"|"login": ..., "senha": ...}
  (validade 48h; resposta é a string do token entre aspas)
Ambiente de testes: https://testews.siop.gov.br/
Sem token: HTTP 401 {"err":"token up for parsing was not passed through the context"}

Endpoints (20): agregador, alteracoes-orcamentarias/pedidos, bi, cnpj, comunicacao,
impositivo/{beneficiarios,bloqueio,emendas,impedimentos,itens}, informacoes-complementares,
marcadores, permissoes, qualitativo, quantitativo, quantitativo/classificadores, orgaos,
orgaossiorg, parametros, siafi.

Formato de `programacao`: 99.99999.99.999.9999.AAAA.9999 = esfera.uo.funcao.subfuncao.programa.acao.localizador
Formato de `dotacao`:     9999.9.999.9999.9 (doc) = idoc.iduso.fonte.natureza.resultadoPrimario
