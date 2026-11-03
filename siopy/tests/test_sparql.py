import httpx
import pandas as pd
import pytest
import respx

from siopy import siop_emendas, siop_orcamento, siop_orgaos, siop_sparql, siop_ultima_atualizacao
from siopy.orcamento import montar_query
from siopy.sparql import SPARQL_ENDPOINT


def test_montar_query_filtros():
    q = montar_query(2025, orgao=["26000", "22000"], rp="6")
    assert "GRAPH <http://orcamento.dados.gov.br/2025/>" in q
    assert 'FILTER(?cod_orgao IN ("26000", "22000"))' in q
    assert 'FILTER(?cod_rp IN ("6"))' in q
    assert "ORDER BY" not in q  # Virtuoso limita ORDER BY+OFFSET a 10k linhas


def test_montar_query_filtro_invalido():
    with pytest.raises(ValueError, match="filtro desconhecido"):
        montar_query(2025, orgaoX="1")


@respx.mock
def test_siop_sparql_csv(fixture_text):
    respx.get(SPARQL_ENDPOINT).mock(
        return_value=httpx.Response(200, text=fixture_text("sparql_orgaos.csv"))
    )
    df = siop_sparql("SELECT ...")
    assert list(df.columns) == ["cod_orgao", "desc_orgao"]
    assert df["cod_orgao"].tolist() == ["26000", "22000"]  # zeros/strings preservados


@respx.mock
def test_siop_sparql_json():
    payload = {
        "head": {"vars": ["a", "b"]},
        "results": {"bindings": [{"a": {"type": "literal", "value": "1"}}]},
    }
    respx.get(SPARQL_ENDPOINT).mock(return_value=httpx.Response(200, json=payload))
    df = siop_sparql("SELECT ...", format="json")
    assert df.shape == (1, 2) and df.loc[0, "b"] is None


@respx.mock
def test_siop_emendas(fixture_text):
    route = respx.get(SPARQL_ENDPOINT).mock(
        return_value=httpx.Response(200, text=fixture_text("sparql_emendas_2025.csv"))
    )
    df = siop_emendas(2025, tipo=["individual", "bancada"])
    assert route.called
    q = route.calls[0].request.url.params["query"]
    assert 'FILTER(?cod_rp IN ("6", "7"))' in q
    assert len(df) == 4
    assert df["tipo_emenda"].tolist() == ["individual", "individual", "individual", "bancada"]
    assert df["loa"].dtype == "float64" and df["loa"].iloc[2] == 6000001
    assert str(df["exercicio"].dtype) == "Int64"
    assert pd.api.types.is_datetime64_any_dtype(df["data_atualizacao"])


def test_siop_emendas_tipo_invalido():
    with pytest.raises(ValueError, match="tipo inválido"):
        siop_emendas(2025, tipo="xyz")


@respx.mock
def test_siop_orcamento_particiona_por_orgao(fixture_text):
    route = respx.get(SPARQL_ENDPOINT)
    route.side_effect = [
        httpx.Response(200, text=fixture_text("sparql_orgaos.csv")),
        httpx.Response(200, text=fixture_text("sparql_emendas_2025.csv")),
        httpx.Response(200, text=fixture_text("sparql_emendas_2025.csv")),
    ]
    df = siop_orcamento(2025)
    assert route.call_count == 3  # 1 (órgãos) + 2 (um por órgão)
    assert len(df) == 8
    assert 'IN ("22000")' in route.calls[1].request.url.params["query"]


@respx.mock
def test_siop_orcamento_sem_particao_quando_filtrado(fixture_text):
    route = respx.get(SPARQL_ENDPOINT).mock(
        return_value=httpx.Response(200, text=fixture_text("sparql_emendas_2025.csv"))
    )
    siop_orcamento(2025, orgao="26000")
    assert route.call_count == 1


@respx.mock
def test_siop_orgaos_e_ultima_atualizacao(fixture_text):
    route = respx.get(SPARQL_ENDPOINT)
    route.side_effect = [
        httpx.Response(200, text=fixture_text("sparql_orgaos.csv")),
        httpx.Response(200, text=fixture_text("sparql_exercicios.csv")),
    ]
    org = siop_orgaos(2025)
    assert org["cod_orgao"].tolist() == ["22000", "26000"]
    upd = siop_ultima_atualizacao(2025)
    assert len(upd) == 1 and int(upd.loc[0, "exercicio"]) == 2025
    assert upd.loc[0, "data_atualizacao"].year == 2026


@respx.mock
def test_retry_em_503(fixture_text):
    route = respx.get(SPARQL_ENDPOINT)
    route.side_effect = [
        httpx.Response(503),
        httpx.Response(200, text=fixture_text("sparql_orgaos.csv")),
    ]
    import siopy._http as h

    h.time.sleep = lambda *_: None  # sem esperar no teste
    df = siop_sparql("SELECT ...")
    assert route.call_count == 2 and len(df) == 2
