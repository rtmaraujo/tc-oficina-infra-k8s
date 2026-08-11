#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y curl awscli

export AWS_ACCESS_KEY_ID="${ecr_access_key}"
export AWS_SECRET_ACCESS_KEY="${ecr_secret_key}"
export AWS_SESSION_TOKEN="${ecr_session_token}"
export AWS_DEFAULT_REGION="${region}"

ECR_TOKEN=$(aws ecr get-login-password --region "${region}")

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

# Junta o no worker ao cluster k3s (server privado 10.0.0.10:6443)
export K3S_TOKEN="${k3s_token}"
export K3S_URL="https://${server_private_ip}:6443"
curl -sfL https://get.k3s.io | sh -