package br.com.quickcoders.backendtcsitaupjpayment.domain.port;

import br.com.quickcoders.backendtcsitaupjpayment.domain.model.Payment;

import java.util.Optional;
import java.util.UUID;

public interface PaymentRepositoryPort {
    Payment save(Payment payment);
    Optional<Payment> findById(UUID id);
}
