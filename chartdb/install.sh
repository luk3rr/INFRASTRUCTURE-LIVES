#!/bin/bash

# =============================================================================
# SCRIPT DE DEPLOY DO CHART-DB (Build Local, Deploy Remoto)
#
# O que ele faz:
# 1. Compila o projeto Chart-DB na sua máquina local.
# 2. Compacta apenas os arquivos de produção ('dist').
# 3. Conecta-se ao seu servidor via SSH.
# 4. No servidor, ele:
#    - Instala as dependências mínimas (Node.js e o servidor 'serve').
#    - Descompacta os arquivos de produção.
#    - Configura e inicia o serviço systemd.
#
# Execute este script na sua máquina pessoal, não no servidor.
# =============================================================================

# -- Encerra o script imediatamente se qualquer comando falhar --
set -e

REMOTE_USER="root"
REMOTE_HOST="ssh.chartdb.luk3rr.com"
REMOTE_PROJECT_PATH="/opt/chart-db"
REMOTE_TMP_FILE="/tmp/dist.tar.gz"

echo "==============================================="
echo "### ETAPA 1: Compilando o projeto localmente..."
echo "==============================================="

PROJECT_DIR="chart-db"

cd /tmp

if [ ! -d "$PROJECT_DIR" ]; then
    echo "--> Clonando o repositório de chart-db..."
    git clone https://github.com/chartdb/chartdb.git chart-db
fi

cd $PROJECT_DIR

echo "--> Instalando dependências (npm install)... Isso pode levar um minuto."
npm install

echo "--> Compilando para produção (npm run build)..."
npm run build

echo "--> Build concluído. A pasta 'dist' foi criada."
echo

echo "==========================================================="
echo "### ETAPA 2: Compactando e transferindo para o servidor..."
echo "==========================================================="

tar -czvf ../dist.tar.gz dist

cd ..

echo "--> Transferindo 'dist.tar.gz' para ${REMOTE_HOST}..."
scp dist.tar.gz ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_TMP_FILE}

rm dist.tar.gz

echo "--> Transferência concluída."
echo

echo "======================================================="
echo "### ETAPA 3: Conectando ao servidor para configurar..."
echo "======================================================="

ssh ${REMOTE_USER}@${REMOTE_HOST} bash -s <<EOF
    set -e

    echo "--- (EXECUTANDO NO SERVIDOR: ${REMOTE_HOST}) ---"

    echo "--> Etapa A: Instalando dependências mínimas (Node.js e serve)..."
    apt-get update > /dev/null
    apt-get install -y curl > /dev/null

    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null
        apt-get install -y nodejs > /dev/null
    fi

    npm install -g serve

    echo "--> Etapa B: Preparando os diretórios e descompactando..."
    mkdir -p ${REMOTE_PROJECT_PATH}

    rm -rf ${REMOTE_PROJECT_PATH}/dist

    tar -xzvf ${REMOTE_TMP_FILE} -C ${REMOTE_PROJECT_PATH}

    rm ${REMOTE_TMP_FILE}

    echo "--> Etapa C: Criando o serviço systemd..."
    cat <<EOT > /etc/systemd/system/chart-db.service
[Unit]
Description=Chart-DB Static Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${REMOTE_PROJECT_PATH}
ExecStart=/usr/bin/serve -s dist -l 8080
Restart=always

[Install]
WantedBy=multi-user.target
EOT

    echo "--> Etapa D: Habilitando e iniciando o serviço..."
    systemctl daemon-reload
    systemctl enable chart-db.service
    systemctl start chart-db.service

    echo "-------------------------------------------------------"
    echo "Instalação no servidor concluída!"
    echo "O chart-db deve estar acessível na porta 8080."
    echo "Verificando o status do serviço:"
    sleep 2
    systemctl status chart-db.service --no-pager
    echo "--- (DESCONECTANDO DO SERVIDOR) ---"
EOF

echo
echo "==============================================="
echo "PROCESSO FINALIZADO!"
echo "==============================================="
