# Frontend Mobile — Market Case: PJ Payment App

## Objetivo do App
Um aplicativo Android nativo, escalável e seguro, projetado para consumir a arquitetura de microsserviços do ecosistema de pagamentos PJ. O foco é garantir uma experiência fluida (*near real-time*), resiliência em cenários de baixa conectividade e segurança de nível bancário.

---

## Stack Tecnológica e Arquitetura
- **Linguagem:** Kotlin
- **Arquitetura UI:** MVI (Model-View-Intent) acoplado a uma Clean Architecture baseada em fluxos unidirecionais de dados.
- **Modularização:** Divisão estrita por *features* e *core modules* (`:app`, `:core:network`, `:core:designsystem`, `:feature:payments`, `:feature:auth`) para otimizar tempo de build e trabalho em equipe.
- **UI Toolkit:** Jetpack Compose.
- **Concorrência e Reatividade:** Kotlin Coroutines e StateFlow/SharedFlow.
- **Injeção de Dependência:** Hilt.
- **Networking:** Ktor Client ou Retrofit + OkHttp.

---

## Segurança e Persistência Local (Nível Bancário)
- **Armazenamento Seguro:** Uso do `EncryptedSharedPreferences` (Jetpack Security) para armazenar tokens JWT e dados sensíveis.
- **Autenticação Biométrica:** Integração com a API de Biometria do Android para aprovação de transações (PIX/Transferências).
- **Proteção de Rede:** Implementação de *SSL Pinning* para prevenir ataques *Man-in-the-Middle* (MitM).
- **Offline-First:** Utilização do Room Database para cache criptografado do histórico de transações, permitindo navegação básica mesmo sem internet.

---

## Funcionalidades e Telas Críticas
1. **Módulo de Autenticação:** Login, gestão de sessão e renovação automática de *refresh tokens* via OkHttp Interceptors.
2. **Dashboard de Gestão PJ:** Visão consolidada de saldo, limite corporativo e atalhos rápidos de movimentação.
3. **Orquestrador de Pagamentos:** Fluxo transacional robusto, com tipagem forte de domínio (*Value Objects* como `Money` e `Cnpj`) e validação de formulários assíncrona.
4. **Timeline da Transação (Real-Time):** Tela de detalhamento que reflete o motor de *Step Functions* do backend (Criado → Em Análise → Autorizado → Liquidado).
   - *Estratégia:* Implementação de Server-Sent Events (SSE) ou *Smart Polling* (com *exponential backoff*) em Coroutines para atualizar a interface imediatamente quando a transação for aprovada pelo antifraude.

---

## Observabilidade Mobile e CI/CD
- **Telemetry & Crashlytics:** Rastreamento de falhas e logs não-fatais enviados via Datadog RUM (Real User Monitoring) ou Firebase Crashlytics.
- **Esteira de Deploy (Fastlane):** Pipeline configurado (via GitHub Actions/Bitrise) para rodar ktlint, Detekt (análise estática), executar a suíte de testes e gerar o APK/AAB de *staging*.
- **Testes:** - Testes unitários para regras de apresentação (ViewModels) com MockK.
  - Testes de UI/Snapshot com Paparazzi ou Jetpack Compose Testing.