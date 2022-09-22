######################################################
# Variáveis gerais do projeto
######################################################

variable "project_id" {
  description = "Insira o ID do projeto no Google Cloud Platform"
  type        = string
  default     = "dp6-stargate"
}

variable "project_name" {
  description = "Insira o ID do projeto no Google Cloud Platform"
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

variable "bucket_name" {
  description = "Insira o nome do bucket"
  default     = "bucket_stargate"
}

variable "network" {
  description = "Insira a network utilizada"
  default     = "default"
}

variable "service_account_email" {
  description = "Insira o email de uma conta de serviço no formato service-account@project-id.iam.gserviceaccount.com"
  default     = "testeterraformstargate@dp6-stargate.iam.gserviceaccount.com"
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
  default     = "e2-standard-2"
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
  default     = ["http-server", "https-server", "fastapi-8000"]
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
  default     = "e2-standard-2"
}

variable "kafka_disk_size" {
  description = "Insira a capacidade de disco de cada máquina de Kafka"
  type        = number
  default     = 100
}

variable "kafka_disk_type" {
  description = "Insira a capacidade de disco de cada máquina de Kafka"
  type        = string
  default     = "pd-ssd"
}

variable "kafka_network_tags" {
  description = "Insira a lista de tags das regras de Firewall de cada máquina de Kafka"
  type        = list
  default     = ["http-server", "https-server", "kafka-broker-29092-jmx-8080"]
}

######################################################
# Variáveis do DataProc pro Spark
######################################################

variable "spark_name_prefix" {
  description = "Insira o prefixo do nome das máquinas e do cluster de Kafka"
  type        = string
  default     = "spark"
}

variable "spark_machine_number" {
  description = "Insira a quantidade de máquinas do DataProc do Spark"
  type        = number
  default     = 3
}

variable "spark_machine_type" {
  description = "Insira o tipo das máquinas do DataProc do Spark"
  type        = string
  default     = "n1-standard-2" 
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
  default     = "e2-standard-2"
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

variable "domain" {
  description = "Insira o nome criado para o load balancing"
  type        = list
  default     = ["fastapi-kafka-stargate-v2.com"] 
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
  default     = ["9000", "3000"]
}