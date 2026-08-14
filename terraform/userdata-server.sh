#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl unzip jq

# AWS CLI v2 (o pacote 'awscli' do apt nao existe no Ubuntu 24.04)
curl -sS https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/aws
/tmp/aws/aws/install

# Credenciais temporarias para gerar o token de login do ECR
export AWS_ACCESS_KEY_ID="${ecr_access_key}"
export AWS_SECRET_ACCESS_KEY="${ecr_secret_key}"
export AWS_SESSION_TOKEN="${ecr_session_token}"
export AWS_DEFAULT_REGION="${region}"

ECR_TOKEN=$(aws ecr get-login-password --region "${region}")

# Configura autenticacao do containerd (k3s) no ECR privado
mkdir -p /etc/rancher/k3s
cat > /etc/rancher/k3s/registries.yaml <<-EOF
mirrors:
  "${ecr_url}":
    endpoint:
      - "https://${ecr_url}"
configs:
  "${ecr_url}":
    auth:
      username: AWS
      password: "$${ECR_TOKEN}"
EOF

# Instala o no server (control plane) do k3s
#   - Traefik (API Gateway) e servicelb habilitados: ponto unico de entrada via
#     ingress (portas 80/443) e homologacao (8081/8443) configurados via HelmChartConfig
#   - metrics-server embutido habilita o HPA
export K3S_TOKEN="${k3s_token}"
export INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644"
curl -sfL https://get.k3s.io | sh -