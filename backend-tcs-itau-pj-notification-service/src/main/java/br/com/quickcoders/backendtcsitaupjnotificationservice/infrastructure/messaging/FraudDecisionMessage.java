package br.com.quickcoders.backendtcsitaupjnotificationservice.infrastructure.messaging;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record FraudDecisionMessage(
        String eventId,
        String paymentId,
        String decision,
        double ruleScore,
        double anomalyScore
) {}
