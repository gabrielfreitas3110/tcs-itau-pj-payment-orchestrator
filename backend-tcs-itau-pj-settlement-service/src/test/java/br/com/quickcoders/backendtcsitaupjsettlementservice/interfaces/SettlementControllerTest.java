package br.com.quickcoders.backendtcsitaupjsettlementservice.interfaces;

import br.com.quickcoders.backendtcsitaupjsettlementservice.application.SettlementService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class SettlementControllerTest {

    @Mock
    SettlementService settlementService;

    MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();

        mockMvc = MockMvcBuilders
                .standaloneSetup(new SettlementController(settlementService))
                .setControllerAdvice(new ApiExceptionHandler())
                .setValidator(validator)
                .build();
    }

    @Test
    void handleDecision_approvedPayment_shouldReturn200() throws Exception {
        when(settlementService.settle(org.mockito.ArgumentMatchers.any())).thenReturn("SETTLED");

        mockMvc.perform(post("/api/v1/settlement/fraud-decision")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"paymentId\":\"pay-1\",\"decision\":\"APPROVED\",\"eventId\":\"evt-1\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SETTLED"))
                .andExpect(jsonPath("$.paymentId").value("pay-1"));
    }

    @Test
    void handleDecision_invalidBody_shouldReturn400() throws Exception {
        mockMvc.perform(post("/api/v1/settlement/fraud-decision")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"paymentId\":\"\",\"decision\":\"\",\"eventId\":\"\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getStatus_existingPayment_shouldReturn200() throws Exception {
        when(settlementService.getStatus("pay-1")).thenReturn("SETTLED");

        mockMvc.perform(get("/api/v1/settlement/pay-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SETTLED"));
    }

    @Test
    void getStatus_unknownPayment_shouldReturnNotFound() throws Exception {
        when(settlementService.getStatus("pay-99")).thenReturn("NOT_FOUND");

        mockMvc.perform(get("/api/v1/settlement/pay-99"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("NOT_FOUND"));
    }
}
