# siop — monorepo siopr (R) + siopy (Python)

Clientes espelhados para fontes públicas do orçamento federal. Regra de ouro: **toda função
nova nasce nos dois pacotes**, com o mesmo nome, colunas `snake_case` em português e prefixo
pela fonte (`siop_` SIOP, `pt_` Portal da Transparência, `camara_`/`ibge_`/`cnpj_` apoio).
Funções `pt_*` são vetorizadas: vetor/lista entra, um tibble/DataFrame sai, com a coluna-chave
na frente e progresso nos loops longos. Decisões e seus porquês vivem no `DECISIONS.md` da
raiz — leia antes de mexer em SPARQL, nomes ou empacotamento, e registre lá o que decidir.

## Comandos

```bash
# R (em siopr/)
Rscript -e 'devtools::test()'                       # offline (mocks httr2)
SIOPR_LIVE=true Rscript -e 'devtools::test()'       # + chamadas reais (chave no ~/.Renviron)
Rscript -e 'devtools::check(args = c("--no-manual", "--as-cran"))'
Rscript -e 'devtools::document()'                   # após mexer em roxygen

# Python (em siopy/)
uv run --extra dev python -m pytest tests/ -q      # SIOPY_LIVE=true para os live
uv run --extra dev python -m ruff check --fix src tests && uv run --extra dev python -m ruff format src tests
```

## Armadilhas que já custaram retrabalho

- **CRAN proíbe não-ASCII em código R** (strings; comentários/roxygen podem). E as ferramentas
  de edição materializam `\uxxxx` em acentos reais ao gravar — para escrever escapes literais
  use perl: `perl -C -i -pe 's/([^\x00-\x7F])/sprintf("\\\\u%04x", ord($1))/ge'` nas linhas de
  código. Conferir com `tools::showNonASCIIfile()` só nas linhas que não são comentário.
- **Busca de autor do Portal não encontra nomes acentuados** — `pt_emendas()` já normaliza
  (via `sem_acento()`); não use `iconv //TRANSLIT` (no macOS vira `ANDR'E`). A busca é parcial:
  "DA FONTE" devolve dois deputados; por isso o multi-autor deduplica por `codigo_emenda` e a
  vinheta casa por igualdade exata.
- **Job R 4.1 do CI** instala só deps hard + `Config/Needs/check41` (DESCRIPTION): os Suggests
  de vinheta (ggplot2/geobr) não resolvem em 4.1. Suggests novo usado em vinheta → declare no
  DESCRIPTION mesmo com `eval = FALSE` (o check acusa unstated dependency).
- **`r-lib/actions/setup-r@v2` às vezes trava ~20 min no Ubuntu** (visto 2x em 2026-11-06, em
  jobs diferentes; não é do código). Cancelar e `gh run rerun <id> --failed` resolve. Actions
  dos workflows estão em versões Node 24 (2026-11); ao subir versão, confira `runs.using` no
  `action.yml` da tag; ações de terceiros vão pinadas por SHA com `# vX.Y.Z` (exceto
  `gh-action-pypi-publish`, ação Docker — ver comentário no `pypi.yaml`).
- **Vinhetas rodam com `eval = FALSE`** (CRAN sem rede/chave): as saídas reais vão como
  comentários `#>` e as figuras são pré-computadas em `vignettes/figures/`. Scripts e agregados
  que as regeneram: `siopr/data-raw/emendas-pe/` (fora do build via .Rbuildignore). Os CSVs
  brutos da coleta não estão no repo — regeneram-se pelos scripts (~35 min, rate limit 90/min).
- **Virtuoso/SPARQL**: nunca `ORDER BY`+`OFFSET` (limite 10k); consultas grandes particionam
  por órgão. Medido 2026-11: órgão inteiro (MEC) 128k linhas em ~91 s — aceitável, sem mexer.
- **CRAN rejeita link relativo no README.md** ("invalid file URI" — foi o motivo da devolução
  de 2026-11-03): links para fora do pacote (ex.: `../siopy`) têm de ser URL absoluta; só podem
  ser relativos os caminhos de arquivos que vão no tarball (`man/figures/*`). E a URL do siopy
  é `…github.io/siop/siopy/` — a forma `…github.io/siopy/` dá 404.

## Publicação

Site: push em main → workflows `pkgdown` (R, raiz do site) e `siopy-docs` (mkdocs em /siopy/)
publicam em gh-pages; ver `gh run list`. CRAN: `rcmdcheck` no tarball + upload
(`devtools:::upload_cran` dispensa prompt; em auto mode o classificador bloqueia — o usuário
autoriza na conversa); registrar em `siopr/CRAN-SUBMISSION`; depois do upload o usuário clica
o link no e-mail (leite@castlab.org). PyPI:
tag `siopy-v*` dispara `pypi.yaml` (trusted publishing; distribuição `siopy-br`, import
`siopy`); acompanhar com `gh run watch` e conferir em `pypi.org/pypi/siopy-br/json`.
E-mail de autoria: leite@castlab.org.

Onde está uma submissão no CRAN: as pastas de `https://cran.r-project.org/incoming/`
(`newbies/` = pacote novo aguardando inspeção manual, fila FIFO de ~2 semanas em 2026-11;
`waiting/` = aguardando resposta do mantenedor; `pretest/`, `inspect/`, `pending/`, `publish/`,
pastas com iniciais de revisores; `archive/` = submissões devolvidas/antigas). Algumas
listagens (`archive/`) são enormes e lentas — `curl --max-time 30` em cada uma, e
`sed 's/<[^>]*>/ /g' | grep tar.gz | awk '{print $2,$3,$1}' | sort | nl` dá a posição na fila.
