package br.com.quickcoders.backendtcsitaupjpayment.domain.valueobject;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CnpjTest {

    @Test
    void shouldNormalizeFormattedCnpj() {
        Cnpj cnpj = new Cnpj("12.345.678/0001-90");
        assertEquals("12345678000190", cnpj.value());
    }

    @Test
    void shouldAcceptUnformattedCnpj() {
        Cnpj cnpj = new Cnpj("12345678000190");
        assertEquals("12345678000190", cnpj.value());
    }

    @Test
    void shouldRejectCnpjWithLessThan14Digits() {
        assertThrows(IllegalArgumentException.class, () -> new Cnpj("1234567800019"));
    }

    @Test
    void shouldRejectCnpjWithMoreThan14Digits() {
        assertThrows(IllegalArgumentException.class, () -> new Cnpj("123456780001901"));
    }

    @Test
    void shouldRejectNullCnpj() {
        assertThrows(NullPointerException.class, () -> new Cnpj(null));
    }
}
