# Backend — Market Case: PJ Payment Orchestrator

## Objetivo do Backend
Construir um backend escalável, seguro e resiliente para o domínio de **Cartão PJ e Pagamentos**, com foco em:
- Criação e processamento transacional de pagamentos.
- Análise de crédito e antifraude potencializada por Inteligência Artificial.
- Integração assíncrona orientada a eventos.
- Observabilidade profunda e esteiras ágeis de deploy.

---

## Arquitetura-alvo (DDD + Clean Architecture + Microsserviços)
A organização do código reflete o domínio e os casos de uso, garantindo isolamento de frameworks e focando em manutenibilidade a longo prazo.

### Estrutura (Clean Architecture)
- `domain/`: Entidades (`Payment`, `CardAccount`), Value Objects (`Money`, `Cnpj`), e portas de repositório. Regras de negócio puras.
- `application/`: Casos de uso (`CreatePaymentUseCase`, `SettlePaymentUseCase`), DTOs e orquestração.
- `infrastructure/`: Adapters (JPA/Aurora, SQS producers/consumers, integrações AWS).
- `interfaces/`: Controllers REST (Spring MVC), Listeners (SQS).

---

## Módulos e Tecnologias

### 1) payment-service (Java + Spring Boot)
- **Papel:** Receber requisições REST (criação/consulta de pagamentos).
- **Persistência:** Amazon Aurora (PostgreSQL).
- **Mensageria:** Publica eventos no SQS (`payment.created`) utilizando o *Outbox Pattern* para garantir consistência transacional entre o banco e a fila.

### 2) fraud-service (Python + FastAPI) — *[Integração com IA]*
- **Papel:** Consumir SQS (`payment.created`) e executar motor de regras antifraude.
- **Inovação:** Além de limites estáticos, integra uma chamada a um modelo de Machine Learning (via AWS Bedrock ou SageMaker) para gerar um *Score de Anomalia* baseado no comportamento da transação.
- **Persistência:** Grava evidências em DynamoDB para consultas ultrarrápidas de auditoria.

### 3) settlement-service (Java + Spring Boot)
- **Papel:** Consumir eventos autorizados, executar a liquidação contábil, e persistir o status final no Aurora.

### 4) notification-service (Kotlin + Spring Boot)
- **Papel:** Consumir eventos do SNS/SQS e disparar webhooks, e-mails ou notificações push (simuladas) para o cliente PJ.

---

## Decisões de Arquitetura e Trade-offs
- **SQS/SNS vs Kafka:** Em um ecossistema nativo AWS focado em orquestração de pagamentos com *Step Functions*, o SQS oferece integração direta, gerenciamento nativo de *Dead Letter Queues* (DLQ) e menor sobrecarga operacional (*serverless*). O Kafka seria ideal para *event sourcing* puro ou streaming de altíssimo throughput contínuo, mas para orquestrar estados e retries pontuais, a dupla SQS + Step Functions entrega resiliência com menor custo.
- **Step Functions:** Utilizado para coordenar fluxos longos, lidando com *retries*, *timeouts* e o padrão SAGA (compensação) em caso de falha na liquidação contábil.

---

## Práticas de Engenharia e Cultura de Mentoria
A qualidade do software reflete a cultura do time. Este repositório adota práticas focadas em repasse contínuo de conhecimento e excelência técnica:
- **Code Reviews Estruturados:** Foco em capacitação prática. PRs exigem contexto claro ("O quê", "Por quê", "Como testar").
- **Quality Gates:** Integração com SonarQube no CI para bloquear PRs com cobertura de testes inferior a 80% ou *code smells*.
- **Testes:** Pirâmide rigorosa com JUnit 5 e Testcontainers para integração real com o banco de dados e mensageria local (LocalStack).