package br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence.jpa.repository;

import br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence.jpa.entity.PaymentJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface SpringDataPaymentRepository extends JpaRepository<PaymentJpaEntity, UUID> {
}
