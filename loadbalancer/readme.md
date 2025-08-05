# IPs reservados para serviços
- 192.168.1.231: PostgreSQL
- 192.168.1.232: Hotela
- 192.168.1.233: P2P Chat
- 192.168.1.234: Excalidraw

# Desabilitar o Load Balancer Padrão do K3s (ServiceLB)
## Contexto

O K3s, por padrão, inclui um controlador de serviços de Load Balancer chamado **Klipper**, que implementa a funcionalidade **ServiceLB**. Este controlador monitora a criação de serviços do tipo `LoadBalancer` e tenta expô-los criando um pod de balanceamento em um dos nós do cluster, usando um `HostPort` (vinculando a porta diretamente no nó).

Ao utilizar uma solução mais robusta e flexível como o **MetalLB**, o ServiceLB padrão não é mais necessário e **deve ser desabilitado**. Manter os dois ativos pode acarretar em conflitos, como:

* Pods `svclb-<nome-do-serviço>` ficando presos no estado `Pending` por não conseguirem a porta que desejam.
* Disputa por recursos e comportamento inesperado na exposição dos serviços.

## Desabilitando o ServiceLB

Existem duas maneiras principais de desabilitar o ServiceLB. A primeira, via arquivo de configuração, é a recomendada para novas instalações e para padronização. A segunda, alterando o serviço `systemd`, é uma alternativa prática para clusters já em execução.

### Método 1: Via Arquivo de Configuração `config.yaml` (Recomendado)

Este método é o ideal por ser declarativo e facilitar a automação e o gerenciamento do cluster.

1.  **Localize ou crie o arquivo de configuração do K3s.** O local padrão é `/etc/rancher/k3s/config.yaml`. Se o diretório ou o arquivo não existirem, você pode criá-los.

    ```bash
    # Se necessário, crie o diretório
    sudo mkdir -p /etc/rancher/k3s/

    # Crie ou edite o arquivo
    sudo nvim /etc/rancher/k3s/config.yaml
    ```

2.  **Adicione a diretiva para desabilitar o ServiceLB.** Insira o seguinte conteúdo no arquivo:

    ```yaml
    # /etc/rancher/k3s/config.yaml
    disable:
      - servicelb
    ```

3.  **Reinicie o serviço do K3s** para que a nova configuração seja aplicada.

    ```bash
    sudo systemctl restart k3s
    ```

### Método 2: Via Parâmetro de Linha de Comando (Para Clusters Existentes)

Se o seu cluster K3s foi instalado sem um `config.yaml` e é gerenciado pelo `systemd`, você pode desabilitar o ServiceLB diretamente no arquivo de serviço.

1.  **Edite o arquivo de serviço do K3s.**

    ```bash
    sudo nvim /etc/systemd/system/k3s.service
    ```

2.  **Modifique a linha `ExecStart`** para incluir a flag `--disable servicelb`.

    * **Exemplo ANTES:**

      ```
      ExecStart=/usr/local/bin/k3s server
      ```

    * **Exemplo DEPOIS:**

      ```
      ExecStart=/usr/local/bin/k3s server --disable servicelb
      ```

3.  **Recarregue a configuração do `systemd` e reinicie o K3s.** É crucial executar `daemon-reload` para que o `systemd` leia a alteração no arquivo de serviço antes de reiniciar.

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl restart k3s
    ```

## Verificação

Após reiniciar o K3s usando um dos métodos acima, você pode verificar se o ServiceLB foi realmente desativado.

1.  **Crie ou recrie um serviço** do tipo `LoadBalancer`.

2.  **Verifique se o DaemonSet ou os pods do `svclb` não são mais criados** no namespace `kube-system`. O comando abaixo não deve retornar nenhum recurso relacionado ao ServiceLB.

    ```bash
    # Este comando não deve mais encontrar o DaemonSet que cria os pods do ServiceLB
    kubectl get daemonset -n kube-system -l app=svclb

    # Ou verifique diretamente se os pods não foram criados
    kubectl get pods -n kube-system | grep svclb
    ```

3.  **Confirme que o MetalLB atribuiu o IP externo** ao seu serviço.

    ```bash
    kubectl get service <nome-do-seu-servico> -n <seu-namespace>
    ```

Com isso, o MetalLB passa a ser o único responsável por gerenciar os serviços `LoadBalancer`, garantindo um ambiente estável e sem conflitos.
