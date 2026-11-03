"""Arquivos CSV/ZIP dos Dados Abertos do SIOP: catálogo raspado da página oficial + cache."""

from __future__ import annotations

import hashlib
import io
import re
import zipfile
from html.parser import HTMLParser
from pathlib import Path

import pandas as pd
from platformdirs import user_cache_dir

from ._http import make_client, request_with_retry
from ._parse import brl_columns, decode_bytes, read_siop_csv

SIOP_DOC = "https://www1.siop.planejamento.gov.br"
CATALOGO_URL = f"{SIOP_DOC}/siopdoc/doku.php/acesso_publico:dados_abertos"

# categoria canônica -> regex no título da seção (h2/h3) da página
_CATEGORIAS = {
    "rdf": r"RDF da Execu",
    "acompanhamento": r"Acompanhamento F",
    "cadastro_acoes": r"Cadastro de A",
    "creditos": r"Cr[ée]ditos",
    "regionalizacao": r"Regionaliza",
}


class _Links(HTMLParser):
    """Coleta (seção, texto, href) dos links da área de conteúdo."""

    def __init__(self) -> None:
        super().__init__()
        self.secao = ""
        self._in_h = False
        self._h_buf: list[str] = []
        self._href: str | None = None
        self._a_buf: list[str] = []
        self.links: list[tuple[str, str, str]] = []

    def handle_starttag(self, tag, attrs):
        if tag in ("h1", "h2", "h3"):
            self._in_h, self._h_buf = True, []
        elif tag == "a":
            self._href = dict(attrs).get("href")
            self._a_buf = []

    def handle_endtag(self, tag):
        if tag in ("h1", "h2", "h3") and self._in_h:
            self.secao = "".join(self._h_buf).strip()
            self._in_h = False
        elif tag == "a" and self._href is not None:
            self.links.append((self.secao, "".join(self._a_buf).strip(), self._href))
            self._href = None

    def handle_data(self, data):
        if self._in_h:
            self._h_buf.append(data)
        if self._href is not None:
            self._a_buf.append(data)


def parse_catalogo(html: str) -> pd.DataFrame:
    p = _Links()
    p.feed(html)
    rows = []
    for secao, titulo, href in p.links:
        if not re.search(r"fetch\.php|/downloads/rdf/", href):
            continue
        cat = next((k for k, rx in _CATEGORIAS.items() if re.search(rx, secao)), None)
        if cat is None:
            continue
        url = href if href.startswith("http") else SIOP_DOC + href
        m = re.search(r"(20\d{2})", titulo) or re.search(r"(20\d{2})", url)
        exercicio = int(m.group(1)) if m else None
        ext = url.rsplit(".", 1)[-1].lower()
        tipo = "dicionario" if ext == "pdf" else "dados"
        subtipo = None
        if cat == "cadastro_acoes" and tipo == "dados":
            nome = url.rsplit(":", 1)[-1].lower()  # ex.: dados_acao2025.csv
            if "localizador" in nome:
                subtipo = "localizadores"
            elif "plano" in nome:
                subtipo = "planos_orcamentarios"
            else:
                subtipo = "acoes"
        rows.append(
            {
                "categoria": cat,
                "subtipo": subtipo,
                "tipo": tipo,
                "exercicio": exercicio,
                "titulo": titulo,
                "formato": ext,
                "url": url,
            }
        )
    df = pd.DataFrame(rows)
    if not df.empty:
        df["exercicio"] = df["exercicio"].astype("Int64")
    return df


def siop_catalogo(*, client=None) -> pd.DataFrame:
    """Catálogo dos arquivos publicados na página de Dados Abertos do SIOP.

    Colunas: ``categoria`` (rdf, acompanhamento, cadastro_acoes, creditos, regionalizacao),
    ``subtipo`` (acoes/localizadores/planos_orcamentarios), ``tipo`` (dados/dicionario),
    ``exercicio``, ``titulo``, ``formato``, ``url``.
    """
    own = client is None
    client = client or make_client(timeout=60)
    try:
        resp = request_with_retry(client, "GET", CATALOGO_URL)
        return parse_catalogo(resp.text)
    finally:
        if own:
            client.close()


# ---------------------------------------------------------------- cache & download


def cache_dir() -> Path:
    d = Path(user_cache_dir("siopy"))
    d.mkdir(parents=True, exist_ok=True)
    return d


def _cache_path(url: str) -> Path:
    nome = url.rsplit("/", 1)[-1].split(":")[-1]
    h = hashlib.sha1(url.encode()).hexdigest()[:8]
    return cache_dir() / f"{h}_{nome}"


def siop_download(url: str, *, refresh: bool = False, client=None) -> Path:
    """Baixa (com cache em disco) um arquivo dos Dados Abertos e devolve o caminho local."""
    dest = _cache_path(url)
    if dest.exists() and not refresh:
        return dest
    own = client is None
    client = client or make_client(timeout=600)
    try:
        resp = request_with_retry(client, "GET", url)
        dest.write_bytes(resp.content)
        return dest
    finally:
        if own:
            client.close()


def _ler_arquivo(path: Path) -> pd.DataFrame:
    raw = path.read_bytes()
    if zipfile.is_zipfile(io.BytesIO(raw)):
        with zipfile.ZipFile(io.BytesIO(raw)) as z:
            nomes = [n for n in z.namelist() if n.lower().endswith((".csv", ".txt"))]
            if not nomes:
                raise ValueError(f"nenhum CSV dentro de {path.name}: {z.namelist()}")
            return pd.concat(
                [read_siop_csv(decode_bytes(z.read(n))) for n in nomes], ignore_index=True
            )
    if path.suffix.lower() == ".rar":
        raise ValueError(
            f"{path.name} é .rar; extraia manualmente (ex.: `unar`) e use read_siop_csv()."
        )
    return read_siop_csv(decode_bytes(raw))


def _buscar(cat: pd.DataFrame, categoria: str, exercicio: int, subtipo: str | None = None) -> str:
    sel = cat[
        (cat["categoria"] == categoria) & (cat["tipo"] == "dados") & (cat["exercicio"] == exercicio)
    ]
    if subtipo is not None:
        sel = sel[sel["subtipo"] == subtipo]
    if sel.empty:
        disp = sorted(
            cat.loc[(cat["categoria"] == categoria) & (cat["tipo"] == "dados"), "exercicio"]
            .dropna()
            .unique()
        )
        raise ValueError(
            f"{categoria}/{subtipo or ''} {exercicio}: não publicado. Disponíveis: {list(map(int, disp))}"
        )
    return str(sel.iloc[0]["url"])


def _dataset(
    categoria: str, exercicio: int, subtipo: str | None, refresh: bool, client
) -> pd.DataFrame:
    own = client is None
    client = client or make_client(timeout=600)
    try:
        url = _buscar(siop_catalogo(client=client), categoria, exercicio, subtipo)
        df = _ler_arquivo(siop_download(url, refresh=refresh, client=client))
        df.attrs["url"] = url
        return df
    finally:
        if own:
            client.close()


def siop_cadastro_acoes(
    exercicio: int, tipo: str = "acoes", *, refresh: bool = False, client=None
) -> pd.DataFrame:
    """Cadastro de ações (``"acoes"``), localizadores ou planos orçamentários de um exercício."""
    if tipo not in {"acoes", "localizadores", "planos_orcamentarios"}:
        raise ValueError("tipo deve ser 'acoes', 'localizadores' ou 'planos_orcamentarios'")
    return _dataset("cadastro_acoes", exercicio, tipo, refresh, client)


def siop_creditos(exercicio: int, *, refresh: bool = False, client=None) -> pd.DataFrame:
    """Alterações orçamentárias (créditos) de um exercício, com valores numéricos."""
    df = _dataset("creditos", exercicio, None, refresh, client)
    return brl_columns(df, ["val_acrescimo", "val_reducao"])


def siop_acompanhamento(exercicio: int, *, refresh: bool = False, client=None) -> pd.DataFrame:
    """Acompanhamento físico-financeiro das ações (CSV anual dentro de ZIP)."""
    return _dataset("acompanhamento", exercicio, None, refresh, client)


def siop_regionalizacao(exercicio: int, *, refresh: bool = False, client=None) -> pd.DataFrame:
    """Regionalização das ações do orçamento (execução por UF/município/recorte)."""
    df = _dataset("regionalizacao", exercicio, None, refresh, client)
    cols = [c for c in df.columns if c.startswith(("Liquidado", "Realizado"))]
    return brl_columns(df, cols)


__all__ = [
    "CATALOGO_URL",
    "cache_dir",
    "parse_catalogo",
    "siop_acompanhamento",
    "siop_cadastro_acoes",
    "siop_catalogo",
    "siop_creditos",
    "siop_download",
    "siop_regionalizacao",
]
