package br.com.quickcoders.backendtcsitaupjpayment.infrastructure.messaging;

public interface PaymentEventPublisher {
    void publish(String eventType, String payload);
}
