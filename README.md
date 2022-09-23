# Stargate 2.0

<div align="center">
	<img src="https://raw.githubusercontent.com/DP6/templates-centro-de-inovacoes/main/public/images/centro_de_inovacao_dp6.png" height="100px" />
</div>
<div align="center">
    <img src="https://img.shields.io/codacy/grade/6276f660577e41e0a7b7e4605c4f0434">
    <img src="https://img.shields.io/codacy/coverage/6276f660577e41e0a7b7e4605c4f0434">
    <img src="https://img.shields.io/github/issues/DP6/penguin-adinfo">
	<img src="https://img.shields.io/github/license/DP6/penguin-adinfo">
</div>

### 🚧 Documentação em construção

O Stargate possibilita a consolidação de dados no BigQuery de maneira mais rápida que o usual (a tabela intraday do Google Analytics é exportada para o BigQuery em intervalos com horas de diferença), permitindo que os dados de navegação gerados nos sites e aplicativos sejam consumidos em um intervalo de tempo significativamente menor (o Stargate consolida os dados no BigQuery em questão de minutos).

## Como funciona?

1. O Stargate é iniciado através de uma requisição HTTPS do tipo POST com o dataLayer no body da requisição vinda do GTM, para um endpoint criado em uma api no framework web FastAPI escrita em Python.

2. Essa api, hospedada em um Compute Engine no GCP, funciona com um servidor HTTP WSGI chamado Gunicorn, responsável por distribuir as requisições em workers ASGI chamado Uvicorn.

3. O endpoint da API instância um Producer de Kafka, que irá escrever as mensagens em um tópico criado dentro dos servidores (ou brokers) no cluster do Apache Kafka. Esses brokers de Kafka são gerenciados por servidores (ou nodes) chamado de Apache Zookeeper, onde para cada broker de Kafka, terá um node de Zookeeper dentro do mesmo Compute Engine.

4. Um cluster máquinas no DataProc rodando uma job de Apache Spark, irá ser responsável em ler e efetuar as transformações/processamentos necessários dos os dados do tópico do Kafka em streaming através de sua biblioteca nátiva Structured Streaming.

5. Após ler, transformar e processar os dados, o Spark será o responsável por escrever os dados dentro do BigQuery.

![Diagrama da estrutura](stargate_pics\diagram.png)

## Principais propostas de valor

<!-- - Independência de qualquer programa para a abertura das planilhas durante o processo de parametrização, o que comumente compromete a performance pelo uso extensivo de fórmulas.
- Possibilidade do uso da API em planilhas, externalizando o processamento para uma transformação puramente sobre os dados.Controle de permissões com 3 níveis, cada qual incluindo os seguintes: Controle de **acessos**, edição de **configurações**, realização da **parametrização**.
- Os acessos podem ser divididos em grupos ou projetos, para que por exemplo diferentes agências possam todas ter seu nível de configuração, mas apenas para suas próprias campanhas.
- Escalabilidade de uso por suportar grandes tamanhos de arquivo e histórico.
-->

### 💻 Produtos do GCP

O Stargate pode ser implementado em diferentes provedores de nuvem ou em ambientes on-premise. Listaremos aqui sugestões de serviços do GCP que podem ser utilizados para complementar a infraestrutura da API.

- Compute Engine
- Managed Instance Group
- DataProc
- Cloud Load Balancing
- Cloud DNS

## 🚀 Instalação

Clone o projeto do github para sua máquina local

```console
git clone https://github.com/DP6/stargate.git
```

### Instalação GCP via Terraform

#### Pré-requisitos

1. [Google Cloud SDK](https://cloud.google.com/sdk/docs/install?hl=pt-br);
2. [Terraform](https://www.terraform.io/);
3. Habilitar o Compute Engine, Managed Instance Group, DataProc, Cloud Load Balancing, Cloud DNS, Firewall Rules (necessário ter um billing ativo), no GCP;
4. Criar o arquivo **gcp_key_terraform.json** contendo a chave json de uma conta de serviço GCP com as permissões necessárias para as subidas dos serviços via terraform;

#### Passos

1. Preencha corretamente o arquivo variables.tf com informações necessárias do projeto;

2. 
```
terraform init
terraform plan
terraform apply
```

### Instalação manual - GCP

[Codex - Implementação na GCP - versão 2.0](https://codex.dp6.io/books/stargate/chapter/implementacao-na-gcp-versao-20)

## 🤝 Como contribuir

Pull requests são bem-vindos! Nós vamos adorar ajuda para evoluir esse modulo. Sinta-se livre para navegar por issues abertas buscando por algo que possa fazer. Caso tenha uma nova feature ou bug, por favor abra uma nova issue para ser acompanhada pelo nosso time.

### Requisitos obrigatórios

Só serão aceitas contribuições que estiverem seguindo os seguintes requisitos:

- [Padrão de commit](https://www.conventionalcommits.org/en/v1.0.0/)
- [Padrão de criação de branches](https://www.atlassian.com/br/git/tutorials/comparing-workflows/gitflow-workflow)

### Documentação

## Suporte:

**DP6 Koopa-troopa Team**

_e-mail: <koopas@dp6.com.br>_

<img src="https://raw.githubusercontent.com/DP6/templates-centro-de-inovacoes/main/public/images/koopa.png" height="100px" width=50px/>
