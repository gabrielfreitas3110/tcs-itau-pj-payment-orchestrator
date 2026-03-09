package br.com.quickcoders.backendtcsitaupjpayment.interfaces.rest;

import br.com.quickcoders.backendtcsitaupjpayment.application.dto.PaymentResponse;
import br.com.quickcoders.backendtcsitaupjpayment.application.usecase.CreatePaymentUseCase;
import br.com.quickcoders.backendtcsitaupjpayment.application.usecase.GetPaymentByIdUseCase;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class PaymentControllerTest {

    @Mock
    CreatePaymentUseCase createPaymentUseCase;

    @Mock
    GetPaymentByIdUseCase getPaymentByIdUseCase;

    MockMvc mockMvc;
    ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();

        mockMvc = MockMvcBuilders
                .standaloneSetup(new PaymentController(createPaymentUseCase, getPaymentByIdUseCase))
                .setControllerAdvice(new ApiExceptionHandler())
                .setValidator(validator)
                .build();
    }

    @Test
    void createPayment_shouldReturn201() throws Exception {
        UUID id = UUID.randomUUID();
        when(createPaymentUseCase.execute(any())).thenReturn(
                new PaymentResponse(id, "12345678000190", new BigDecimal("100.00"),
                        "BRL", "merchant-1", "CREATED", Instant.now()));

        mockMvc.perform(post("/api/v1/payments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cnpj\":\"12345678000190\",\"amount\":100.00,\"currency\":\"BRL\",\"merchantId\":\"m-1\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("CREATED"));
    }

    @Test
    void createPayment_shouldReturn400_whenBodyInvalid() throws Exception {
        mockMvc.perform(post("/api/v1/payments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cnpj\":\"\",\"amount\":-1,\"currency\":\"BR\",\"merchantId\":\"\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getPaymentById_shouldReturn200() throws Exception {
        UUID id = UUID.randomUUID();
        when(getPaymentByIdUseCase.execute(id)).thenReturn(
                new PaymentResponse(id, "12345678000190", new BigDecimal("100.00"),
                        "BRL", "merchant-1", "CREATED", Instant.now()));

        mockMvc.perform(get("/api/v1/payments/{id}", id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id.toString()));
    }

    @Test
    void getPaymentById_shouldReturn422_whenNotFound() throws Exception {
        UUID id = UUID.randomUUID();
        when(getPaymentByIdUseCase.execute(id)).thenThrow(new IllegalArgumentException("payment not found"));

        mockMvc.perform(get("/api/v1/payments/{id}", id))
                .andExpect(status().isUnprocessableEntity());
    }
}
