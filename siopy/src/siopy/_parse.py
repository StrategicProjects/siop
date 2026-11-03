"""Utilitários de parsing: números em formato brasileiro, datas, encoding."""

from __future__ import annotations

import io
from collections.abc import Iterable

import pandas as pd


def parse_brl(x: object) -> float | None:
    """Converte "1.234,56" (ou "1234.56", int, float) em float. Vazio/None → None."""
    if x is None:
        return None
    if isinstance(x, (int, float)):
        return float(x)
    s = str(x).strip()
    if s == "" or s.lower() in {"nan", "none", "null", "-"}:
        return None
    s = s.replace("R$", "").replace(" ", "")
    if "," in s:
        s = s.replace(".", "").replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return None


def brl_columns(df: pd.DataFrame, cols: Iterable[str]) -> pd.DataFrame:
    for c in cols:
        if c in df.columns:
            df[c] = df[c].map(parse_brl).astype("float64")
    return df


def decode_bytes(raw: bytes) -> str:
    """UTF-8 (com ou sem BOM) com fallback para latin-1 — os CSVs do SIOP variam."""
    for enc in ("utf-8-sig", "utf-8"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("latin-1")


def read_siop_csv(text: str) -> pd.DataFrame:
    """CSV do SIOP: separador ';', decimal ',', tudo como texto (códigos têm zeros à esquerda)."""
    return pd.read_csv(io.StringIO(text), sep=";", dtype=str, keep_default_na=False)
