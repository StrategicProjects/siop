## Submission: siopr 0.1.0

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
