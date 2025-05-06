#!/bin/bash

install_terraform() {
    # Atualiza o cache do apt
    sudo apt update -y

    # Instala dependências necessárias
    sudo apt install -y gnupg software-properties-common curl

    # Adiciona a chave GPG oficial da HashiCorp
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    # Adiciona o repositório da HashiCorp
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

    # Atualiza o cache novamente
    sudo apt update -y

    # Instala o Terraform
    sudo apt install terraform -y
}

# Verifica se terraform está instalado
if ! command -v terraform &> /dev/null; then
  install_terraform
fi

WORKDIR="."

cd "$WORKDIR" || { echo "Diretório $WORKDIR não encontrado!"; exit 1; }

echo "Iniciando..."

terraform init -input=false
if [ $? -ne 0 ]; then
  echo "Erro no terraform init"
  exit 1
fi

echo "Gerando plano..."
terraform plan -out=tfplan
if [ $? -ne 0 ]; then
  echo "Erro no terraform plan"
  exit 1
fi

echo "Aplicando mudanças..."
terraform apply -auto-approve tfplan
if [ $? -ne 0 ]; then
  echo "Erro no terraform apply"
  exit 1
fi

PUBLIC_IP=$(terraform output -raw public_ec2_ip)
PRIVATE_IPS=$(terraform output -raw private_ec2_ips)
DATABASE_IP=$(terraform output -raw private_database_ip)

PEM_KEY_PATH=$(find . -maxdepth 1 -type f -name "*.pem" | head -n 1)

if [ -z "$PEM_KEY_PATH" ]; then
    echo "Chave .pem não encontrada no diretório atual."
    exit 1
fi

echo "Caminho da chave .pem encontrado: $PEM_KEY_PATH"
chmod 400 "$PEM_KEY_PATH"


# Copiando a chame para a instancia
echo "Copiando a chave para EC2"
scp -i "$PEM_KEY_PATH" "$PEM_KEY_PATH" ubuntu@$PUBLIC_IP:~/.

# Conectando via SSH (se necessário)
echo "Conectando à EC2 pública via SSH..."
ssh -i "$PEM_KEY_PATH" ubuntu@$PUBLIC_IP << 'EOF'
    echo "INstalação do Docker"

    sudo apt update
    sudo apt install -y docker-compose

    ssh -o StrictHostKeyChecking=no -i "$PEM_KEY_PATH" ubuntu@$DATABASE_IP << DATABASE_EOF
        sudo apt update 
        sudo apt install -y docker-compose
        
        git clone https://github.com/Orderize/docker-s-repo.git

        cd docker-s-repo/database
        sudo docker-compose up -d
    DATABASE_EOF

    for PRIVATE_IP in $PRIVATE_IPS; do
        echo "Conectando a instância privada $PRIVATE_IP..."

        # Instalar Docker e Docker Compose nas instâncias privadas
        ssh -o StrictHostKeyChecking=no -i "$PEM_KEY_PATH" ubuntu@$PRIVATE_IP << PRIVATE_EOF
            sudo apt update 
            sudo apt install -y docker-compose
            
            git clone https://github.com/Orderize/docker-s-repo.git

            cd docker-s-repo/backend
            sudo docker-compose up -d
        PRIVATE_EOF
    done
EOF
