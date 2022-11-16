#!/bin/bash

echo "Inicializando a implementação do projeto de Apache Kafka e Apache Zookeeper"
echo "Atualizando repositórios"
sudo apt-get -y install
sudo apt-get upgrade

echo "Instalando Docker e outras dependências"
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common gnupg2 unzip
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "Clonando e extraindo o projeto do bucket"
sudo gcloud compute project-info describe --format="value[separator='\n'](commonInstanceMetadata.STARGATE_BUCKET_NAME)" > stargate_bucket_name.txt
sudo gcloud alpha storage cp gs://$(cat stargate_bucket_name.txt)/stargate_folder.zip ./opt
sudo unzip /opt/stargate_folder.zip 'apache_kafka_zookeeper_docker/*' -d /opt
cd /opt/apache_kafka_zookeeper_docker

echo "Buscando e salvando os IPs internos de todas as máquinas"
sudo curl http://metadata.google.internal/computeMetadata/v1/instance/name -H Metadata-Flavor:Google -O
sudo curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H Metadata-Flavor:Google | cut '-d/' -f4 > zone.txt
sudo gcloud compute instances list --filter="name ~ $(cat name)" --format='get(networkInterfaces[0].networkIP)' > kafka_internal_ip.txt
sudo gcloud compute instances list --filter="name ~ $kafka-zookeeper-*" --flatten networkInterfaces[].accessConfigs[] --format="value(networkInterfaces.networkIP)" > kafka_instances_ips.txt
sudo gcloud compute instance-groups list --filter="name ~ $kafka-zookeeper" --format='get(name)' > kafka_instance_group.txt

echo "Alterando o ip interno do grupo de Kafka para Stateful"
sudo gcloud beta compute instance-groups managed update $(cat kafka_instance_group.txt) --stateful-internal-ip enabled --zone $(cat zone.txt)

echo "Armazenando os ips dinamicamente no arquivo .env"
sudo chmod -R 777 get_ips_script.sh
./get_ips_script.sh

echo "Startando os brokers de Kafka e nodes do Zookeeper"
sudo docker compose up --build -d

echo "Apagando os arquivos baixados"
sudo rm -rf /opt/stargate_folder.zip
sudo rm -rf /opt/apache_kafka_zookeeper_docker/get_ips_script.sh
sudo rm -rf /opt/apache_kafka_zookeeper_docker/zone.txt
sudo rm -rf /opt/apache_kafka_zookeeper_docker/kafka_*
sudo rm -rf /opt/apache_kafka_zookeeper_docker/name