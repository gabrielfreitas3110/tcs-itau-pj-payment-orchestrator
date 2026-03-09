package br.com.quickcoders.backendtcsitaupjnotificationservice.interfaces;

import br.com.quickcoders.backendtcsitaupjnotificationservice.application.NotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class NotificationControllerTest {

    @Mock
    NotificationService notificationService;

    MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();

        mockMvc = MockMvcBuilders
                .standaloneSetup(new NotificationController(notificationService))
                .setControllerAdvice(new ApiExceptionHandler())
                .setValidator(validator)
                .build();
    }

    @Test
    void send_validRequest_shouldReturn200() throws Exception {
        when(notificationService.dispatch(any(), any())).thenReturn(Map.of(
                "paymentId", "pay-1",
                "status", "SETTLED",
                "channel", "webhook",
                "delivery", "simulated"
        ));

        mockMvc.perform(post("/api/v1/notifications")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"paymentId\":\"pay-1\",\"status\":\"SETTLED\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.channel").value("webhook"));
    }

    @Test
    void send_missingPaymentId_shouldReturn400() throws Exception {
        mockMvc.perform(post("/api/v1/notifications")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"paymentId\":\"\",\"status\":\"SETTLED\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void send_missingStatus_shouldReturn400() throws Exception {
        mockMvc.perform(post("/api/v1/notifications")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"paymentId\":\"pay-1\",\"status\":\"\"}"))
                .andExpect(status().isBadRequest());
    }
}
