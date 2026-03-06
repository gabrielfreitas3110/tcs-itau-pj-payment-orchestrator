package br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence;

import br.com.quickcoders.backendtcsitaupjpayment.domain.model.Payment;
import br.com.quickcoders.backendtcsitaupjpayment.domain.port.PaymentRepositoryPort;
import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Cnpj;
import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Money;
import br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence.jpa.entity.PaymentJpaEntity;
import br.com.quickcoders.backendtcsitaupjpayment.infrastructure.persistence.jpa.repository.SpringDataPaymentRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
public class PaymentRepositoryAdapter implements PaymentRepositoryPort {

    private final SpringDataPaymentRepository repository;

    public PaymentRepositoryAdapter(SpringDataPaymentRepository repository) {
        this.repository = repository;
    }

    @Override
    public Payment save(Payment payment) {
        PaymentJpaEntity entity = new PaymentJpaEntity();
        entity.setId(payment.id());
        entity.setCnpj(payment.cnpj().value());
        entity.setAmount(payment.money().amount());
        entity.setCurrency(payment.money().currency());
        entity.setMerchantId(payment.merchantId());
        entity.setStatus(payment.status());
        entity.setCreatedAt(payment.createdAt());
        PaymentJpaEntity saved = repository.save(entity);
        return toDomain(saved);
    }

    @Override
    public Optional<Payment> findById(UUID id) {
        return repository.findById(id).map(this::toDomain);
    }

    private Payment toDomain(PaymentJpaEntity entity) {
        return new Payment(
                entity.getId(),
                new Cnpj(entity.getCnpj()),
                new Money(entity.getAmount(), entity.getCurrency()),
                entity.getMerchantId(),
                entity.getStatus(),
                entity.getCreatedAt()
        );
    }
}
