"""siopy — Orçamento Federal (SIOP Dados Abertos) e emendas parlamentares (Portal da Transparência).

Fontes públicas, sem credencial do SIOP:

* ``siop_*`` — endpoint SPARQL e CSVs dos Dados Abertos do SIOP/SOF.
* ``pt_*``   — API REST do Portal da Transparência (chave em ``PORTAL_TRANSPARENCIA_API_KEY``).
"""

from ._msg import set_verbose
from ._version import __version__
from .apoio import camara_deputados, cnpj_municipio, ibge_municipios, sem_acento
from .catalogo import (
    siop_acompanhamento,
    siop_cadastro_acoes,
    siop_catalogo,
    siop_creditos,
    siop_download,
    siop_regionalizacao,
)
from .orcamento import (
    TIPO_EMENDA_RP,
    siop_emendas,
    siop_exercicios,
    siop_orcamento,
    siop_orgaos,
    siop_ultima_atualizacao,
)
from .sparql import sparql as siop_sparql
from .transparencia import (
    PortalTransparencia,
    emendas_execucao,
    pt_despesa_documento,
    pt_documentos_relacionados,
    pt_emenda_documentos,
    pt_emendas,
    pt_favorecidos_finais,
    pt_has_key,
    pt_set_key,
)

__all__ = [
    "TIPO_EMENDA_RP",
    "PortalTransparencia",
    "__version__",
    "camara_deputados",
    "cnpj_municipio",
    "emendas_execucao",
    "ibge_municipios",
    "pt_despesa_documento",
    "pt_documentos_relacionados",
    "pt_emenda_documentos",
    "pt_emendas",
    "pt_favorecidos_finais",
    "pt_has_key",
    "pt_set_key",
    "sem_acento",
    "set_verbose",
    "siop_acompanhamento",
    "siop_cadastro_acoes",
    "siop_catalogo",
    "siop_creditos",
    "siop_download",
    "siop_emendas",
    "siop_exercicios",
    "siop_orcamento",
    "siop_orgaos",
    "siop_regionalizacao",
    "siop_sparql",
    "siop_ultima_atualizacao",
]
