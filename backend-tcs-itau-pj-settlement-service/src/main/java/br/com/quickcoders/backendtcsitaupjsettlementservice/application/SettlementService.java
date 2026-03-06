package br.com.quickcoders.backendtcsitaupjsettlementservice.application;

import br.com.quickcoders.backendtcsitaupjsettlementservice.infrastructure.persistence.SettlementRecord;
import br.com.quickcoders.backendtcsitaupjsettlementservice.infrastructure.persistence.SettlementRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class SettlementService {

    private static final Logger LOGGER = LoggerFactory.getLogger(SettlementService.class);

    private final SettlementRepository repository;

    public SettlementService(SettlementRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public String settle(FraudDecisionCommand command) {
        if (repository.existsByPaymentId(command.paymentId())) {
            String existing = repository.findByPaymentId(command.paymentId())
                    .map(SettlementRecord::getStatus)
                    .orElse("UNKNOWN");
            LOGGER.warn("[Settlement] paymentId={} já liquidado com status={}. Ignorando duplicata.",
                    command.paymentId(), existing);
            return existing;
        }

        String status = "APPROVED".equalsIgnoreCase(command.decision()) ? "SETTLED" : "FRAUD_REJECTED";

        SettlementRecord record = new SettlementRecord(
                UUID.randomUUID().toString(),
                command.paymentId(),
                command.eventId(),
                command.decision(),
                status,
                LocalDateTime.now()
        );

        repository.save(record);
        LOGGER.info("[Settlement] Liquidação persistida: paymentId={} status={}", command.paymentId(), status);
        return status;
    }

    @Transactional(readOnly = true)
    public String getStatus(String paymentId) {
        return repository.findByPaymentId(paymentId)
                .map(SettlementRecord::getStatus)
                .orElse("NOT_FOUND");
    }
}
