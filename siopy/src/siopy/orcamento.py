"""Consultas de alto nível ao RDF do Orçamento Federal: emendas (RP 6/7/8/9) e orçamento."""

from __future__ import annotations

from collections.abc import Sequence

import pandas as pd

from ._http import make_client
from .sparql import GRAPH_BASE, PREFIXES, sparql, sparql_template

# Resultado Primário usado para marcar emendas parlamentares no orçamento federal.
# Fonte: siopdoc acesso_publico:emendas_parlamentares_dados_abertos (RP6 desde 2014, RP7 desde 2017);
# RP8 (comissão) e RP9 (relator) observados nos grafos a partir de 2020.
TIPO_EMENDA_RP: dict[str, str] = {
    "individual": "6",
    "bancada": "7",
    "comissao": "8",
    "relator": "9",
}

# nome do filtro -> variável ?cod_* no template orcamento.rq
_FILTROS = {
    "esfera": "cod_esfera",
    "orgao": "cod_orgao",
    "uo": "cod_uo",
    "funcao": "cod_funcao",
    "subfuncao": "cod_subfuncao",
    "programa": "cod_programa",
    "acao": "cod_acao",
    "localizador": "cod_localizador",
    "po": "cod_po",
    "fonte": "cod_fonte",
    "categoria": "cod_categoria",
    "gnd": "cod_gnd",
    "modalidade": "cod_modalidade",
    "elemento": "cod_elemento",
    "iduso": "cod_iduso",
    "rp": "cod_rp",
}

VALOR_COLS = ["ploa", "autografo", "loa", "lei_mais_credito", "empenhado", "liquidado", "pago"]


def _as_list(x: object) -> list[str]:
    if x is None:
        return []
    if isinstance(x, (str, int)):
        return [str(x)]
    return [str(v) for v in x]  # type: ignore[union-attr]


def _filtro_sparql(**filtros: object) -> str:
    linhas = []
    for nome, valores in filtros.items():
        vals = _as_list(valores)
        if not vals:
            continue
        if nome not in _FILTROS:
            raise ValueError(f"filtro desconhecido: {nome!r}; use um de {sorted(_FILTROS)}")
        lit = ", ".join('"' + v.replace('"', '\\"') + '"' for v in vals)
        linhas.append(f"    FILTER(?{_FILTROS[nome]} IN ({lit}))")
    return "\n".join(linhas)


def montar_query(exercicio: int, **filtros: object) -> str:
    """Monta a consulta SPARQL do template ``orcamento.rq`` para um exercício e filtros."""
    tpl = sparql_template("orcamento")
    return tpl.replace("{{exercicio}}", str(int(exercicio))).replace(
        "{{filtros}}", _filtro_sparql(**filtros)
    )


def _tidy(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return df
    df = df.copy()
    df["exercicio"] = pd.to_numeric(df["exercicio"], errors="coerce").astype("Int64")
    for c in VALOR_COLS:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce").astype("float64")
    if "data_atualizacao" in df.columns:
        df["data_atualizacao"] = pd.to_datetime(df["data_atualizacao"], errors="coerce", utc=True)
    return df


def siop_orcamento(
    exercicio: int,
    *,
    particionar: bool | None = None,
    client=None,
    **filtros: object,
) -> pd.DataFrame:
    """Linhas de despesa (``loa:ItemDespesa``) de um exercício, com classificação e valores.

    Filtros aceitos (códigos como texto, valor único ou lista): ``esfera, orgao, uo, funcao,
    subfuncao, programa, acao, localizador, po, fonte, categoria, gnd, modalidade, elemento,
    iduso, rp``. Ex.: ``siop_orcamento(2025, orgao="26000", rp=["6", "7"])``.

    ``particionar``: quando ``True`` (padrão se nenhum filtro for dado) consulta órgão a órgão
    para evitar respostas gigantes/timeouts.
    """
    if particionar is None:
        particionar = not any(_as_list(v) for v in filtros.values())
    own = client is None
    client = client or make_client()
    try:
        if not particionar:
            return _tidy(sparql(montar_query(exercicio, **filtros), client=client))
        partes = []
        for cod in siop_orgaos(exercicio, client=client)["cod_orgao"]:
            f = dict(filtros)
            f["orgao"] = cod
            partes.append(sparql(montar_query(exercicio, **f), client=client))
        return _tidy(pd.concat(partes, ignore_index=True)) if partes else _tidy(pd.DataFrame())
    finally:
        if own:
            client.close()


def siop_emendas(
    exercicio: int,
    tipo: str | Sequence[str] = ("individual", "bancada", "comissao", "relator"),
    *,
    client=None,
    **filtros: object,
) -> pd.DataFrame:
    """Dotações de emendas parlamentares (RP 6/7/8/9) de um exercício.

    ``tipo``: ``"individual"`` (RP6), ``"bancada"`` (RP7), ``"comissao"`` (RP8), ``"relator"`` (RP9)
    ou uma lista. Demais filtros como em :func:`siop_orcamento`.

    O RDF do SIOP não identifica autor nem número de emenda — para isso use
    :func:`siopy.pt_emendas` (Portal da Transparência).
    """
    tipos = [tipo] if isinstance(tipo, str) else list(tipo)
    try:
        rps = [TIPO_EMENDA_RP[t] for t in tipos]
    except KeyError as e:
        raise ValueError(f"tipo inválido {e}; use {sorted(TIPO_EMENDA_RP)}") from None
    df = siop_orcamento(exercicio, particionar=False, client=client, rp=rps, **filtros)
    if df.empty:
        return df
    inv = {v: k for k, v in TIPO_EMENDA_RP.items()}
    df.insert(df.columns.get_loc("cod_rp"), "tipo_emenda", df["cod_rp"].map(inv))
    return df


def siop_orgaos(exercicio: int, *, client=None) -> pd.DataFrame:
    """Órgãos orçamentários presentes no grafo de um exercício (código e nome)."""
    q = PREFIXES + (
        "SELECT DISTINCT ?cod_orgao ?desc_orgao WHERE { "
        f"GRAPH <{GRAPH_BASE}{int(exercicio)}/> {{ "
        "?i a loa:ItemDespesa ; loa:temUnidadeOrcamentaria ?uo . ?uo loa:temOrgao ?org . "
        "?org loa:codigo ?cod_orgao ; rdfs:label ?desc_orgao } }"
    )
    df = sparql(q, client=client)
    return df.sort_values("cod_orgao", ignore_index=True)


def siop_exercicios(*, client=None) -> pd.DataFrame:
    """Exercícios disponíveis no endpoint e a data da última carga de cada grafo."""
    q = PREFIXES + (
        "SELECT ?exercicio ?data_atualizacao WHERE { GRAPH ?g { "
        "?e a loa:Exercicio ; loa:identificador ?exercicio ; loa:dataUltimaAtualizacao ?data_atualizacao } }"
    )
    df = sparql(q, client=client)
    if df.empty:
        return df
    df["exercicio"] = pd.to_numeric(df["exercicio"]).astype("Int64")
    df["data_atualizacao"] = pd.to_datetime(df["data_atualizacao"], utc=True)
    return df.sort_values("exercicio", ascending=False, ignore_index=True)


def siop_ultima_atualizacao(exercicio: int | None = None, *, client=None) -> pd.DataFrame:
    """Data da última atualização do grafo RDF (todas ou de um exercício)."""
    df = siop_exercicios(client=client)
    if exercicio is not None:
        df = df[df["exercicio"] == int(exercicio)].reset_index(drop=True)
    return df


__all__ = [
    "TIPO_EMENDA_RP",
    "montar_query",
    "siop_emendas",
    "siop_exercicios",
    "siop_orcamento",
    "siop_orgaos",
    "siop_ultima_atualizacao",
]
