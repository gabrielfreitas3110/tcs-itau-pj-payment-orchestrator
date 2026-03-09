package br.com.quickcoders.backendtcsitaupjpayment.application.usecase;

import br.com.quickcoders.backendtcsitaupjpayment.application.dto.PaymentResponse;
import br.com.quickcoders.backendtcsitaupjpayment.domain.model.Payment;
import br.com.quickcoders.backendtcsitaupjpayment.domain.model.PaymentStatus;
import br.com.quickcoders.backendtcsitaupjpayment.domain.port.PaymentRepositoryPort;
import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Cnpj;
import br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject.Money;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GetPaymentByIdUseCaseTest {

    @Mock
    PaymentRepositoryPort paymentRepository;

    @InjectMocks
    GetPaymentByIdUseCase useCase;

    @Test
    void shouldReturnPaymentWhenFound() {
        UUID id = UUID.randomUUID();
        Payment payment = new Payment(
                id,
                new Cnpj("12345678000190"),
                new Money(new BigDecimal("200.00"), "BRL"),
                "merchant-1",
                PaymentStatus.CREATED,
                Instant.now()
        );
        when(paymentRepository.findById(id)).thenReturn(Optional.of(payment));

        PaymentResponse response = useCase.execute(id);

        assertEquals(id, response.id());
        assertEquals("12345678000190", response.cnpj());
        assertEquals("CREATED", response.status());
    }

    @Test
    void shouldThrowWhenPaymentNotFound() {
        UUID id = UUID.randomUUID();
        when(paymentRepository.findById(id)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> useCase.execute(id));
    }
}
