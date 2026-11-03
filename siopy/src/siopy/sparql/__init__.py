"""Cliente SPARQL para o endpoint de Dados Abertos do Orçamento Federal (SIOP/SOF)."""

from __future__ import annotations

import io
import json
from importlib import resources
from typing import Any

import pandas as pd

from .._http import make_client, request_with_retry

SPARQL_ENDPOINT = "https://www1.siop.planejamento.gov.br/sparql/"
GRAPH_BASE = "http://orcamento.dados.gov.br/"
PREFIXES = (
    "PREFIX loa: <http://vocab.e.gov.br/2013/09/loa#>\n"
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n"
    "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n"
)


def sparql_template(name: str = "orcamento") -> str:
    return resources.files(__package__).joinpath(f"{name}.rq").read_text(encoding="utf-8")


def sparql(
    query: str,
    *,
    format: str = "csv",
    endpoint: str = SPARQL_ENDPOINT,
    timeout: float = 300.0,
    client: Any | None = None,
) -> pd.DataFrame:
    """Executa uma consulta SPARQL e devolve um DataFrame.

    ``format="csv"`` (padrão) pede ``text/csv`` ao Virtuoso — bem mais leve que JSON.
    ``format="json"`` usa ``application/sparql-results+json`` e preserva os datatypes.

    Atenção: o Virtuoso limita ``ORDER BY`` + ``OFFSET`` a 10 000 linhas; prefira consultas
    sem ``ORDER BY`` e particione por órgão/UO quando o resultado for muito grande.
    """
    own = client is None
    client = client or make_client(timeout=timeout)
    try:
        if format == "csv":
            resp = request_with_retry(
                client, "GET", endpoint, params={"query": query, "format": "text/csv"}
            )
            text = resp.content.decode("utf-8")
            return pd.read_csv(io.StringIO(text), dtype=str, keep_default_na=False)
        resp = request_with_retry(
            client,
            "GET",
            endpoint,
            params={"query": query, "format": "application/sparql-results+json"},
            headers={"Accept": "application/sparql-results+json"},
        )
        return _bindings_to_df(json.loads(resp.content))
    finally:
        if own:
            client.close()


def _bindings_to_df(payload: dict) -> pd.DataFrame:
    vars_ = payload["head"]["vars"]
    rows = [
        {v: (b[v]["value"] if v in b else None) for v in vars_}
        for b in payload["results"]["bindings"]
    ]
    return pd.DataFrame(rows, columns=vars_)
