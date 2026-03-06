package br.com.quickcoders.backendtcsitaupjpayment.application.usecase;

import br.com.quickcoders.backendtcsitaupjpayment.application.dto.CreatePaymentCommand;
import br.com.quickcoders.backendtcsitaupjpayment.domain.model.Payment;
import br.com.quickcoders.backendtcsitaupjpayment.domain.port.OutboxEventRepositoryPort;
import br.com.quickcoders.backendtcsitaupjpayment.domain.port.PaymentRepositoryPort;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class CreatePaymentUseCaseTest {

    @Test
    void shouldCreatePaymentAndRegisterOutbox() {
        var paymentRepository = new InMemoryPaymentRepository();
        var outboxRepository = new InMemoryOutboxRepository();
        var useCase = new CreatePaymentUseCase(paymentRepository, outboxRepository, new ObjectMapper());

        var response = useCase.execute(new CreatePaymentCommand("12345678000190", new java.math.BigDecimal("10.00"), "BRL", "merchant-1"));

        assertNotNull(response.id());
        assertEquals("CREATED", response.status());
        assertEquals(1, outboxRepository.savedCount);
    }

    static class InMemoryPaymentRepository implements PaymentRepositoryPort {
        private Payment payment;

        @Override
        public Payment save(Payment payment) {
            this.payment = payment;
            return payment;
        }

        @Override
        public Optional<Payment> findById(UUID id) {
            return Optional.ofNullable(payment);
        }
    }

    static class InMemoryOutboxRepository implements OutboxEventRepositoryPort {
        int savedCount = 0;

        @Override
        public void save(UUID eventId, String eventType, String aggregateId, String payload, Instant occurredAt) {
            savedCount++;
        }

        @Override
        public List<OutboxRecord> nextBatch(int size) {
            return List.of();
        }

        @Override
        public void markAsPublished(UUID eventId) {
        }
    }
}
