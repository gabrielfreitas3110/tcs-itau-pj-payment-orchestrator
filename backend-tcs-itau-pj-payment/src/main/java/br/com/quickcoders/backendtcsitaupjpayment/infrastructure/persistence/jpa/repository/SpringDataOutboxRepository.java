package br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence.jpa.repository;

import br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence.jpa.entity.OutboxEventJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SpringDataOutboxRepository extends JpaRepository<OutboxEventJpaEntity, UUID> {
    List<OutboxEventJpaEntity> findTop50ByPublishedAtIsNullOrderByOccurredAtAsc();
}
