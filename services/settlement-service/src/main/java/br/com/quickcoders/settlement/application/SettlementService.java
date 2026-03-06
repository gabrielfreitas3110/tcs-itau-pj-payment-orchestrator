package br.com.quickcoders.settlement.application;

import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class SettlementService {

    private final Map<String, String> paymentStatus = new ConcurrentHashMap<>();

    public String settle(FraudDecisionCommand command) {
        if ("APPROVED".equalsIgnoreCase(command.decision())) {
            paymentStatus.put(command.paymentId(), "SETTLED");
            return "SETTLED";
        }
        paymentStatus.put(command.paymentId(), "FRAUD_REJECTED");
        return "FRAUD_REJECTED";
    }

    public String getStatus(String paymentId) {
        return paymentStatus.getOrDefault(paymentId, "UNKNOWN");
    }
}
