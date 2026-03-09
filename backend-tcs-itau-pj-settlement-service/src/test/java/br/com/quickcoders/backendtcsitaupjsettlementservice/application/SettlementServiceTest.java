package br.com.quickcoders.backendtcsitaupjsettlementservice.application;

import br.com.quickcoders.backendtcsitaupjsettlementservice.infrastructure.persistence.SettlementRecord;
import br.com.quickcoders.backendtcsitaupjsettlementservice.infrastructure.persistence.SettlementRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SettlementServiceTest {

    @Mock
    SettlementRepository repository;

    @InjectMocks
    SettlementService settlementService;

    @Test
    void settle_approvedDecision_shouldReturnSettled() {
        FraudDecisionCommand cmd = new FraudDecisionCommand("pay-1", "APPROVED", "evt-1");
        when(repository.existsByPaymentId("pay-1")).thenReturn(false);
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        String status = settlementService.settle(cmd);

        assertEquals("SETTLED", status);
        ArgumentCaptor<SettlementRecord> captor = ArgumentCaptor.forClass(SettlementRecord.class);
        verify(repository).save(captor.capture());
        assertEquals("SETTLED", captor.getValue().getStatus());
        assertEquals("pay-1", captor.getValue().getPaymentId());
    }

    @Test
    void settle_rejectedDecision_shouldReturnFraudRejected() {
        FraudDecisionCommand cmd = new FraudDecisionCommand("pay-2", "REJECTED", "evt-2");
        when(repository.existsByPaymentId("pay-2")).thenReturn(false);
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        String status = settlementService.settle(cmd);

        assertEquals("FRAUD_REJECTED", status);
    }

    @Test
    void settle_duplicatePayment_shouldReturnExistingStatus() {
        FraudDecisionCommand cmd = new FraudDecisionCommand("pay-3", "APPROVED", "evt-3");
        SettlementRecord existing = new SettlementRecord(
                "id-1", "pay-3", "evt-old", "APPROVED", "SETTLED", LocalDateTime.now());

        when(repository.existsByPaymentId("pay-3")).thenReturn(true);
        when(repository.findByPaymentId("pay-3")).thenReturn(Optional.of(existing));

        String status = settlementService.settle(cmd);

        assertEquals("SETTLED", status);
        verify(repository, never()).save(any());
    }

    @Test
    void getStatus_existingPayment_shouldReturnStatus() {
        SettlementRecord record = new SettlementRecord(
                "id-1", "pay-4", "evt-4", "APPROVED", "SETTLED", LocalDateTime.now());
        when(repository.findByPaymentId("pay-4")).thenReturn(Optional.of(record));

        assertEquals("SETTLED", settlementService.getStatus("pay-4"));
    }

    @Test
    void getStatus_unknownPayment_shouldReturnNotFound() {
        when(repository.findByPaymentId("pay-99")).thenReturn(Optional.empty());

        assertEquals("NOT_FOUND", settlementService.getStatus("pay-99"));
    }
}
