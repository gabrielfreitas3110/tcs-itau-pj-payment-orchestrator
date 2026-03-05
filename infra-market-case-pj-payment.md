# Infraestrutura, DevOps e Dados — AWS & IaC

## Objetivo
Provisionar via código (IaC) todo o ecossistema distribuído de pagamentos, garantindo alta disponibilidade, segurança, governança de dados analíticos e observabilidade de ponta a ponta.

---

## Provisionamento com Terraform (IaC)
Toda a infraestrutura é declarada em módulos reutilizáveis, seguindo o princípio de *Least Privilege* no IAM.
- **Networking:** VPC isolada, subnets públicas para o API Gateway/ALB, subnets privadas para computação e banco de dados, e NAT Gateways.
- **Compute:** Amazon ECS (Fargate) para os microsserviços Java/Kotlin e AWS Lambda para funções auxiliares e âncoras do Step Functions.
- **Armazenamento e Mensageria:** - Amazon Aurora Serverless (PostgreSQL) para consistência ACID.
  - DynamoDB com criptografia em repouso (KMS) para logs rápidos do antifraude.
  - Filas SQS configuradas com *Redrive Policy* para DLQs e alarmes de profundidade de fila.
- **Orquestração:** Definição da State Machine do AWS Step Functions declarada em código nativo (ASL) via Terraform.

---

## Esteira de CI/CD (DevSecOps)
Pipelines implementados via GitHub Actions para garantir entregas contínuas e seguras:
1. **Lint & Tests:** Execução automatizada da suíte de testes.
2. **Code Quality & Security:** Scan estático via SonarCloud e verificação de vulnerabilidades em dependências (SCA).
3. **Build & Container Registry:** Construção das imagens Docker e upload para o Amazon ECR.
4. **Terraform Plan/Apply:** Validação das mudanças de infraestrutura. O `terraform apply` em produção exige aprovação manual (*approval gates*).
5. **Deploy Automático:** Atualização das *task definitions* no ECS de forma *rolling update* (zero downtime).

---

## Observabilidade e Monitoramento
Monitoramento proativo e centralizado para sistemas de missão crítica.
- **Datadog APM:** Tracing distribuído ponta a ponta. Um `trace_id` gerado no API Gateway é injetado nos headers, passa pelos serviços Java, cruza as filas SQS e chega ao serviço Python de fraude, permitindo visibilidade total do gargalo.
- **Logs Estruturados:** Aplicações cospem logs em formato JSON, ingeridos diretamente no CloudWatch e redirecionados para o Datadog.
- **Métricas e Alarmes de Negócio:**
  - P95/P99 de latência na autorização de pagamentos.
  - Taxa de conversão do antifraude.
  - **Alarmes Críticos:** DLQ recebendo mensagens (`ApproximateNumberOfMessagesVisible > 0`) e consumo excessivo de CPU/Memória no ECS.

---

## Engenharia de Dados e Analytics (AWS Glue)
Arquitetura preparada para separar o processamento analítico (OLAP) do banco transacional (OLTP).
- **Pipeline de Extração:** Jobs do AWS Glue (em PySpark) ou exportação nativa via S3, retirando dados do Aurora e DynamoDB em janelas de baixa utilização.
- **Transformação:** Dados são limpos, particionados e salvos em buckets Amazon S3 no formato colunar Parquet.
- **Consumo:** Disponibilização via Amazon Athena para times de backoffice gerarem relatórios financeiros, auditorias de compliance e levantamento de features para re-treino do modelo de IA antifraude.