from unittest.mock import patch
from datetime import datetime, timezone

import pytest

from app.models import PaymentCreatedEvent
from app.rules import evaluate_rules


def _event(**kwargs) -> PaymentCreatedEvent:
    defaults = dict(
        eventId="evt-1",
        eventType="payment.created.v1",
        occurredAt="2026-03-05T10:00:00Z",
        paymentId="pay-1",
        cnpj="12345678000190",
        amount=1000.0,
        currency="BRL",
        merchantId="m1",
    )
    defaults.update(kwargs)
    return PaymentCreatedEvent(**defaults)


_BUSINESS_HOUR = datetime(2026, 3, 9, 10, 0, 0, tzinfo=timezone.utc)
_OFF_HOUR = datetime(2026, 3, 9, 3, 0, 0, tzinfo=timezone.utc)


def test_clean_payment_has_zero_score():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _BUSINESS_HOUR
        score, reasons = evaluate_rules(_event(cnpj="12345678000190"))  # even suffix
    assert score == 0.0
    assert reasons == []


def test_high_amount_triggers():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _BUSINESS_HOUR
        score, reasons = evaluate_rules(_event(amount=70000.0))
    assert score == pytest.approx(0.45)
    assert "amount_above_static_limit" in reasons


def test_amount_at_threshold_does_not_trigger():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _BUSINESS_HOUR
        score, reasons = evaluate_rules(_event(amount=50000.0))
    assert "amount_above_static_limit" not in reasons


def test_odd_cnpj_suffix_triggers():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _BUSINESS_HOUR
        score, reasons = evaluate_rules(_event(cnpj="12345678000191"))  # odd suffix 91
    assert "odd_cnpj_suffix_pattern" in reasons
    assert score == pytest.approx(0.20)


def test_even_cnpj_suffix_does_not_trigger():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _BUSINESS_HOUR
        score, reasons = evaluate_rules(_event(cnpj="12345678000190"))  # even suffix 90
    assert "odd_cnpj_suffix_pattern" not in reasons


def test_non_brl_currency_triggers():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _BUSINESS_HOUR
        score, reasons = evaluate_rules(_event(currency="USD"))
    assert "non_brl_transaction" in reasons
    assert score == pytest.approx(0.30)


def test_brl_currency_does_not_trigger():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _BUSINESS_HOUR
        score, reasons = evaluate_rules(_event(currency="BRL"))
    assert "non_brl_transaction" not in reasons


def test_off_hours_triggers():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _OFF_HOUR  # 3 AM
        score, reasons = evaluate_rules(_event())
    assert "off_hours_transaction" in reasons
    assert score == pytest.approx(0.25)


def test_all_flags_score_capped_at_1():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _OFF_HOUR
        score, reasons = evaluate_rules(_event(
            amount=70000.0,
            cnpj="12345678000191",
            currency="USD",
        ))
    assert score == pytest.approx(1.0)
    assert len(reasons) == 4


def test_score_combines_multiple_flags():
    with patch("app.rules.datetime") as mock_dt:
        mock_dt.now.return_value = _BUSINESS_HOUR
        score, reasons = evaluate_rules(_event(amount=70000.0, currency="USD"))
    assert score == pytest.approx(0.75)
    assert "amount_above_static_limit" in reasons
    assert "non_brl_transaction" in reasons
