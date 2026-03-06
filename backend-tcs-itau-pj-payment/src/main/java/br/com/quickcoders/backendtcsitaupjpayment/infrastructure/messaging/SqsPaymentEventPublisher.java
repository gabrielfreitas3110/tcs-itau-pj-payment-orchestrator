package br.com.quickcoders.backendtcsitaupjpayment.infrastructure.messaging;

import io.awspring.cloud.sqs.operations.SqsTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class SqsPaymentEventPublisher implements PaymentEventPublisher {

    private static final Logger LOGGER = LoggerFactory.getLogger(SqsPaymentEventPublisher.class);

    private final SqsTemplate sqsTemplate;
    private final String paymentCreatedQueue;

    public SqsPaymentEventPublisher(
            SqsTemplate sqsTemplate,
            @Value("${app.queues.payment-created:payment-created}") String paymentCreatedQueue
    ) {
        this.sqsTemplate = sqsTemplate;
        this.paymentCreatedQueue = paymentCreatedQueue;
    }

    @Override
    public void publish(String eventType, String payload) {
        LOGGER.info("publishing eventType={} queue={}", eventType, paymentCreatedQueue);
        sqsTemplate.send(to -> to.queue(paymentCreatedQueue).payload(payload));
    }
}
