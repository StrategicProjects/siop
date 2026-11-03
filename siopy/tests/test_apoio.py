import httpx
import respx

from siopy import camara_deputados, cnpj_municipio, ibge_municipios, sem_acento
from siopy.apoio import CAMARA_BASE, CNPJ_BASE, IBGE_BASE


def test_sem_acento():
    assert sem_acento("Túlio Gadêlha") == "Tulio Gadelha"
    assert sem_acento("MENDONÇA") == "MENDONCA"


@respx.mock
def test_camara_deputados_filtra_e_pagina():
    p1 = {
        "dados": [
            {
                "id": 204454,
                "nome": "André Ferreira",
                "siglaPartido": "PL",
                "siglaUf": "PE",
                "idLegislatura": 57,
                "email": "dep@camara.leg.br",
            }
        ],
        "links": [{"rel": "next", "href": f"{CAMARA_BASE}/deputados?pagina=2"}],
    }
    p2 = {
        "dados": [
            {
                "id": 74573,
                "nome": "Pedro Campos",
                "siglaPartido": "PSB",
                "siglaUf": "PE",
                "idLegislatura": 57,
                "email": None,
            }
        ],
        "links": [],
    }
    route = respx.get(f"{CAMARA_BASE}/deputados").mock(
        side_effect=[httpx.Response(200, json=p1), httpx.Response(200, json=p2)]
    )
    df = camara_deputados(uf="PE", legislatura=57)
    assert route.call_count == 2
    assert "siglaUf=PE" in str(route.calls[0].request.url)
    assert "idLegislatura=57" in str(route.calls[0].request.url)
    assert list(df["nome"]) == ["André Ferreira", "Pedro Campos"]
    assert list(df["sigla_partido"]) == ["PL", "PSB"]


@respx.mock
def test_ibge_municipios():
    corpo = [
        {"id": 2611606, "nome": "Recife", "microrregiao": {"mesorregiao": {"UF": {"sigla": "PE"}}}},
        {
            "id": 2613909,
            "nome": "Surubim",
            "microrregiao": None,
            "regiao-imediata": {"regiao-intermediaria": {"UF": {"sigla": "PE"}}},
        },
    ]
    respx.get(f"{IBGE_BASE}/localidades/estados/PE/municipios").mock(
        return_value=httpx.Response(200, json=corpo)
    )
    df = ibge_municipios("PE")
    assert list(df["codigo"]) == ["2611606", "2613909"]
    assert list(df["uf"]) == ["PE", "PE"]


@respx.mock
def test_cnpj_municipio_limpa_pontuacao_e_404():
    respx.get(f"{CNPJ_BASE}/10298546000124").mock(
        return_value=httpx.Response(200, json={"municipio": "SURUBIM", "uf": "PE"})
    )
    respx.get(f"{CNPJ_BASE}/00000000000000").mock(return_value=httpx.Response(404))
    df = cnpj_municipio(["10.298.546/0001-24", "00.000.000/0000-00"])
    assert df["municipio"][0] == "SURUBIM"
    assert df["municipio"].isna()[1]
    assert df["cnpj"][0] == "10.298.546/0001-24"
