package br.com.quickcoders.backendtcsitaupjpayment.infrastructure.security;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@ConditionalOnProperty(name = "app.security.enabled", havingValue = "true")
public class SecurityConfig {

    @Bean
    CognitoLogoutHandler cognitoLogoutHandler(
            @Value("${app.security.cognito.domain}") String domain,
            @Value("${app.security.cognito.logout-redirect-uri}") String logoutRedirectUrl,
            @Value("${spring.security.oauth2.client.registration.cognito.client-id}") String userPoolClientId
    ) {
        return new CognitoLogoutHandler(domain, logoutRedirectUrl, userPoolClientId);
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, CognitoLogoutHandler cognitoLogoutHandler) throws Exception {
        http
                .csrf(Customizer.withDefaults())
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers("/").permitAll()
                        .requestMatchers("/actuator/health", "/actuator/health/**").permitAll()
                        .anyRequest().authenticated()
                )
                .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
                .oauth2Login(Customizer.withDefaults())
                .logout(logout -> logout
                        .logoutUrl("/logout")
                        .logoutSuccessHandler(cognitoLogoutHandler)
                );
        return http.build();
    }
}
