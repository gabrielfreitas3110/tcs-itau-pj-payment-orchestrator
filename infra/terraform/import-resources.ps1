# Import ALB Listeners e ECS Services existentes para o Terraform state
# Execute no diretorio infra/terraform

$ALB_ARN = "arn:aws:elasticloadbalancing:us-east-2:372110294246:loadbalancer/app/pjpay-dev-alb/a4333f6be9cb290f"
$CLUSTER = "pj-payment-orchestrator-cluster-dev"

# 1. Obter ARNs dos listeners
$Listeners = aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --region us-east-2 --query "Listeners[*].{Port:Port,Arn:ListenerArn}" --output json | ConvertFrom-Json

$Listener8000 = ($Listeners | Where-Object { $_.Port -eq 8000 }).Arn
$Listener8082 = ($Listeners | Where-Object { $_.Port -eq 8082 }).Arn
$Listener8083 = ($Listeners | Where-Object { $_.Port -eq 8083 }).Arn

Write-Host "Importando listeners..."
terraform import aws_lb_listener.fraud_service $Listener8000
terraform import aws_lb_listener.settlement_service $Listener8082
terraform import aws_lb_listener.notification_service $Listener8083

Write-Host "`nImportando ECS services..."
terraform import "aws_ecs_service.payment_service" "$CLUSTER/payment-service"
terraform import "aws_ecs_service.fraud_service" "$CLUSTER/fraud-service"
terraform import "aws_ecs_service.settlement_service" "$CLUSTER/settlement-service"
terraform import "aws_ecs_service.notification_service" "$CLUSTER/notification-service"

Write-Host "`nConcluido. Execute: terraform plan"