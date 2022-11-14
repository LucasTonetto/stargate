echo "Buscando as informações do cluster de Kafka e passando para o .env..."
IPS=""
i=1
KAFKA_TOPIC_PARTITIONS=1
KAFKA_TOPIC_REPLICAS=1

for IP in $(cat kafka_instances_ips.txt);
do
        IPS+="${IP}:9092,"
        if [ $i -ge 3 ]
        then
                KAFKA_TOPIC_PARTITIONS=3
                KAFKA_TOPIC_REPLICAS=3
        fi
        i=$((i+1))
done
IPS=${IPS::-1}
printf "\nBOOTSTRAP_SERVERS=\"$IPS\"" >> /opt/fastapi_gunicorn_uvicorn_traefik_docker/app/.env.example
printf "\nVM_NAME=$(cat name)" >> /opt/fastapi_gunicorn_uvicorn_traefik_docker/app/.env.example
printf "\nKAFKA_TOPIC_PARTITIONS=$KAFKA_TOPIC_PARTITIONS" >> /opt/fastapi_gunicorn_uvicorn_traefik_docker/app/.env.example
printf "\nKAFKA_TOPIC_REPLICAS=$KAFKA_TOPIC_REPLICAS" >> /opt/fastapi_gunicorn_uvicorn_traefik_docker/app/.env.example

echo "Passando metadados do projeto pro .env..."
IFS=';'
key=$(sed -n 1p project_metadata.txt)
read -ra ARRAY_KEY <<< "$key"
value=$(sed -n 2p project_metadata.txt)
read -ra ARRAY_VALUE <<< "$value"
i=0
for i in "${!ARRAY_KEY[@]}"
do
        if [[ "${ARRAY_KEY[$i]}" == "ALLOWED_HOSTS" ]]
        then
        printf "\n${ARRAY_KEY[$i]}='${ARRAY_VALUE[$i]//\'/\"}'" >> /opt/fastapi_gunicorn_uvicorn_traefik_docker/app/.env
        else
        printf "\n${ARRAY_KEY[$i]}=${ARRAY_VALUE[$i]}" >> /opt/fastapi_gunicorn_uvicorn_traefik_docker/app/.env
        fi
done