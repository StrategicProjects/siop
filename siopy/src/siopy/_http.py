"""Cliente HTTP compartilhado: retries com backoff e User-Agent."""

from __future__ import annotations

import random
import time
from typing import Any

import httpx

from ._version import __version__

USER_AGENT = f"siopy/{__version__} (+https://github.com/castlab/siop-sdk)"

RETRY_STATUS = {429, 500, 502, 503, 504}


class SiopHTTPError(RuntimeError):
    """Erro HTTP com status e corpo (truncado) da resposta."""

    def __init__(self, response: httpx.Response):
        self.status_code = response.status_code
        self.url = str(response.request.url)
        body = response.text[:500]
        super().__init__(f"HTTP {self.status_code} em {self.url}: {body}")


def make_client(timeout: float = 300.0, headers: dict[str, str] | None = None) -> httpx.Client:
    h = {"User-Agent": USER_AGENT}
    if headers:
        h.update(headers)
    return httpx.Client(
        timeout=httpx.Timeout(timeout, connect=30.0), headers=h, follow_redirects=True
    )


def request_with_retry(
    client: httpx.Client,
    method: str,
    url: str,
    *,
    max_tries: int = 4,
    base_delay: float = 1.0,
    **kwargs: Any,
) -> httpx.Response:
    """Executa a requisição; repete em 429/5xx e erros de transporte com backoff exponencial."""
    last_exc: Exception | None = None
    for attempt in range(max_tries):
        try:
            resp = client.request(method, url, **kwargs)
        except httpx.TransportError as exc:  # timeouts, conexão
            last_exc = exc
            resp = None
        if resp is not None:
            if resp.status_code < 400:
                return resp
            if resp.status_code not in RETRY_STATUS or attempt == max_tries - 1:
                raise SiopHTTPError(resp)
            retry_after = resp.headers.get("Retry-After")
            if retry_after and retry_after.isdigit():
                time.sleep(int(retry_after))
                continue
        if attempt == max_tries - 1:
            break
        time.sleep(base_delay * (2**attempt) + random.uniform(0, 0.5))
    assert last_exc is not None
    raise last_exc
