package br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class MoneyTest {

    @Test
    void shouldCreateValidMoney() {
        Money money = new Money(new BigDecimal("100.00"), "brl");
        assertEquals(new BigDecimal("100.00"), money.amount());
        assertEquals("BRL", money.currency());
    }

    @Test
    void shouldNormalizeCurrencyToUpperCase() {
        Money money = new Money(new BigDecimal("1.00"), "usd");
        assertEquals("USD", money.currency());
    }

    @Test
    void shouldRejectZeroAmount() {
        assertThrows(IllegalArgumentException.class,
                () -> new Money(BigDecimal.ZERO, "BRL"));
    }

    @Test
    void shouldRejectNegativeAmount() {
        assertThrows(IllegalArgumentException.class,
                () -> new Money(new BigDecimal("-1.00"), "BRL"));
    }

    @Test
    void shouldRejectCurrencyWithLessThan3Chars() {
        assertThrows(IllegalArgumentException.class,
                () -> new Money(new BigDecimal("10.00"), "BR"));
    }

    @Test
    void shouldRejectCurrencyWithMoreThan3Chars() {
        assertThrows(IllegalArgumentException.class,
                () -> new Money(new BigDecimal("10.00"), "BRLL"));
    }

    @Test
    void shouldRejectNullAmount() {
        assertThrows(NullPointerException.class,
                () -> new Money(null, "BRL"));
    }

    @Test
    void shouldRejectNullCurrency() {
        assertThrows(NullPointerException.class,
                () -> new Money(new BigDecimal("10.00"), null));
    }
}
