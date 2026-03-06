package br.com.quickcoders.backendtcsitaupjsettlementservice.infrastructure.messaging;

import br.com.quickcoders.backendtcsitaupjsettlementservice.application.FraudDecisionCommand;
import br.com.quickcoders.backendtcsitaupjsettlementservice.application.SettlementService;
import io.awspring.cloud.sqs.annotation.SqsListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class SqsFraudDecisionListener {

    private static final Logger LOGGER = LoggerFactory.getLogger(SqsFraudDecisionListener.class);

    private final SettlementService settlementService;

    public SqsFraudDecisionListener(SettlementService settlementService) {
        this.settlementService = settlementService;
    }

    @SqsListener("${app.queues.settlement:payment-settlement}")
    public void onFraudDecision(FraudDecisionMessage message) {
        LOGGER.info("[SQS] Fraud decision recebida: paymentId={} decision={}",
                message.paymentId(), message.decision());

        String status = settlementService.settle(
                new FraudDecisionCommand(message.paymentId(), message.decision(), message.eventId())
        );

        LOGGER.info("[Settlement] paymentId={} -> status={}", message.paymentId(), status);
    }
}
