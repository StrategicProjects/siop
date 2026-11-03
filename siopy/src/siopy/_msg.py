"""Mensagens leves de console, espelhando os alertas cli do pacote R.

Vão para stderr e podem ser silenciadas com :func:`set_verbose`.
"""

from __future__ import annotations

import sys

_VERBOSE = True


def set_verbose(verbose: bool) -> None:
    """Liga ou desliga as mensagens informativas (success/step/inform/progress)."""
    global _VERBOSE
    _VERBOSE = bool(verbose)


def success(message: str) -> None:
    if _VERBOSE:
        print(f"✔ {message}", file=sys.stderr)


def step(message: str) -> None:
    if _VERBOSE:
        print(f"ℹ {message}", file=sys.stderr)


def inform(message: str) -> None:
    if _VERBOSE:
        print(message, file=sys.stderr)


def progress(i: int, total: int, label: str) -> None:
    """Uma linha de progresso sobrescrita in loco (equivalente ao cli_progress_bar do R)."""
    if _VERBOSE:
        end = "\n" if i >= total else "\r"
        print(f"{label}: {i}/{total}", file=sys.stderr, end=end, flush=True)
