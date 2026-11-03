import httpx
import pytest
import respx

from siopy import (
    emendas_execucao,
    pt_despesa_documento,
    pt_emenda_documentos,
    pt_emendas,
    pt_has_key,
    pt_set_key,
)
from siopy._parse import parse_brl
from siopy.transparencia import PT_BASE, PT_HEADER, PT_KEY_ENV


@pytest.fixture(autouse=True)
def chave(monkeypatch):
    monkeypatch.setenv(PT_KEY_ENV, "chave-teste")
    pt_set_key(None)
    import siopy.transparencia as t

    t._limiter._ts.clear()
    yield


def test_parse_brl():
    assert parse_brl("1.500.000,00") == 1_500_000.0
    assert parse_brl("750.000,50") == 750000.5
    assert parse_brl("1234.5") == 1234.5
    assert parse_brl("") is None and parse_brl(None) is None


def test_chave_ausente(monkeypatch):
    monkeypatch.delenv(PT_KEY_ENV)
    assert not pt_has_key()
    with pytest.raises(RuntimeError, match=PT_KEY_ENV):
        pt_emendas(2025)


@respx.mock
def test_pt_emendas_pagina_e_cabecalho(fixture_text):
    route = respx.get(f"{PT_BASE}/api-de-dados/emendas")
    route.side_effect = [
        httpx.Response(200, text=fixture_text("pt_emendas_p1.json")),
        httpx.Response(200, text=fixture_text("pt_vazio.json")),
    ]
    df = pt_emendas(2025, autor="PARLAMENTAR EXEMPLO")
    assert route.call_count == 2
    req = route.calls[0].request
    assert req.headers[PT_HEADER] == "chave-teste"
    assert req.url.params["pagina"] == "1" and req.url.params["ano"] == "2025"
    assert req.url.params["nomeAutor"] == "PARLAMENTAR EXEMPLO"
    assert "tipoEmenda" not in req.url.params  # None é omitido
    assert route.calls[1].request.url.params["pagina"] == "2"
    assert list(df.columns)[:3] == ["codigo_emenda", "ano", "tipo_emenda"]
    assert df["valor_empenhado"].tolist() == [1_500_000.0, 300_000.0]
    assert df["valor_liquidado"].iloc[0] == 750000.5


@respx.mock
def test_pt_emendas_max_paginas(fixture_text):
    route = respx.get(f"{PT_BASE}/api-de-dados/emendas").mock(
        return_value=httpx.Response(200, text=fixture_text("pt_emendas_p1.json"))
    )
    df = pt_emendas(2025, max_paginas=2)
    assert route.call_count == 2 and len(df) == 4


@respx.mock
def test_pt_emenda_documentos(fixture_text):
    respx.get(f"{PT_BASE}/api-de-dados/emendas/documentos/202512340001").side_effect = [
        httpx.Response(200, text=fixture_text("pt_emenda_documentos.json")),
        httpx.Response(200, text="[]"),
    ]
    df = pt_emenda_documentos("202512340001")
    assert df["codigo_emenda"].unique().tolist() == ["202512340001"]
    assert df["codigo_documento"].tolist()[0] == "257001257012025NE000123"


@respx.mock
def test_pt_despesa_documento(fixture_text):
    respx.get(f"{PT_BASE}/api-de-dados/despesas/documentos/257001257012025NE000123").mock(
        return_value=httpx.Response(200, text=fixture_text("pt_despesa_documento.json"))
    )
    df = pt_despesa_documento("257001257012025NE000123")
    assert len(df) == 1 and df.loc[0, "valor"] == 1_500_000.0
    assert df.loc[0, "uf_favorecido"] == "PE"


@respx.mock
def test_emendas_execucao(fixture_text):
    respx.get(f"{PT_BASE}/api-de-dados/emendas").side_effect = [
        httpx.Response(200, text=fixture_text("pt_emendas_p1.json")),
        httpx.Response(200, text="[]"),
    ]
    respx.get(
        url__regex=rf"{PT_BASE}/api-de-dados/emendas/documentos/202512340001.*"
    ).side_effect = [
        httpx.Response(200, text=fixture_text("pt_emenda_documentos.json")),
        httpx.Response(200, text="[]"),
    ]
    respx.get(url__regex=rf"{PT_BASE}/api-de-dados/emendas/documentos/202512340002.*").mock(
        return_value=httpx.Response(200, text="[]")
    )
    respx.get(url__regex=rf"{PT_BASE}/api-de-dados/despesas/documentos/.*").mock(
        return_value=httpx.Response(200, text=fixture_text("pt_despesa_documento.json"))
    )
    df = emendas_execucao(2025, autor="PARLAMENTAR EXEMPLO")
    # emenda 1 -> 2 documentos; emenda 2 -> nenhum (fica com NaN)
    assert len(df) == 3
    assert df["codigo_emenda"].tolist() == ["202512340001", "202512340001", "202512340002"]
    assert "nome_favorecido" in df.columns
    assert df["nome_favorecido"].iloc[0] == "MUNICIPIO EXEMPLO"


@respx.mock
def test_401_vira_erro():
    respx.get(f"{PT_BASE}/api-de-dados/emendas").mock(return_value=httpx.Response(401, text="{}"))
    from siopy._http import SiopHTTPError

    with pytest.raises(SiopHTTPError, match="401"):
        pt_emendas(2025)
