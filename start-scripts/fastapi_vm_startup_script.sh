#!/bin/bash

echo "Inicializando a implementação do projeto da FastAPI"
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
sudo unzip /opt/stargate_folder.zip 'fastapi_gunicorn_uvicorn_docker/*' -d /opt
cd /opt/fastapi_gunicorn_uvicorn_docker

echo "Buscando e salvando os IPs internos de todas as máquinas"
sudo curl http://metadata.google.internal/computeMetadata/v1/instance/name -H Metadata-Flavor:Google -O
sudo gcloud compute instances list --filter="name ~ $(cat name)" --format='get(networkInterfaces[0].networkIP)' > kafka_internal_ip.txt
sudo gcloud compute instances list --filter="name ~ $kafka-zookeeper-*" --flatten networkInterfaces[].accessConfigs[] --format="value(networkInterfaces.networkIP)" > kafka_instances_ips.txt
sudo gcloud compute project-info describe --format="value[separator='\n'](commonInstanceMetadata.items[].key,commonInstanceMetadata.items[].value)" > project_metadata.txt

echo "Armazenando os metadados do projeto e ips dos brokers de Kafka dinamicamente no arquivo .env"
sudo chmod -R 777 get_ips_and_metadata_script.sh
./get_ips_and_metadata_script.sh
sudo mv /opt/fastapi_gunicorn_uvicorn_docker/app/.env.example /opt/fastapi_gunicorn_uvicorn_docker/app/.env
sudo chmod -R 777 /opt/fastapi_gunicorn_uvicorn_docker/app/.env
sudo gsutil cp /opt/fastapi_gunicorn_uvicorn_docker/app/.env gs://$(cat stargate_bucket_name.txt)

echo "Startando o serviço da FastAPI"
sudo docker build -t fastapi_kafka_producer_image .
sudo docker run -d --restart unless-stopped --name fastapi_kafka_producer_container -p 80:80 fastapi_kafka_producer_image

echo "Apagando os arquivos baixados"
sudo rm -rf /opt/stargate_folder.zip
sudo rm -rf /opt/fastapi_gunicorn_uvicorn_docker/get_ips_and_metadata_script.sh
sudo rm -rf /opt/fastapi_gunicorn_uvicorn_docker/kafka_*
sudo rm -rf /opt/fastapi_gunicorn_uvicorn_docker/project_metadata.txt
sudo rm -rf /opt/fastapi_gunicorn_uvicorn_docker/name