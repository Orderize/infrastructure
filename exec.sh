#!/bin/bash

set -e

# 1. Instalação do Terraform (como você já fez)
# 2. Terraform apply
terraform init -input=false
terraform apply -auto-approve

# 3. Pega IPs
PUBLIC_IP=$(terraform output -raw public_ip)
PRIVATE_IP=$(terraform output -raw private_ip)

# 4. Gera inventário
cat > inventory.ini <<EOF
[publicos]
publico1 ansible_host=$PUBLIC_IP

[privados]
privado1 ansible_host=$PRIVATE_IP ansible_ssh_common_args='-o ProxyJump=ubuntu@$PUBLIC_IP'
EOF

# 5. Executa Ansible
PEM_KEY_PATH=$(find . -maxdepth 1 -type f -name "*.pem" | head -n 1)
chmod 400 "$PEM_KEY_PATH"

ansible-playbook -i inventory.ini playbook.yml \
  --private-key "$PEM_KEY_PATH" \
  -u ubuntu
