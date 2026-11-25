## Resubmission: siopr 0.1.0

This is a resubmission. Changes made in response to the review by Leonore
Hochhauser:

* Software and API names in the Title and Description are now in single
  quotes ('SIOP', 'Portal da Transparencia', 'SPARQL', 'REST', 'tidyverse',
  'tbl_df').
* The Title was shortened to 62 characters.
* The URL `https://portaldatransparencia.gov.br/api-de-dados/cadastrar-email`
  (status 405) is no longer a link in `man/pt_set_key.Rd` and `README.md`.
  The page works in a browser, but the government site rejects automated
  requests, so the address is now given as plain text.
* `\value` was added to `pt_documentos_relacionados.Rd`,
  `pt_favorecidos_finais.Rd`, `siop_acompanhamento.Rd` and
  `tipo_emenda_rp.Rd` (the last one is an exported character vector, not a
  function), describing the class, structure and meaning of the output.

Earlier resubmission: as requested by Uwe Ligges, the invalid relative file
URI `../siopy` in README.md was replaced by the absolute URL of the sibling
package's documentation (<https://strategicprojects.github.io/siop/siopy/>).

## Original submission notes

This is a new submission. The package is a tidyverse-friendly client for
public sources of the Brazilian federal budget: the SPARQL endpoint and the
official CSV files of the SIOP open data portal (Federal Budget
Secretariat), and the REST API of the Portal da Transparencia (CGU) for
parliamentary amendments.

The documentation is written in Brazilian Portuguese (`Language: pt-BR` in
DESCRIPTION); the intended audience works with the Brazilian federal
budget.

All examples that reach the network are wrapped in
`@examplesIf interactive()`; the test suite runs entirely offline against
recorded responses (`httr2::local_mocked_responses()`). Live tests only run
when the environment variable `SIOPR_LIVE=true` is set.

## R CMD check results

0 errors | 0 warnings | 1 note

* New submission.

## Test environments

* local: macOS (aarch64-apple-darwin), R release
* GitHub Actions: ubuntu-latest (release, oldrel-1, 4.1), windows-latest
  (release), macos-latest (release)
