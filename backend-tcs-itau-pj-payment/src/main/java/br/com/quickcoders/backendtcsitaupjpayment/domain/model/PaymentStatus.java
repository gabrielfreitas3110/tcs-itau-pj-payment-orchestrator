package br.com.quickcoders.backendtcsitaupjpayment.domain.model;

public enum PaymentStatus {
    CREATED,
    FRAUD_APPROVED,
    FRAUD_REJECTED,
    SETTLED,
    COMPENSATED
}
