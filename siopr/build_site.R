# Rode este script em R, a partir da pasta siopr/, para montar o site
# pkgdown localmente:
#   install.packages("pkgdown")

pkgdown::build_site()

# O site é gerado em docs/ (gitignorado). Abra docs/index.html para
# conferir. O site publicado é montado por .github/workflows/pkgdown.yaml a
# cada push em main e servido do branch gh-pages em
# https://strategicprojects.github.io/siop/
