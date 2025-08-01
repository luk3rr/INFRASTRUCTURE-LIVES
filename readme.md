<p align="center" width="100%">
  <img align="center" width="30%" src="./docs/img/logo.png"> 
</p>

# 🏗️ Infraestrutura do Homelab

O objetivo deste projeto é centralizar e gerenciar todas as configurações dos meus serviços e da minha infraestrutura, aplicando práticas de **Infraestrutura como Código (IaC)**.

Este repositório é a fonte da verdade para o estado desejado de todos os componentes, permitindo provisionamento, configuração e manutenção de forma automatizada e consistente.

---

### 🗺️ Estrutura de Diretórios

Cada diretório na raiz do projeto representa um componente, serviço ou aspecto lógico da infraestrutura.

* `📁 database`
  Contém scripts de inicialização, schemas (DDL) e configurações para os bancos de dados usados pelos serviços (ex: PostgreSQL, MySQL, Redis).

* `📁 docs`
  Documentação geral do projeto, diagramas de arquitetura, guias e anotações importantes sobre a configuração e a topologia da rede.

* `📁 gitlab`
  Arquivos de configuração da instância principal do GitLab (`gitlab.rb`) e dos seus runners (`config.toml`).

* `📁 loadbalancer`
  Configurações do balanceador de carga e reverse proxy (ex: Nginx, Traefik, HAProxy), responsável por direcionar o tráfego para os serviços corretos.

* `📁 pipeline`
  Definições e templates para os pipelines de CI/CD do GitLab (`.gitlab-ci.yml`), que automatizam o build, teste e deploy de aplicações.

* `📁 scripts`
  Coleção de scripts utilitários para automação de tarefas rotineiras, como backups, atualizações e manutenções gerais.

* `📁 serviceaccount`
  Manifestos e configurações para a criação de contas de serviço, que são usadas por aplicações e pipelines para interagir com outras APIs de forma segura.

* `📁 vault`
  Políticas (policies), configurações e métodos de autenticação para o [HashiCorp Vault](https://www.vaultproject.io/), o cofre central para gerenciamento de segredos (secrets), tokens e senhas.

* `📁 terraform`
  Scripts e módulos do Terraform para provisionamento da infraestrutura do homelab.

* `📁 ansible`
  Playbooks e roles do Ansible para configuração e gerenciamento de servidores, serviços e aplicações.