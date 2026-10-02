from urllib.parse import urlparse


def assert_test_database(db_url: str) -> None:
    """
    Enforces that database operations that drop, truncate, or reset tables
    only ever execute against a database name ending with '_test'.
    """
    parsed = urlparse(db_url)
    db_name = parsed.path.lstrip("/").split("?")[0]
    if not db_name.endswith("_test"):
        raise RuntimeError(
            f"SAFETY VIOLATION: Database name '{db_name}' does not end in '_test'. "
            f"Tests, drop, truncate, and reset operations are strictly forbidden on this database."
        )
