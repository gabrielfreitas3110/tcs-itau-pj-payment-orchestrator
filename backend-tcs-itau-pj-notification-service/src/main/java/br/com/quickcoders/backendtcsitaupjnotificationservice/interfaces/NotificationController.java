package br.com.quickcoders.backendtcsitaupjnotificationservice.interfaces;

import br.com.quickcoders.backendtcsitaupjnotificationservice.application.NotificationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @PostMapping
    public Map<String, String> send(@Valid @RequestBody NotificationCommand command) {
        return notificationService.dispatch(command.paymentId(), command.status());
    }

    public record NotificationCommand(
            @NotBlank String paymentId,
            @NotBlank String status
    ) {
    }
}
