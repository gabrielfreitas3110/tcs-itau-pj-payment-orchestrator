package br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject;

import java.math.BigDecimal;
import java.util.Objects;

public record Money(BigDecimal amount, String currency) {

    public Money {
        Objects.requireNonNull(amount, "amount is required");
        Objects.requireNonNull(currency, "currency is required");
        if (amount.signum() <= 0) {
            throw new IllegalArgumentException("amount must be positive");
        }
        if (currency.length() != 3) {
            throw new IllegalArgumentException("currency must have 3 chars");
        }
        currency = currency.toUpperCase();
    }
}
