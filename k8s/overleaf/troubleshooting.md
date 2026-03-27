# Overleaf - Troubleshooting

## Problema: HTTP 500 ao fazer push da imagem para o GitLab Container Registry

### Sintoma

O `docker push` da imagem do Overleaf (~4GB+ devido ao TeX Live completo) falhava com:

```
127392bafa02: Retrying in 5 seconds
...
received unexpected HTTP status: 500 Internal Server Error
```

Todas as layers pequenas eram enviadas com sucesso (`Layer already exists` ou `Pushed`), mas a layer grande do TeX Live ficava em retry infinito até retornar erro 500.

### Causa Raiz

O tráfego passa por dois proxies reversos antes de chegar ao registry:

```
Docker client → NPM (192.168.1.103:443) → GitLab NGINX (:5050) → Registry (:5000)
```

O **NGINX Proxy Manager (NPM)** não tinha configurações adequadas para streaming de uploads grandes. Sem `proxy_http_version 1.1`, o NGINX usa HTTP/1.0 e **força o buffering completo** da requisição, ignorando `proxy_request_buffering off`. Com uma layer de ~4GB, isso causava timeout e erro 500.

Referência: [GitLab Issue #38678](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/38678)

### Solução

#### 1. NGINX Proxy Manager (NPM)

Na UI do NPM, no proxy host `registry.gitlab.luk3rr.com`, aba **Advanced**, adicionar:

```nginx
client_max_body_size 0;
chunked_transfer_encoding on;
proxy_http_version 1.1;
proxy_buffering off;
proxy_request_buffering off;
proxy_read_timeout 900;
proxy_connect_timeout 900;
proxy_send_timeout 900;
```

#### 2. GitLab (`gitlab.rb`)

As seguintes configurações foram adicionadas ao template `ansible/roles/gitlab/templates/gitlab.rb.j2`:

```ruby
# Registry
registry['validation_enabled'] = true
registry['storage'] = {
  'filesystem' => {
    'rootdirectory' => '/var/opt/gitlab/gitlab-rails/shared/registry',
    'maxthreads' => 100
  },
  'maintenance' => {
    'uploadpurging' => {
      'enabled' => true,
      'age' => '168h',
      'interval' => '24h',
      'dryrun' => false
    }
  }
}

# NGINX principal
nginx['client_max_body_size'] = '0'

# Registry NGINX
registry_nginx['client_max_body_size'] = '0'
registry_nginx['proxy_read_timeout'] = 900
registry_nginx['proxy_connect_timeout'] = 900
registry_nginx['proxy_send_timeout'] = 900
registry_nginx['proxy_http_version'] = '1.1'
registry_nginx['proxy_buffering'] = 'off'
registry_nginx['proxy_request_buffering'] = 'off'
```

### Ponto Crítico

A configuração `proxy_http_version 1.1` é **obrigatória** em todos os proxies reversos no caminho. Sem ela, o chunked transfer encoding não funciona e o proxy bufferiza a requisição inteira antes de encaminhar, causando falha com layers grandes.