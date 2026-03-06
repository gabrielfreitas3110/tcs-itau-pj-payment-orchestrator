package br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence;

import br.com.quickcoders.backendtcsitaupjpayment.domain.port.OutboxEventRepositoryPort;
import br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence.jpa.entity.OutboxEventJpaEntity;
import br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence.jpa.repository.SpringDataOutboxRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Component
public class OutboxRepositoryAdapter implements OutboxEventRepositoryPort {

    private final SpringDataOutboxRepository repository;

    public OutboxRepositoryAdapter(SpringDataOutboxRepository repository) {
        this.repository = repository;
    }

    @Override
    public void save(UUID eventId, String eventType, String aggregateId, String payload, Instant occurredAt) {
        OutboxEventJpaEntity entity = new OutboxEventJpaEntity();
        entity.setId(eventId);
        entity.setEventType(eventType);
        entity.setAggregateId(aggregateId);
        entity.setPayload(payload);
        entity.setOccurredAt(occurredAt);
        repository.save(entity);
    }

    @Override
    public List<OutboxRecord> nextBatch(int size) {
        return repository.findTop50ByPublishedAtIsNullOrderByOccurredAtAsc()
                .stream()
                .limit(size)
                .map(event -> new OutboxRecord(
                        event.getId(),
                        event.getEventType(),
                        event.getAggregateId(),
                        event.getPayload()
                ))
                .toList();
    }

    @Override
    @Transactional
    public void markAsPublished(UUID eventId) {
        repository.findById(eventId).ifPresent(event -> {
            event.setPublishedAt(Instant.now());
            repository.save(event);
        });
    }
}
