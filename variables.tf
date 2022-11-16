######################################################
# Variáveis gerais do projeto
######################################################

variable "project_id" {
  description = "Insira o ID do projeto a ser implementado o Stargate no Google Cloud Platform"
  type        = string
  default     = "raiadrogasil-280519"
}

variable "project_name" {
  description = "Insira o nome do projeto Stargate no Google Cloud Platform"
  type        = string
  default     = "stargate"
}

variable "region" {
  description = "Insira a região do projeto"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Insira a zona do projeto"
  type        = string
  default     = "us-central1-a"
}

variable "network" {
  description = "Insira a network utilizada"
  default     = "default"
}

variable "service_account_email" {
  description = "Insira o email de uma conta de serviço no formato service-account-name@project-id.iam.gserviceaccount.com"
  default     = "service-account@project-id.iam.gserviceaccount.com"
}

variable "allowed_hosts" {
  description = "Insira aqui o(s) domínio(s) da empresa"
  type = string
  default     = "['https://www.example.com', 'www.example.com']"
}

######################################################
# Variáveis do cluster de FastAPI
######################################################

variable "fastapi_name_prefix" {
  description = "Insira o prefixo do nome das máquinas e do cluster da FastAPI"
  type        = string
  default     = "fastapi-kafka-producer"
}

variable "fastapi_machine_number" {
  description = "Insira a quantidade de máquinas do cluster da FastAPI"
  type        = number
  default     = 3
}

variable "fastapi_machine_type" {
  description = "Insira o tipo de máquinas do cluster da FastAPI"
  type        = string
  #default     = "e2-micro"
  default     = "e2-small"
  #default     = "e2-medium"
  #default     = "e2-standard-2"
  #default     = "e2-standard-4"
}

variable "fastapi_disk_size" {
  description = "Insira a capacidade de disco de cada máquina da FastAPI"
  type        = number
  default     = 10
}

variable "fastapi_disk_type" {
  description = "Insira a capacidade de disco de cada máquina da FastAPI"
  type        = string
  default     = "pd-ssd"
}

variable "fastapi_network_tags" {
  description = "Insira a lista de tags das regras de Firewall de cada máquina de Kafka"
  type        = list
  default     = ["http-server", "https-server", "fastapi-8000", "allow-health-check"]
}

######################################################
# Variáveis do cluster de Apache Kafka
######################################################

variable "kafka_name_prefix" {
  description = "Insira o prefixo do nome das máquinas e do cluster de Kafka"
  type        = string
  default     = "kafka-zookeeper"
}

variable "kafka_machine_number" {
  description = "Insira a quantidade de máquinas do cluster de Kafka"
  type        = number
  default     = 3
}

variable "kafka_machine_type" {
  description = "Insira o tipo das máquinas do cluster de Kafka"
  type        = string
  #default     = "e2-micro"
  default     = "e2-small"
  #default     = "e2-medium"
  #default     = "e2-standard-2"
  #default     = "e2-standard-4"
}

variable "kafka_disk_size" {
  description = "Insira a capacidade de disco de cada máquina de Kafka"
  type        = number
  default     = 10
}

variable "kafka_disk_type" {
  description = "Insira a capacidade de disco de cada máquina de Kafka"
  type        = string
  default     = "pd-ssd"
}

variable "kafka_log_retention_hours" {
  description = "Por quanto tempo as mensagens ficarão armazenadas no Kafka"
  type        = number
  default     = 1
}

variable "kafka_network_tags" {
  description = "Insira a lista de tags das regras de Firewall de cada máquina de Kafka"
  type        = list
  default     = ["http-server", "https-server", "ssh","kafka-broker-29092-jmx-8080"]
}

variable "kafka_topic_app" {
  description = "Insira aqui o nome do tópico para app a ser usado no Kafka"
  type        = string
  default     = "stargate.app"
}

variable "kafka_topic_web" {
  description = "Insira aqui o nome do tópico para web a ser usado no Kafka"
  type        = string
  default     = "stargate.web"
}

######################################################
# Variáveis do DataProc pro Spark
######################################################

variable "spark_name_prefix" {
  description = "Insira o prefixo do nome das máquinas e do cluster de Kafka"
  type        = string
  default     = "spark"
}

variable "spark_master_machine_number" {
  description = "Insira a quantidade de máquinas do DataProc do Spark"
  type        = number
  default     = 1
}

variable "spark_worker_machine_number" {
  description = "Insira a quantidade de máquinas do DataProc do Spark"
  type        = number
  default     = 2
}

variable "spark_machine_type" {
  description = "Insira o tipo das máquinas do DataProc do Spark"
  type        = string
  #default     = "n1-custom-1-4096" # USD 112.02 - Job não foi enviada
  #default     = "n1-custom-2-4096" # USD 184.77 - Job quando foi enviada, apresentou muita falha
  default     = "n1-custom-1-6656" # USD 129.06 - Job enviada e sem erros nos testes iniciais
  #default     = "n1-standard-2" # USD 201.43 - Mínimo PERMITIDO pela interface da GCP
  #default     = "n1-standard-4" 
}

variable "spark_disk_size" {
  description = "Insira a capacidade de disco de cada máquina do Spark"
  type        = number
  default     = 100
}

variable "spark_disk_type" {
  description = "Insira a capacidade de disco de cada máquina do Spark"
  type        = string
  default     = "pd-ssd"
}

variable "spark_stargate_group" {
  description = "Insira o nome do Consumer Group que o Spark Consumer será inserido no Kafka"
  type        = string
  default     = "spark.stargate.group"
}

######################################################
# Variáveis da máquina de teste e monitoramento
######################################################

variable "kafka_test_monitoring_name_prefix" {
  description = "Insira o prefixo do nome da máquina de Teste e Monitoramento"
  type        = string
  default     = "kafka-test-and-monitoring"
}

variable "kafka_test_monitoring_machine_type" {
  description = "Insira o tipo da máquina de Teste e Monitoramento"
  type        = string
  #default     = "e2-micro"
  default     = "e2-small"
  #default     = "e2-medium"
  #default     = "e2-standard-2"
}

variable "kafka_test_monitoring_disk_size" {
  description = "Insira a capacidade de disco da máquina de Teste e Monitoramento"
  type        = number
  default     = 10
}

variable "kafka_test_monitoring_disk_type" {
  description = "Insira a capacidade de disco da máquina de Teste e Monitoramento"
  type        = string
  default     = "pd-standard"
}

variable "kafka_test_monitoring_network_tags" {
  description = "Insira a lista de tags das regras de Firewall da máquina de Teste e Monitoramento"
  type        = list
  default     = ["http-server", "https-server", "prometheus-9090-grafana-3000"]
}

######################################################
# Variáveis de Load Balancing e Cloud DNS
######################################################

variable "load_balancing_name" {
  description = "Insira o nome criado para o load balancing"
  type        = string
  default     = "fastapi-kafka" 
}

variable "fastapi_domain" {
  description = "Insira o domínio criado para a FastAPI sem o .com no final"
  type        = string
  default     = "stargate-rd" 
}

######################################################
# Variáveis de regras de firewall
######################################################

variable "fastapi_firewall_rule_name" {
  description = "Insira o nome da tag da regra de firewall das portas da FastAPI"
  type        = string
  default     = "fastapi-8000"
}

variable "fastapi_firewall_rule_port" {
  description = "Insira as portas da regra de firewall da FastAPI"
  type        = list
  default     = ["8000"]
}

variable "kafka_firewall_rule_name" {
  description = "Insira o nome da tag da regra de firewall das portas de Kafka, JMX e Zookeeper"
  type        = string
  default     = "kafka-broker-29092-jmx-8080-zookeeper-2181"
}

variable "kafka_firewall_rule_port" {
  description = "Insira as portas da regra de firewall de Kafka, JMX e Zookeeper"
  type        = list
  default     = ["9092", "8080", "2181"]
}

variable "test_monitoring_firewall_rule_name" {
  description = "Insira o nome da tag da regra de firewall das portas do Prometheus e Grafana"
  type        = string
  default     = "prometheus-9090-grafana-3000"
}

variable "test_monitoring_firewall_rule_port" {
  description = "Insira as portas da regra de firewall do Prometheus e do Grafana"
  type        = list
  default     = ["9090", "3000"]
}

######################################################
# Variáveis Big Query
######################################################

variable "bigquery_dataset" {
  description = "Insira o nome do dataset no Big Query"
  type        = string
  default     = "data_realtime"
}