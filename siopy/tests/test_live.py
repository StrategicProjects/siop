"""Testes ao vivo (opt-in): SIOPY_LIVE=true pytest tests/test_live.py"""
import os

import pytest

import siopy

live = pytest.mark.skipif(os.environ.get("SIOPY_LIVE", "").lower() != "true", reason="SIOPY_LIVE != true")


@live
def test_ultima_atualizacao_live():
    df = siopy.siop_ultima_atualizacao()
    assert 2025 in df["exercicio"].tolist()


@live
def test_emendas_live_recorte():
    df = siopy.siop_emendas(2025, tipo="bancada", orgao="26000")
    assert len(df) > 0 and (df["cod_rp"] == "7").all()


@live
def test_catalogo_live():
    cat = siopy.siop_catalogo()
    assert {"cadastro_acoes", "creditos"} <= set(cat["categoria"])


@live
@pytest.mark.skipif(not siopy.pt_has_key(), reason="sem PORTAL_TRANSPARENCIA_API_KEY")
def test_pt_emendas_live():
    df = siopy.pt_emendas(2025, max_paginas=1)
    assert len(df) > 0 and "codigo_emenda" in df.columns
