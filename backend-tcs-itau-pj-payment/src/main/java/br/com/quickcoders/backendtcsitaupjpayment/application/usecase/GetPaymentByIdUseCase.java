package br.com.quickcoders.backendtcsitaupjpayment.application.usecase;

import br.com.quickcoders.backendtcsitaupjpayment.application.dto.PaymentResponse;
import br.com.quickcoders.backendtcsitaupjpayment.domain.model.Payment;
import br.com.quickcoders.backendtcsitaupjpayment.domain.port.PaymentRepositoryPort;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class GetPaymentByIdUseCase {

    private final PaymentRepositoryPort paymentRepositoryPort;

    public GetPaymentByIdUseCase(PaymentRepositoryPort paymentRepositoryPort) {
        this.paymentRepositoryPort = paymentRepositoryPort;
    }

    public PaymentResponse execute(UUID id) {
        Payment payment = paymentRepositoryPort.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("payment not found"));
        return new PaymentResponse(
                payment.id(),
                payment.cnpj().value(),
                payment.money().amount(),
                payment.money().currency(),
                payment.merchantId(),
                payment.status().name(),
                payment.createdAt()
        );
    }
}
