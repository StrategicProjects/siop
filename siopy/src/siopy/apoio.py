"""Fontes públicas de apoio ao estudo de emendas: Câmara dos Deputados, IBGE e Minha Receita.

Nenhuma exige chave. Espelha as funções homônimas do pacote R ``siopr``.
"""

from __future__ import annotations

import re

import pandas as pd

from ._http import SiopHTTPError, make_client, request_with_retry

CAMARA_BASE = "https://dadosabertos.camara.leg.br/api/v2"
IBGE_BASE = "https://servicodados.ibge.gov.br/api/v1"
CNPJ_BASE = "https://minhareceita.org"

_ACENTOS = str.maketrans(
    "áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ",
    "aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC",
)


def sem_acento(x: str) -> str:
    """Troca caracteres acentuados do português pelos equivalentes ASCII.

    Útil para casar nomes entre fontes — a busca textual do Portal da
    Transparência, por exemplo, não encontra nomes acentuados.
    """
    return x.translate(_ACENTOS)


def camara_deputados(
    uf: str | list[str] | None = None,
    legislatura: int | list[int] | None = None,
) -> pd.DataFrame:
    """Deputados federais (``GET /deputados`` dos Dados Abertos da Câmara), com paginação.

    Sem filtros, devolve os deputados em exercício. Colunas: ``id``, ``nome``,
    ``sigla_partido``, ``sigla_uf``, ``id_legislatura``, ``email``.
    """

    def junta(v):
        if v is None:
            return None
        return ",".join(str(i) for i in (v if isinstance(v, (list, tuple)) else [v]))

    itens: list[dict] = []
    with make_client(headers={"Accept": "application/json"}) as client:
        url: str | None = f"{CAMARA_BASE}/deputados"
        params = {
            k: v
            for k, v in {
                "siglaUf": junta(uf),
                "idLegislatura": junta(legislatura),
                "ordem": "ASC",
                "ordenarPor": "nome",
            }.items()
            if v is not None
        }
        while url:
            corpo = request_with_retry(client, "GET", url, params=params).json()
            params = None  # as páginas seguintes já vêm com a query embutida
            itens.extend(corpo.get("dados", []))
            links = {ln.get("rel"): ln.get("href") for ln in corpo.get("links", [])}
            url = links.get("next") if links.get("next") != url else None
    return pd.DataFrame(
        {
            "id": [str(it.get("id", "")) for it in itens],
            "nome": [it.get("nome") for it in itens],
            "sigla_partido": [it.get("siglaPartido") for it in itens],
            "sigla_uf": [it.get("siglaUf") for it in itens],
            "id_legislatura": [str(it.get("idLegislatura", "")) for it in itens],
            "email": [it.get("email") for it in itens],
        }
    )


def ibge_municipios(uf: str | list[str] | None = None) -> pd.DataFrame:
    """Municípios (API de localidades do IBGE), com a grafia oficial dos nomes.

    ``uf = None`` devolve o Brasil inteiro. Colunas: ``codigo`` (7 dígitos,
    texto), ``nome`` e ``uf``.
    """
    if uf is None:
        caminho = "/localidades/municipios"
    else:
        ufs = uf if isinstance(uf, (list, tuple)) else [uf]
        caminho = f"/localidades/estados/{'|'.join(ufs)}/municipios"
    with make_client(headers={"Accept": "application/json"}) as client:
        itens = request_with_retry(client, "GET", f"{IBGE_BASE}{caminho}").json()

    def sigla(it: dict) -> str | None:
        micro = (it.get("microrregiao") or {}).get("mesorregiao") or {}
        imediata = (it.get("regiao-imediata") or {}).get("regiao-intermediaria") or {}
        return (micro.get("UF") or imediata.get("UF") or {}).get("sigla")

    return pd.DataFrame(
        {
            "codigo": [str(it["id"]) for it in itens],
            "nome": [it["nome"] for it in itens],
            "uf": [sigla(it) for it in itens],
        }
    )


def cnpj_municipio(cnpj: str | list[str]) -> pd.DataFrame:
    """Município e UF da sede de cada CNPJ (https://minhareceita.org).

    Resolve favorecidos de nome genérico ("FUNDO MUNICIPAL DE SAUDE") nos
    documentos de despesa. CNPJs não encontrados vêm com ``NA``.
    """
    cnpjs = cnpj if isinstance(cnpj, (list, tuple, pd.Series)) else [cnpj]
    vistos: dict[str, dict] = {}
    linhas = []
    with make_client(headers={"Accept": "application/json"}) as client:
        for c in cnpjs:
            digitos = re.sub(r"\D", "", str(c))
            if digitos not in vistos:
                try:
                    vistos[digitos] = request_with_retry(
                        client, "GET", f"{CNPJ_BASE}/{digitos}"
                    ).json()
                except SiopHTTPError as exc:
                    if exc.status_code != 404:
                        raise
                    vistos[digitos] = {}
            corpo = vistos[digitos]
            linhas.append({"cnpj": c, "municipio": corpo.get("municipio"), "uf": corpo.get("uf")})
    return pd.DataFrame(linhas)
