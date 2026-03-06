package br.com.quickcoders.settlement.interfaces;

import br.com.quickcoders.settlement.application.FraudDecisionCommand;
import br.com.quickcoders.settlement.application.SettlementService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/settlement")
public class SettlementController {

    private final SettlementService settlementService;

    public SettlementController(SettlementService settlementService) {
        this.settlementService = settlementService;
    }

    @PostMapping("/fraud-decision")
    public Map<String, String> handleDecision(@Valid @RequestBody FraudDecisionCommand command) {
        String status = settlementService.settle(command);
        return Map.of("paymentId", command.paymentId(), "status", status);
    }

    @GetMapping("/{paymentId}")
    public Map<String, String> status(@PathVariable String paymentId) {
        return Map.of("paymentId", paymentId, "status", settlementService.getStatus(paymentId));
    }
}
