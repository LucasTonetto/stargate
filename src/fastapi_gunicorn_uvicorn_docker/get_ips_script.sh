IPS=""
for IP in $(cat kafka_instances_ips.txt);
do
        IPS+="${IP}:9092,"
done
IPS=${IPS::-1}
printf "\nBOOTSTRAP_SERVERS=\"$IPS\"" >> /opt/fastapi_gunicorn_uvicorn_docker/app/.env.example
printf "\nVM_NAME=$(cat name)" >> /opt/fastapi_gunicorn_uvicorn_docker/app/.env.example