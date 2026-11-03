from pathlib import Path

import pytest

FIX = Path(__file__).parent / "fixtures"


@pytest.fixture
def fixture_text():
    def _read(name: str) -> str:
        return (FIX / name).read_text(encoding="utf-8")

    return _read


@pytest.fixture
def fixture_bytes():
    def _read(name: str) -> bytes:
        return (FIX / name).read_bytes()

    return _read
