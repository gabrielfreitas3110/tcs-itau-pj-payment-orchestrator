package br.com.quickcoders.backendtcsitaupjpayment.domain.port;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface OutboxEventRepositoryPort {
    void save(UUID eventId, String eventType, String aggregateId, String payload, Instant occurredAt);
    List<OutboxRecord> nextBatch(int size);
    void markAsPublished(UUID eventId);

    record OutboxRecord(UUID eventId, String eventType, String aggregateId, String payload) {
    }
}
