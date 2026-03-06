package br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject;

import java.util.Objects;

public record Cnpj(String value) {

    public Cnpj {
        Objects.requireNonNull(value, "cnpj is required");
        String normalized = value.replaceAll("\\D", "");
        if (normalized.length() != 14) {
            throw new IllegalArgumentException("cnpj must have 14 digits");
        }
        value = normalized;
    }
}
