package br.com.quickcoders.backendtcsitaupjsettlementservice.application;

import jakarta.validation.constraints.NotBlank;

public record FraudDecisionCommand(
        @NotBlank String paymentId,
        @NotBlank String decision,
        @NotBlank String eventId
) {
}
