package br.com.quickcoders.backendtcsitaupjsettlementservice.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SettlementRepository extends JpaRepository<SettlementRecord, String> {

    Optional<SettlementRecord> findByPaymentId(String paymentId);

    boolean existsByPaymentId(String paymentId);
}
