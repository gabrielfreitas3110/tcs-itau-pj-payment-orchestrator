package br.com.quickcoders.backendtcsitaupjpayment.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record PaymentResponse(
        UUID id,
        String cnpj,
        BigDecimal amount,
        String currency,
        String merchantId,
        String status,
        Instant createdAt
) {
}
