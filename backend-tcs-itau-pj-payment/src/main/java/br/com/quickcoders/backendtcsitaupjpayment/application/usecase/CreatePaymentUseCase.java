package br.com.quickcoders.backendtcsitaupjpayment.application.usecase;

import br.com.quickcoders.backendtcsitaupjpayment.application.dto.CreatePaymentCommand;
import br.com.quickcoders.backendtcsitaupjpayment.application.dto.PaymentResponse;
import br.com.quickcoders.backendtcsitaupjpayment.domain.model.Payment;
import br.com.quickcoders.backendtcsitaupjpayment.domain.port.OutboxEventRepositoryPort;
import br.com.quickcoders.backendtcsitaupjpayment.domain.port.PaymentRepositoryPort;
import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Cnpj;
import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Money;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Service
public class CreatePaymentUseCase {

    private final PaymentRepositoryPort paymentRepositoryPort;
    private final OutboxEventRepositoryPort outboxEventRepositoryPort;
    private final ObjectMapper objectMapper;

    public CreatePaymentUseCase(
            PaymentRepositoryPort paymentRepositoryPort,
            OutboxEventRepositoryPort outboxEventRepositoryPort,
            ObjectMapper objectMapper
    ) {
        this.paymentRepositoryPort = paymentRepositoryPort;
        this.outboxEventRepositoryPort = outboxEventRepositoryPort;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public PaymentResponse execute(CreatePaymentCommand command) {
        Payment payment = Payment.create(
                new Cnpj(command.cnpj()),
                new Money(command.amount(), command.currency()),
                command.merchantId()
        );

        Payment saved = paymentRepositoryPort.save(payment);
        UUID eventId = UUID.randomUUID();
        outboxEventRepositoryPort.save(
                eventId,
                "payment.created.v1",
                saved.id().toString(),
                serializePaymentCreated(eventId, saved),
                Instant.now()
        );
        return toResponse(saved);
    }

    private String serializePaymentCreated(UUID eventId, Payment payment) {
        try {
            return objectMapper.writeValueAsString(Map.of(
                    "eventId", eventId.toString(),
                    "eventType", "payment.created.v1",
                    "occurredAt", Instant.now().toString(),
                    "paymentId", payment.id().toString(),
                    "cnpj", payment.cnpj().value(),
                    "amount", payment.money().amount(),
                    "currency", payment.money().currency(),
                    "merchantId", payment.merchantId()
            ));
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("could not serialize payment.created event", ex);
        }
    }

    private PaymentResponse toResponse(Payment payment) {
        return new PaymentResponse(
                payment.id(),
                payment.cnpj().value(),
                payment.money().amount(),
                payment.money().currency(),
                payment.merchantId(),
                payment.status().name(),
                payment.createdAt()
        );
    }
}
