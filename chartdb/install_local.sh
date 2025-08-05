#!/bin/bash

# =======================================================================
# SCRIPT DE EXECUÇÃO LOCAL DO CHART-DB
#
# O que ele faz:
# 1. Compila o projeto Chart-DB na sua máquina local.
# 2. Instala as dependências necessárias localmente (Node.js e 'serve').
# 3. Inicia o serviço na sua máquina na porta 8080.
#
# Execute este script na sua máquina pessoal.
# =======================================================================

# -- Encerra o script imediatamente se qualquer comando falhar --
set -e

PROJECT_PATH="/tmp/chart-db"

echo "==============================================="
echo "### ETAPA 1: Compilando o projeto localmente..."
echo "==============================================="

# Navega para a pasta /tmp para não poluir outros diretórios
cd /tmp

if [ ! -d "chart-db" ]; then
    echo "--> Clonando o repositório de chart-db..."
    git clone https://github.com/chartdb/chartdb.git chart-db
fi

# Entra no diretório do projeto
cd "$PROJECT_PATH"

echo "--> Instalando dependências (npm install)... Isso pode levar um minuto."
npm install

echo "--> Compilando para produção (npm run build)..."
npm run build

echo "--> Build concluído. A pasta 'dist' foi criada em ${PROJECT_PATH}."
echo

echo "====================================================================="
echo "### ETAPA 2: Instalando dependências para execução local..."
echo "====================================================================="

# Verifica se o Node.js está instalado. Se não, tenta instalar.
# NOTA: O comando abaixo pode exigir 'sudo' e assume um sistema Debian/Ubuntu.
# Se você usa outro sistema (Fedora, Arch, macOS), instale Node.js com seu
# gerenciador de pacotes (dnf, pacman, brew).
if ! command -v node &> /dev/null; then
    echo "--> Node.js não encontrado. Tentando instalar..."
    # A linha abaixo precisa de privilégios de root (sudo)
    sudo apt-get update > /dev/null
    sudo apt-get install -y curl > /dev/null
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash - > /dev/null
    sudo apt-get install -y nodejs > /dev/null
    echo "--> Node.js instalado."
fi

# Instala o pacote 'serve' globalmente para servir os arquivos estáticos
# NOTA: O comando 'npm install -g' geralmente requer 'sudo'.
echo "--> Instalando o servidor 'serve' globalmente (pode pedir senha)..."
if ! command -v serve &> /dev/null; then
    sudo npm install -g serve
else
    echo "--> O pacote 'serve' já está instalado."
fi

echo "--> Dependências locais prontas."
echo

echo "======================================================="
echo "### ETAPA 3: Iniciando o serviço localmente..."
echo "======================================================="

echo "--> O serviço será iniciado a partir do diretório: $(pwd)"
echo "--> Servindo a pasta 'dist' na porta 8080."
echo
echo "#####################################################################"
echo "### O Chart-DB agora está rodando localmente!"
echo "###"
echo "### Acesse em seu navegador: http://localhost:8080"
echo "###"
echo "### Para parar o serviço, pressione CTRL+C neste terminal."
echo "#####################################################################"
echo

# Inicia o servidor. Ele ficará em execução no terminal.
serve -s dist -l 8080