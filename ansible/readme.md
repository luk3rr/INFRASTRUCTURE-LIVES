# Automação de Homelab com Ansible ⚙️

Este diretório contém a configuração completa do Ansible para gerenciar os serviços do homelab, incluindo AdGuard, Nginx Proxy Manager, GitLab e backups centralizados com Restic.

O projeto é projetado para ser modular e idempotente, permitindo uma configuração rápida, consistente e repetível de novos serviços.

---
## 🚀 Começando

Para configurar um novo ambiente do zero, basta executar o script de setup inicial.

### 1. Configuração Inicial do Ambiente
O script `local_setup.sh` prepara sua máquina local (o "controller" do Ansible) com todas as dependências necessárias, cria o usuário de backup e gera um arquivo de segredos criptografado.

▶️ Execute no seu terminal:
```bash
bash local_setup.sh
```
O script é interativo e irá guiá-lo na criação das senhas necessárias. Ao final, ele instruirá como copiar sua chave SSH para os hosts remotos.

### 2. Edição do Inventário
O arquivo `inventory.ini` é o mapa da sua infraestrutura. Antes de rodar qualquer playbook, certifique-se de que os IPs e variáveis de cada host estão corretos.

**Exemplo:**
```ini
[lxc_containers]
adguard ansible_host=192.168.1.102 backup_path=/opt/AdGuardHome/ ...
npm ansible_host=192.168.1.103 backup_path='/data/ /etc/letsencrypt/' ...
gitlab-runner ansible_host=192.168.1.111 ...

[vms]
gitlab ansible_host=192.168.1.110 backup_path='/var/opt/gitlab/backups/ /etc/gitlab/' ...
```

---
## 🏗️ Estrutura do Projeto

* **`playbooks/`**: Contém os playbooks do Ansible. Cada arquivo é focado em uma única tarefa (ex: `adguard.yml`, `npm.yml`, `backup.yml`).
* **`roles/`**: Contém a lógica de automação reutilizável. Cada `role` é responsável por configurar um serviço específico (ex: `gitlab`, `restic-client`).
* **`group_vars/`**: Armazena as variáveis. O arquivo `secrets.yml` (criptografado) contém senhas e tokens
* **`inventory.ini`**: Lista de todos os seus servidores (VMs e containers).
* **`orchestrator.sh` e outros scripts `.sh`**: Ferramentas de alto nível para simplificar a execução dos playbooks.

---
## 🛠️ Scripts de Orquestração

Em vez de chamar `ansible-playbook` diretamente, use os seguintes scripts para as operações do dia a dia.

### `orchestrator.sh`
Use este script para instalar novos serviços nos seus hosts.

▶️ **Como usar:**
```bash
bash orquestrator.sh
```
O script apresentará um menu interativo onde você poderá escolher instalar um serviço específico (`adguard`, `npm`, `gitlab`, etc.) ou todos de uma vez.

**Para adicionar um novo serviço à automação:**
1.  Crie o playbook correspondente (ex: `playbooks/novo-servico.yml`).
2.  Adicione o nome do playbook (sem a extensão `.yml`) à lista `SERVICE_PLAYBOOKS` dentro do script `orchestrator.sh`.

### `backup_ops.sh`
Use este script para gerenciar o ciclo de vida dos backups (configurar, fazer backup, listar, restaurar).

▶️ **Como usar:**
```bash
bash backup_ops.sh
```

O script apresentará um menu para:
* **Setup Backup Client(s):** Prepara um ou todos os hosts para serem incluídos no sistema de backup (instala o Restic, configura as chaves SSH, etc.).
* **Backup All Services:** Executa o backup de todos os serviços definidos no inventário.
* **List Snapshots for a Service:** Permite escolher um serviço e ver uma lista de todos os seus backups disponíveis.
* **Restore a Service:** Inicia um guia interativo para restaurar um backup específico para um diretório temporário em um host.