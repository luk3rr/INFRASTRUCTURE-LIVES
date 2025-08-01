# Infraestrutura com Terraform e Proxmox 

Este projeto provisiona uma infraestrutura completa no Proxmox VE utilizando Terraform. Ele é projetado para ser modular e facilmente extensível.

---

### ## 1. Pré-requisitos e Instalação

O primeiro passo é preparar seu ambiente local. O script `local_setup.sh` foi criado para instalar o Terraform e outras dependências necessárias.

▶️ Rode o seguinte comando no seu terminal:
```bash
bash local_setup.sh
```

---

### ## 2. Configuração do Ambiente

A autenticação com a API do Proxmox e outras variáveis sensíveis são gerenciadas através de variáveis de ambiente.

1.  **Crie seu Token de API no Proxmox:**
    * Na interface do Proxmox, vá para **Datacenter -> Permissions -> API Tokens**.
    * Clique em `Add`, selecione um usuário (como `root@pam`), dê um ID para o token (ex: `terraform`) e desmarque a opção `Privilege Separation`.
    * **IMPORTANTE:** Copie o **Token ID** e o **Secret** gerados. O segredo só é exibido uma vez.

2.  **Crie o arquivo `.env`:**
    * Copie o conteúdo abaixo para um novo arquivo chamado `.env` na raiz do projeto.
    * Preencha os valores que você acabou de criar no Proxmox e suas outras informações.

    ```bash
    # Arquivo: .env
    
    export TF_VAR_proxmox_api_url="https://SEU_IP_PROXMOX:8006/api2/json"
    export TF_VAR_pm_api_token_id="SEU_TOKEN_ID_AQUI"
    export TF_VAR_pm_api_token_secret="SEU_TOKEN_SECRET_AQUI"
    export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub) ou sua chave SSH pública aqui"
    export TF_VAR_default_lxc_password="SENHA_FORTE_AQUI"
    ```

3.  **Carregue as Variáveis de Ambiente:**
    * Antes de usar o Terraform, você precisa carregar essas variáveis na sua sessão do terminal.

    ▶️ Rode o comando:
    ```bash
    source .env
    ```
    **Atenção:** Você precisa rodar este comando toda vez que abrir um novo terminal para trabalhar no projeto.

---

### ## 3. Executando o Terraform

Com o ambiente configurado, você pode provisionar a infraestrutura.

1.  **Inicializar o Terraform:**
    * Este comando prepara seu projeto, baixando os provedores e módulos necessários.

    ▶️ Rode o comando:
    ```bash
    terraform init
    ```

2.  **Planejar as Mudanças:**
    * O Terraform irá mostrar um plano de execução detalhado com todos os recursos que serão criados, alterados ou destruídos. Revise o plano com atenção.

    ▶️ Rode o comando:
    ```bash
    terraform plan
    ```

3.  **Aplicar as Mudanças:**
    * Se o plano estiver correto, aplique as mudanças para criar a infraestrutura no Proxmox.

    ▶️ Rode o comando:
    ```bash
    terraform apply
    ```

O Terraform pedirá uma confirmação final. Digite `yes` e pressione Enter para começar o provisionamento.