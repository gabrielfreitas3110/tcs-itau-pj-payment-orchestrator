package br.com.quickcoders.backendtcsitaupjnotificationservice.application;

import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class NotificationService {

    public Map<String, String> dispatch(String paymentId, String status) {
        String channel;
        if ("SETTLED".equalsIgnoreCase(status)) {
            channel = "webhook";
        } else if ("FRAUD_REJECTED".equalsIgnoreCase(status)) {
            channel = "email";
        } else if ("COMPENSATED".equalsIgnoreCase(status)) {
            channel = "push";
        } else {
            channel = "webhook";
        }
        return Map.of(
                "paymentId", paymentId,
                "status", status,
                "channel", channel,
                "delivery", "simulated"
        );
    }
}
