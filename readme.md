<p align="center" width="100%">
  <img align="center" width="30%" src="./docs/img/logo.png"> 
</p>

# 🏗️ Homelab as Code

Este repositório contém toda a configuração da minha infraestrutura de homelab, gerenciada utilizando princípios de Infraestrutura como Código (IaC). O objetivo é manter uma fonte única da verdade para provisionar, configurar e gerenciar todos os serviços de forma automatizada, consistente e repetível.

O projeto utiliza uma combinação de Terraform para provisionamento da infraestrutura base (VMs e contêineres), Ansible para configuração de servidores e aplicações, e manifestos Kubernetes (K8s) para orquestração de serviços em contêineres.

---

### 🗺️ Estrutura de Diretórios
#### 📁 ansible
Contém os Playbooks e Roles do Ansible. É responsável pela configuração fina do sistema operacional, instalação de softwares e gerenciamento do estado das aplicações nos servidores e contêineres. É o "como" as coisas são configuradas.

#### 📁 terraform
Contém o código Terraform para o provisionamento declarativo da infraestrutura principal no Proxmox. Ele define "o que" deve existir: máquinas virtuais, contêineres LXC, suas configurações de hardware e rede.

#### 📁 k8s
Contém os manifestos Kubernetes (YAMLs) para implantar e gerenciar aplicações dentro do cluster K3s. Aqui são definidos Deployments, Services, Ingresses, Load Balancer e outras configurações de orquestração.

#### 📁 pipeline
Definições para os pipelines de CI/CD, que automatizam os processos de teste e deploy dos meus projetos no cluster K3s.

#### 📁 docs
Documentação do projeto, diagramas de arquitetura, imagens e anotações sobre a topologia da infraestrutura.
