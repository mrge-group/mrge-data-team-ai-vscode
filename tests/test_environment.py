"""
Sample tests to verify pytest setup.

Run with:
    make test
    poetry run pytest
    poetry run pytest -v
"""

import sys


def test_python_version():
    """Verify Python version is 3.11.x"""
    assert sys.version_info.major == 3
    assert sys.version_info.minor == 11


def test_imports():
    """Verify key packages can be imported"""
    try:
        import boto3  # noqa: F401
        import duckdb  # noqa: F401
        import pandas  # noqa: F401
        import polars  # noqa: F401

        assert True
    except ImportError as e:
        assert False, f"Failed to import required package: {e}"


def test_basic_assertion():
    """Basic pytest functionality test"""
    assert 1 + 1 == 2
    assert "hello" == "hello"
    assert [1, 2, 3] == [1, 2, 3]


def test_list_operations():
    """Test list operations"""
    data = [1, 2, 3, 4, 5]

    assert len(data) == 5
    assert sum(data) == 15
    assert max(data) == 5
    assert min(data) == 1
