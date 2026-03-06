package br.com.quickcoders.backendtcsitaupjpayment.infrastructure.messaging;

import br.com.quickcoders.backendtcsitaupjpayment.domain.port.OutboxEventRepositoryPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class OutboxPublisherScheduler {

    private static final Logger LOGGER = LoggerFactory.getLogger(OutboxPublisherScheduler.class);
    private final OutboxEventRepositoryPort outboxEventRepositoryPort;
    private final PaymentEventPublisher paymentEventPublisher;

    public OutboxPublisherScheduler(
            OutboxEventRepositoryPort outboxEventRepositoryPort,
            PaymentEventPublisher paymentEventPublisher
    ) {
        this.outboxEventRepositoryPort = outboxEventRepositoryPort;
        this.paymentEventPublisher = paymentEventPublisher;
    }

    @Scheduled(fixedDelayString = "${app.outbox.publisher-delay-ms:3000}")
    public void publishPendingEvents() {
        outboxEventRepositoryPort.nextBatch(50).forEach(event -> {
            try {
                paymentEventPublisher.publish(event.eventType(), event.payload());
                outboxEventRepositoryPort.markAsPublished(event.eventId());
            } catch (Exception ex) {
                LOGGER.warn("failed to publish event {} due to {}", event.eventId(), ex.getMessage());
            }
        });
    }
}
