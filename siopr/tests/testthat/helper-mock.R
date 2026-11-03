fx <- function(name) system.file("extdata", name, package = "siopr", mustWork = TRUE)
fx_text <- function(name) paste(readLines(fx(name), encoding = "UTF-8", warn = FALSE), collapse = "\n")

resp_csv <- function(name) httr2::response(200, headers = list(`Content-Type` = "text/csv"), body = charToRaw(fx_text(name)))
resp_json <- function(name) httr2::response(200, headers = list(`Content-Type` = "application/json"), body = charToRaw(fx_text(name)))
resp_json_text <- function(txt) httr2::response(200, headers = list(`Content-Type` = "application/json"), body = charToRaw(txt))
resp_html <- function(txt) httr2::response(200, headers = list(`Content-Type` = "text/html"), body = charToRaw(txt))

# fila de respostas + registro das requisições (para inspecionar URL/headers)
mock_queue <- function(..., env = parent.frame()) {
  fila <- list(...)
  reqs <- list()
  i <- 0
  f <- function(req) {
    i <<- i + 1
    reqs[[i]] <<- req
    r <- fila[[min(i, length(fila))]]
    if (is.function(r)) r(req) else r
  }
  httr2::local_mocked_responses(f, env = env)
  function() reqs
}

HTML_CAT <- '<html><body><div id="dokuwiki__content">
<h2 class="x">1. Arquivos de Dados em RDF da Execução do Orçamento Federal</h2>
<a href="https://www1.siop.planejamento.gov.br/downloads/rdf/loa2025.zip" class="urlextern">LOA 2025</a>
<h2>4. Arquivos de Dados em CSV do Cadastro de Ações do Orçamento Federal</h2>
<a href="/siopdoc/lib/exe/fetch.php/dados_abertos:cadastroacao:2025:dados_acao2025.csv">Ações 2025</a>
<a href="/siopdoc/lib/exe/fetch.php/dados_abertos:cadastroacao:2025:dados_localizador2025.csv">Localizadores 2025</a>
<a href="/siopdoc/lib/exe/fetch.php/dados_abertos:cadastroacao:2025:dados_plano_orcamentario2025.csv">Planos Orçamentários 2025</a>
<h2>5. Arquivos de Dados em CSV de Alterações Orçamentárias - Créditos</h2>
<a href="/siopdoc/lib/exe/fetch.php/dados_abertos:alteracoes:alteracoesorcamentarias_2025.csv">Alterações Orçamentárias - créditos 2025</a>
<a href="/siopdoc/lib/exe/fetch.php/acesso_publico:dados_abertos:dicionariodadosatosalteracoesorcamentarias.pdf">Dicionário de Dados</a>
<h3>Arquivos de Dados em CSV da Regionalização das Ações do Orçamento Federal</h3>
<a href="/siopdoc/lib/exe/fetch.php/acesso_publico:dados_abertos:dados_regionalizados_orcamento_2025_publicado_v12_05_2026.csv">Regionalização das Ações do Orçamento Federal - 2025</a>
</div></body></html>'
