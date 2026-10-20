import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "app"))

from breakout import scan_breakouts, self_test_fixture
from server import _self_test


def test_self_test_matches_the_desk_fixture():
    result = scan_breakouts(self_test_fixture())
    assert result["scanned"] == 2
    assert len(result["setups"]) == 1
    setup = result["setups"][0]
    assert setup["symbol"] == "INFY"
    assert setup["breakout_low"] == 90
    assert setup["days_since"] == 4
    assert setup["vol_multiple"] == 4
    payload = _self_test()
    assert payload["status"] == "pass"


def test_scan_service_has_no_order_methods():
    root = Path(__file__).resolve().parent / "app"
    banned = ("place_gtt", "place_order", "modify_order", "cancel_order", "modify_gtt", "delete_gtt")
    for path in root.glob("*.py"):
        text = path.read_text(encoding="utf-8")
        for name in banned:
            assert name not in text
