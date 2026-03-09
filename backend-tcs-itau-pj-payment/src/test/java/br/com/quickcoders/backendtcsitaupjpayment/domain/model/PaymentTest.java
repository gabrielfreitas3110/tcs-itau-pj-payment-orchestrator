package br.com.quickcoders.backendtcsitaupjpayment.domain.model;

import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Cnpj;
import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Money;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class PaymentTest {

    @Test
    void shouldCreatePaymentWithCreatedStatus() {
        Payment payment = Payment.create(
                new Cnpj("12345678000190"),
                new Money(new BigDecimal("500.00"), "BRL"),
                "merchant-1"
        );

        assertNotNull(payment.id());
        assertEquals(PaymentStatus.CREATED, payment.status());
        assertNotNull(payment.createdAt());
        assertEquals("12345678000190", payment.cnpj().value());
        assertEquals("merchant-1", payment.merchantId());
    }

    @Test
    void shouldRejectNullId() {
        assertThrows(NullPointerException.class, () -> new Payment(
                null,
                new Cnpj("12345678000190"),
                new Money(new BigDecimal("100.00"), "BRL"),
                "merchant-1",
                PaymentStatus.CREATED,
                java.time.Instant.now()
        ));
    }

    @Test
    void shouldRejectNullMerchantId() {
        assertThrows(NullPointerException.class, () -> new Payment(
                java.util.UUID.randomUUID(),
                new Cnpj("12345678000190"),
                new Money(new BigDecimal("100.00"), "BRL"),
                null,
                PaymentStatus.CREATED,
                java.time.Instant.now()
        ));
    }
}
