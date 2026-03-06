package br.com.quickcoders.backendtcsitaupjpayment.domain.model;

import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Cnpj;
import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Money;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

public record Payment(
        UUID id,
        Cnpj cnpj,
        Money money,
        String merchantId,
        PaymentStatus status,
        Instant createdAt
) {
    public Payment {
        Objects.requireNonNull(id, "id is required");
        Objects.requireNonNull(cnpj, "cnpj is required");
        Objects.requireNonNull(money, "money is required");
        Objects.requireNonNull(merchantId, "merchantId is required");
        Objects.requireNonNull(status, "status is required");
        Objects.requireNonNull(createdAt, "createdAt is required");
    }

    public static Payment create(Cnpj cnpj, Money money, String merchantId) {
        return new Payment(UUID.randomUUID(), cnpj, money, merchantId, PaymentStatus.CREATED, Instant.now());
    }
}
