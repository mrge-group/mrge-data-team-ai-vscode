"""
pytest configuration and fixtures.

This file is automatically loaded by pytest.
"""

import pytest


@pytest.fixture
def sample_data():
    """Provide sample data for tests"""
    return {
        "name": "test",
        "values": [1, 2, 3, 4, 5],
        "metadata": {"source": "test", "version": "1.0"},
    }


@pytest.fixture
def temp_env_vars(monkeypatch):
    """Set temporary environment variables for tests"""
    monkeypatch.setenv("TEST_MODE", "true")
    monkeypatch.setenv("ENV", "test")
    return monkeypatch
