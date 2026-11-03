"""API REST do Portal da Transparência (CGU): emendas parlamentares e documentos de despesa.

Chave gratuita: https://portaldatransparencia.gov.br/api-de-dados/cadastrar-email
Informe-a na variável de ambiente ``PORTAL_TRANSPARENCIA_API_KEY`` (ou via :func:`pt_set_key`).
"""

from __future__ import annotations

import os
import threading
import time
from collections import deque
from typing import Any

import pandas as pd

from . import _msg
from ._http import make_client, request_with_retry
from ._parse import brl_columns

PT_BASE = "https://api.portaldatransparencia.gov.br"
PT_KEY_ENV = "PORTAL_TRANSPARENCIA_API_KEY"
PT_HEADER = "chave-api-dados"

_VALOR_COLS = [
    "valorEmpenhado",
    "valorLiquidado",
    "valorPago",
    "valorRestoInscrito",
    "valorRestoCancelado",
    "valorRestoPago",
    "valor",
    "valorFinal",
]

# camelCase da API -> snake_case
_RENOMEAR = {
    "codigoEmenda": "codigo_emenda",
    "tipoEmenda": "tipo_emenda",
    "nomeAutor": "nome_autor",
    "numeroEmenda": "numero_emenda",
    "localidadeDoGasto": "localidade_gasto",
    "valorEmpenhado": "valor_empenhado",
    "valorLiquidado": "valor_liquidado",
    "valorPago": "valor_pago",
    "valorRestoInscrito": "valor_resto_inscrito",
    "valorRestoCancelado": "valor_resto_cancelado",
    "valorRestoPago": "valor_resto_pago",
    "codigoDocumento": "codigo_documento",
    "codigoDocumentoResumido": "codigo_documento_resumido",
    "especieTipo": "especie_tipo",
    "documentoResumido": "documento_resumido",
    "subTitulo": "subtitulo",
    "localizadorGasto": "localizador_gasto",
    "codigoFavorecido": "codigo_favorecido",
    "nomeFavorecido": "nome_favorecido",
    "ufFavorecido": "uf_favorecido",
    "codigoUg": "codigo_ug",
    "codigoUo": "codigo_uo",
    "codigoOrgao": "codigo_orgao",
    "codigoOrgaoSuperior": "codigo_orgao_superior",
    "orgaoSuperior": "orgao_superior",
    "numeroProcesso": "numero_processo",
    "planoOrcamentario": "plano_orcamentario",
    "favorecidoIntermediario": "favorecido_intermediario",
    "favorecidoListaFaturas": "favorecido_lista_faturas",
    "elementoDespesa": "elemento_despesa",
    "orgaoVinculado": "orgao_vinculado",
    "unidadeGestora": "unidade_gestora",
    "codigoPagamento": "codigo_pagamento",
    "codigoListaCredor": "codigo_lista_credor",
    "valorFinal": "valor_final",
    "tipoOB": "tipo_ob",
    "tipoDocumento": "tipo_documento",
    "dataCarga": "data_carga",
    "codigoFavorecidoFinal": "codigo_favorecido_final",
    "nomeFavorecidoFinal": "nome_favorecido_final",
    "tipoFavorecidoFinal": "tipo_favorecido_final",
    "ufFavorecidoFinal": "uf_favorecido_final",
    "municipioFavorecidoFinal": "municipio_favorecido_final",
    "codigoFavorecidoDespesa": "codigo_favorecido_despesa",
    "nomeFavorecidoDespesa": "nome_favorecido_despesa",
    "tipoFavorecidoDespesa": "tipo_favorecido_despesa",
    "codigoOrgaoVinculado": "codigo_orgao_vinculado",
    "codigoUnidadeGestora": "codigo_unidade_gestora",
    "skFatDW": "sk_fat_dw",
    "skPessoaFinal": "sk_pessoa_final",
    "skPessoaDespesa": "sk_pessoa_despesa",
}

_state: dict[str, Any] = {"key": None}


def pt_set_key(key: str | None) -> None:
    """Define a chave da API em memória (prioridade sobre a variável de ambiente)."""
    _state["key"] = key


def pt_get_key() -> str:
    key = _state["key"] or os.environ.get(PT_KEY_ENV)
    if not key:
        raise RuntimeError(
            f"Chave da API do Portal da Transparência ausente. Defina {PT_KEY_ENV} "
            "ou chame pt_set_key(). Cadastro: https://portaldatransparencia.gov.br/api-de-dados/cadastrar-email"
        )
    return key


def pt_has_key() -> bool:
    return bool(_state["key"] or os.environ.get(PT_KEY_ENV))


class _RateLimiter:
    """Janela deslizante: no máximo ``n`` chamadas por ``periodo`` segundos."""

    def __init__(self, n: int = 90, periodo: float = 60.0):
        self.n, self.periodo = n, periodo
        self._ts: deque[float] = deque()
        self._lock = threading.Lock()

    def wait(self) -> None:
        with self._lock:
            now = time.monotonic()
            while self._ts and now - self._ts[0] > self.periodo:
                self._ts.popleft()
            if len(self._ts) >= self.n:
                time.sleep(self.periodo - (now - self._ts[0]) + 0.05)
            self._ts.append(time.monotonic())


_limiter = _RateLimiter()


class PortalTransparencia:
    """Cliente de baixo nível. Use as funções ``pt_*`` para o caso comum."""

    def __init__(
        self, key: str | None = None, *, base: str = PT_BASE, timeout: float = 60.0, client=None
    ):
        self.key = key or pt_get_key()
        self.base = base.rstrip("/")
        self._own = client is None
        self.client = client or make_client(
            timeout=timeout, headers={PT_HEADER: self.key, "Accept": "application/json"}
        )
        if client is not None:
            client.headers[PT_HEADER] = self.key

    def close(self) -> None:
        if self._own:
            self.client.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    def get(self, path: str, **params: Any) -> Any:
        params = {k: v for k, v in params.items() if v is not None}
        _limiter.wait()
        resp = request_with_retry(self.client, "GET", f"{self.base}{path}", params=params)
        return resp.json()

    def get_paginado(
        self, path: str, *, max_paginas: int | None = None, **params: Any
    ) -> list[dict]:
        itens: list[dict] = []
        pagina = 1
        while True:
            lote = self.get(path, pagina=pagina, **params)
            if not lote:
                break
            itens.extend(lote)
            pagina += 1
            if max_paginas is not None and pagina > max_paginas:
                break
        return itens


def _to_df(itens: list[dict]) -> pd.DataFrame:
    df = pd.DataFrame(itens)
    df = brl_columns(df, _VALOR_COLS)
    return df.rename(columns=_RENOMEAR)


def _pt(client) -> tuple[PortalTransparencia, bool]:
    if isinstance(client, PortalTransparencia):
        return client, False
    return PortalTransparencia(client=client), True


def _como_lista(x) -> list:
    if isinstance(x, str) or not hasattr(x, "__iter__"):
        return [x]
    return list(x)


def _varios(x, um, rotulo: str) -> pd.DataFrame:
    """Aplica ``um()`` a cada elemento e empilha, com progresso nos loops longos."""
    xs = _como_lista(x)
    if not xs:
        return pd.DataFrame()
    if len(xs) == 1:
        return um(xs[0])
    dfs = []
    for i, xi in enumerate(xs, 1):
        _msg.progress(i, len(xs), rotulo)
        dfs.append(um(xi))
    dfs = [d for d in dfs if not d.empty]
    return pd.concat(dfs, ignore_index=True) if dfs else pd.DataFrame()


def pt_emendas(
    ano: int | None = None,
    *,
    autor: str | None = None,
    tipo: str | None = None,
    codigo: str | None = None,
    numero: str | None = None,
    funcao: str | None = None,
    subfuncao: str | None = None,
    max_paginas: int | None = None,
    client=None,
) -> pd.DataFrame:
    """Emendas parlamentares (``/api-de-dados/emendas``), todas as páginas.

    ``autor`` é um ou mais nomes de parlamentar (busca textual); acentos são
    removidos e o nome vai em maiúsculas automaticamente — a busca da API não
    encontra nomes acentuados ("Túlio Gadêlha" vira "TULIO GADELHA"). Com
    vários autores, as buscas são feitas uma a uma e emendas repetidas (a
    busca é parcial) são deduplicadas pelo código. ``tipo`` como na API (ex.:
    "Emenda Individual - Transferências com Finalidade Definida"). Valores em
    R$ numéricos.
    """
    if autor is not None:
        from .apoio import sem_acento

        autores = [sem_acento(a).upper() for a in _como_lista(autor)]
    else:
        autores = [None]
    pt, own = _pt(client)
    try:

        def um(a):
            itens = pt.get_paginado(
                "/api-de-dados/emendas",
                max_paginas=max_paginas,
                ano=ano,
                nomeAutor=a,
                tipoEmenda=tipo,
                codigoEmenda=codigo,
                numeroEmenda=numero,
                codigoFuncao=funcao,
                codigoSubfuncao=subfuncao,
            )
            return _to_df(itens)

        if len(autores) == 1:
            df = um(autores[0])
        else:
            df = _varios(autores, um, "Emendas por autor")
            if "codigo_emenda" in df.columns:
                # a busca da API é parcial: "LULA DA FONTE" também responde a "DA FONTE"
                df = df.drop_duplicates(subset="codigo_emenda", ignore_index=True)
    finally:
        if own:
            pt.close()
    if "ano" in df.columns:
        df["ano"] = pd.to_numeric(df["ano"], errors="coerce").astype("Int64")
    return df


def pt_emenda_documentos(
    codigo_emenda: str | list[str], *, max_paginas: int | None = None, client=None
) -> pd.DataFrame:
    """Documentos (empenho/liquidação/pagamento) ligados a emendas (``/emendas/documentos/{codigo}``).

    Aceita um ou mais códigos e devolve um único DataFrame, com a coluna
    ``codigo_emenda`` na frente.
    """
    pt, own = _pt(client)
    try:

        def um(cod):
            itens = pt.get_paginado(
                f"/api-de-dados/emendas/documentos/{cod}", max_paginas=max_paginas
            )
            df = _to_df(itens)
            if not df.empty:
                df.insert(0, "codigo_emenda", str(cod))
            return df

        return _varios(codigo_emenda, um, "Documentos por emenda")
    finally:
        if own:
            pt.close()


def pt_despesa_documento(codigo_documento: str | list[str], *, client=None) -> pd.DataFrame:
    """Detalhe de documentos de despesa (``/despesas/documentos/{codigo}``): favorecido, UG, UO, classificação.

    Aceita um ou mais códigos e devolve um único DataFrame (uma linha por documento).
    """
    pt, own = _pt(client)
    try:

        def um(cod):
            item = pt.get(f"/api-de-dados/despesas/documentos/{cod}")
            return _to_df([item] if isinstance(item, dict) else list(item))

        return _varios(codigo_documento, um, "Detalhe dos documentos")
    finally:
        if own:
            pt.close()


def pt_documentos_relacionados(
    codigo_documento: str | list[str], fase: int, *, client=None
) -> pd.DataFrame:
    """Documentos relacionados (``fase``: 1 empenho, 2 liquidação, 3 pagamento); um ou mais códigos."""
    pt, own = _pt(client)
    try:

        def um(cod):
            itens = pt.get(
                "/api-de-dados/despesas/documentos-relacionados",
                codigoDocumento=cod,
                fase=fase,
            )
            df = _to_df(list(itens))
            if not df.empty:
                df.insert(0, "codigo_documento", str(cod))
            return df

        return _varios(codigo_documento, um, "Documentos relacionados")
    finally:
        if own:
            pt.close()


def pt_favorecidos_finais(
    codigo_documento: str | list[str], *, max_paginas: int | None = None, client=None
) -> pd.DataFrame:
    """Favorecidos finais (``/despesas/favorecidos-finais-por-documento``); um ou mais códigos."""
    pt, own = _pt(client)
    try:

        def um(cod):
            itens = pt.get_paginado(
                "/api-de-dados/despesas/favorecidos-finais-por-documento",
                max_paginas=max_paginas,
                codigoDocumento=cod,
            )
            df = _to_df(itens)
            if not df.empty:
                df.insert(0, "codigo_documento", str(cod))
            return df

        return _varios(codigo_documento, um, "Favorecidos finais")
    finally:
        if own:
            pt.close()


def emendas_execucao(
    ano: int,
    *,
    autor: str | None = None,
    tipo: str | None = None,
    detalhar: bool = True,
    max_emendas: int | None = None,
    client=None,
) -> pd.DataFrame:
    """Emendas + documentos (+ detalhe de cada documento): uma linha por documento.

    Combina :func:`pt_emendas`, :func:`pt_emenda_documentos` e, se ``detalhar=True``,
    :func:`pt_despesa_documento`. Custo: 1 req por página de emendas + ≥1 por emenda
    (+1 por documento quando ``detalhar``). O rate limit interno (90/min) é respeitado.
    """
    pt, own = _pt(client)
    try:
        emendas = pt_emendas(ano, autor=autor, tipo=tipo, client=pt)
        if emendas.empty:
            return emendas
        if max_emendas is not None:
            emendas = emendas.head(max_emendas)
        docs_df = pt_emenda_documentos(list(emendas["codigo_emenda"]), client=pt)
        if docs_df.empty:
            docs_df = pd.DataFrame(columns=["codigo_emenda"])
        out = emendas.merge(docs_df, on="codigo_emenda", how="left", suffixes=("", "_doc"))
        if detalhar and "codigo_documento" in out.columns:
            cods = list(out["codigo_documento"].dropna().unique())
            det_df = pt_despesa_documento(cods, client=pt)
            if not det_df.empty and "documento" in det_df.columns:
                det_df = det_df.rename(columns={"documento": "codigo_documento"}).drop_duplicates(
                    subset="codigo_documento"
                )
                out = out.merge(det_df, on="codigo_documento", how="left", suffixes=("", "_det"))
        return out
    finally:
        if own:
            pt.close()


__all__ = [
    "PT_BASE",
    "PT_KEY_ENV",
    "PortalTransparencia",
    "emendas_execucao",
    "pt_despesa_documento",
    "pt_documentos_relacionados",
    "pt_emenda_documentos",
    "pt_emendas",
    "pt_favorecidos_finais",
    "pt_get_key",
    "pt_has_key",
    "pt_set_key",
]
