import io
import zipfile

import httpx
import respx

from siopy import siop_cadastro_acoes, siop_catalogo, siop_creditos
from siopy._parse import decode_bytes, read_siop_csv
from siopy.catalogo import CATALOGO_URL, parse_catalogo

HTML = """<html><body><div id="dokuwiki__content">
<h2>1. Arquivos de Dados em RDF da Execução do Orçamento Federal</h2>
<a href="https://www1.siop.planejamento.gov.br/downloads/rdf/loa2025.zip">LOA 2025</a>
<h2>4. Arquivos de Dados em CSV do Cadastro de Ações do Orçamento Federal</h2>
<a href="/siopdoc/lib/exe/fetch.php/dados_abertos:cadastroacao:2025:dados_acao2025.csv">Ações 2025</a>
<a href="/siopdoc/lib/exe/fetch.php/dados_abertos:cadastroacao:2025:dados_localizador2025.csv">Localizadores 2025</a>
<a href="/siopdoc/lib/exe/fetch.php/dados_abertos:cadastroacao:2025:dados_plano_orcamentario2025.csv">Planos Orçamentários 2025</a>
<h2>5. Arquivos de Dados em CSV de Alterações Orçamentárias - Créditos</h2>
<a href="/siopdoc/lib/exe/fetch.php/dados_abertos:alteracoes:alteracoesorcamentarias_2025.csv">Alterações Orçamentárias - créditos 2025</a>
<a href="/siopdoc/lib/exe/fetch.php/acesso_publico:dados_abertos:dicionariodadosatosalteracoesorcamentarias.pdf">Dicionário de Dados</a>
<h3>Arquivos de Dados em CSV da Regionalização das Ações do Orçamento Federal</h3>
<a href="/siopdoc/lib/exe/fetch.php/acesso_publico:dados_abertos:dados_regionalizados_orcamento_2025_publicado_v12_05_2026.csv">Regionalização das Ações do Orçamento Federal - 2025</a>
</div></body></html>"""

ACAO_LATIN1 = (
    "Exercício;Esfera;UO;Ação;Título\r\n2025;10;01101;4061;Processo Legislativo\r\n".encode(
        "latin-1"
    )
)
CRED_UTF8_BOM = "﻿ano;acao;val_acrescimo;val_reducao\r\n2025;20GP;0,00;1630282,00\r\n".encode()


def test_parse_catalogo():
    df = parse_catalogo(HTML)
    assert set(df["categoria"]) == {"rdf", "cadastro_acoes", "creditos", "regionalizacao"}
    ca = df[df["categoria"] == "cadastro_acoes"]
    assert ca["subtipo"].tolist() == ["acoes", "localizadores", "planos_orcamentarios"]
    assert (df["exercicio"] == 2025).all()
    assert df[df["tipo"] == "dicionario"]["formato"].tolist() == ["pdf"]
    assert df["url"].str.startswith("https://www1.siop.planejamento.gov.br").all()


def test_decode_e_csv():
    assert "Ação" in decode_bytes(ACAO_LATIN1)
    df = read_siop_csv(decode_bytes(CRED_UTF8_BOM))
    assert df.columns[0] == "ano"  # BOM removido
    assert df.loc[0, "val_reducao"] == "1630282,00"


@respx.mock
def test_cadastro_acoes_download_e_cache(tmp_path, monkeypatch):
    monkeypatch.setattr("siopy.catalogo.cache_dir", lambda: tmp_path)
    respx.get(CATALOGO_URL).mock(return_value=httpx.Response(200, text=HTML))
    arq = respx.get(url__regex=r".*dados_acao2025\.csv").mock(
        return_value=httpx.Response(200, content=ACAO_LATIN1)
    )
    df = siop_cadastro_acoes(2025)
    assert df.loc[0, "Título"] == "Processo Legislativo" and df.loc[0, "UO"] == "01101"
    siop_cadastro_acoes(2025)
    assert arq.call_count == 1  # segunda chamada vem do cache
    siop_cadastro_acoes(2025, refresh=True)
    assert arq.call_count == 2


@respx.mock
def test_creditos_zip_e_valores(tmp_path, monkeypatch):
    monkeypatch.setattr("siopy.catalogo.cache_dir", lambda: tmp_path)
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        z.writestr("creditos.csv", CRED_UTF8_BOM)
    respx.get(CATALOGO_URL).mock(return_value=httpx.Response(200, text=HTML))
    respx.get(url__regex=r".*alteracoesorcamentarias_2025\.csv").mock(
        return_value=httpx.Response(200, content=buf.getvalue())
    )
    df = siop_creditos(2025)
    assert df.loc[0, "val_reducao"] == 1630282.0


@respx.mock
def test_exercicio_inexistente(tmp_path, monkeypatch):
    monkeypatch.setattr("siopy.catalogo.cache_dir", lambda: tmp_path)
    respx.get(CATALOGO_URL).mock(return_value=httpx.Response(200, text=HTML))
    import pytest

    with pytest.raises(ValueError, match="Disponíveis: \\[2025\\]"):
        siop_creditos(2019)
    assert len(siop_catalogo()) == 7
