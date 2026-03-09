package br.com.quickcoders.backendtcsitaupjnotificationservice.application;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class NotificationServiceTest {

    private final NotificationService service = new NotificationService();

    @Test
    void dispatch_settledStatus_shouldUseWebhookChannel() {
        Map<String, String> result = service.dispatch("pay-1", "SETTLED");

        assertEquals("pay-1", result.get("paymentId"));
        assertEquals("SETTLED", result.get("status"));
        assertEquals("webhook", result.get("channel"));
        assertEquals("simulated", result.get("delivery"));
    }

    @Test
    void dispatch_fraudRejectedStatus_shouldUseEmailChannel() {
        Map<String, String> result = service.dispatch("pay-2", "FRAUD_REJECTED");

        assertEquals("email", result.get("channel"));
    }

    @Test
    void dispatch_compensatedStatus_shouldUsePushChannel() {
        Map<String, String> result = service.dispatch("pay-3", "COMPENSATED");

        assertEquals("push", result.get("channel"));
    }

    @Test
    void dispatch_unknownStatus_shouldFallbackToWebhook() {
        Map<String, String> result = service.dispatch("pay-4", "PENDING");

        assertEquals("webhook", result.get("channel"));
    }

    @Test
    void dispatch_caseInsensitiveStatus_shouldMatchChannel() {
        Map<String, String> result = service.dispatch("pay-5", "settled");

        assertEquals("webhook", result.get("channel"));
    }
}
