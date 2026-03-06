package br.com.quickcoders.backendtcsitaupjnotificationservice.infrastructure.messaging;

import br.com.quickcoders.backendtcsitaupjnotificationservice.application.NotificationService;
import io.awspring.cloud.sqs.annotation.SqsListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class SqsFraudDecisionListener {

    private static final Logger LOGGER = LoggerFactory.getLogger(SqsFraudDecisionListener.class);

    private final NotificationService notificationService;

    public SqsFraudDecisionListener(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @SqsListener("${app.queues.notification:payment-notification}")
    public void onFraudDecision(FraudDecisionMessage message) {
        LOGGER.info("[SQS] Fraud decision recebida: paymentId={} decision={}",
                message.paymentId(), message.decision());

        String status = "APPROVED".equalsIgnoreCase(message.decision()) ? "SETTLED" : "FRAUD_REJECTED";

        Map<String, String> result = notificationService.dispatch(message.paymentId(), status);

        LOGGER.info("[Notification] paymentId={} status={} channel={} delivery={}",
                result.get("paymentId"), result.get("status"),
                result.get("channel"), result.get("delivery"));
    }
}
