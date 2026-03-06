package br.com.quickcoders.backendtcsitaupjsettlementservice.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "settlements")
public class SettlementRecord {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @Column(name = "payment_id", length = 36, nullable = false, unique = true)
    private String paymentId;

    @Column(name = "fraud_event_id", length = 36, nullable = false)
    private String fraudEventId;

    @Column(name = "decision", length = 20, nullable = false)
    private String decision;

    @Column(name = "status", length = 30, nullable = false)
    private String status;

    @Column(name = "settled_at", nullable = false)
    private LocalDateTime settledAt;

    protected SettlementRecord() {}

    public SettlementRecord(String id, String paymentId, String fraudEventId,
                            String decision, String status, LocalDateTime settledAt) {
        this.id = id;
        this.paymentId = paymentId;
        this.fraudEventId = fraudEventId;
        this.decision = decision;
        this.status = status;
        this.settledAt = settledAt;
    }

    public String getId()          { return id; }
    public String getPaymentId()   { return paymentId; }
    public String getFraudEventId(){ return fraudEventId; }
    public String getDecision()    { return decision; }
    public String getStatus()      { return status; }
    public LocalDateTime getSettledAt() { return settledAt; }
}
