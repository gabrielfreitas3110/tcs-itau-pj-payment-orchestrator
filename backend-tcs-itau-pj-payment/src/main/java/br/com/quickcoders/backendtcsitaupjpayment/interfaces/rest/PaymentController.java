package br.com.quickcoders.backendtcsitaupjpayment.interfaces.rest;

import br.com.quickcoders.backendtcsitaupjpayment.application.dto.CreatePaymentCommand;
import br.com.quickcoders.backendtcsitaupjpayment.application.dto.PaymentResponse;
import br.com.quickcoders.backendtcsitaupjpayment.application.usecase.CreatePaymentUseCase;
import br.com.quickcoders.backendtcsitaupjpayment.application.usecase.GetPaymentByIdUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    private final CreatePaymentUseCase createPaymentUseCase;
    private final GetPaymentByIdUseCase getPaymentByIdUseCase;

    public PaymentController(
            CreatePaymentUseCase createPaymentUseCase,
            GetPaymentByIdUseCase getPaymentByIdUseCase
    ) {
        this.createPaymentUseCase = createPaymentUseCase;
        this.getPaymentByIdUseCase = getPaymentByIdUseCase;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PaymentResponse create(@Valid @RequestBody CreatePaymentCommand request) {
        return createPaymentUseCase.execute(request);
    }

    @GetMapping("/{id}")
    public PaymentResponse findById(@PathVariable UUID id) {
        return getPaymentByIdUseCase.execute(id);
    }
}
