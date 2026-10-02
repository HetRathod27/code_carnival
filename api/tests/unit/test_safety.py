import pytest

from api.app.core.safety import assert_test_database


def test_safety_rejects_non_test_database():
    with pytest.raises(RuntimeError, match="SAFETY VIOLATION"):
        assert_test_database("postgresql+asyncpg://postgres:pass@localhost:5432/queueless_dev")


def test_safety_rejects_production():
    with pytest.raises(RuntimeError, match="SAFETY VIOLATION"):
        assert_test_database("postgresql+asyncpg://postgres:pass@localhost:5432/production")


def test_safety_accepts_test_database():
    # Should not raise
    assert_test_database("postgresql+asyncpg://postgres:pass@localhost:5432/queueless_test")
    assert_test_database("postgresql+asyncpg://postgres:pass@localhost:5432/my_app_test?ssl=require")
