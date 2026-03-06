package br.com.quickcoders.backendtcsitaupjpayment;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class BackendTcsItauPjPaymentApplication {

    public static void main(String[] args) {
        SpringApplication.run(BackendTcsItauPjPaymentApplication.class, args);
    }

}
