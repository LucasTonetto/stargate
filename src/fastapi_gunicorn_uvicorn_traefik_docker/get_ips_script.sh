IPS=""
for IP in $(cat kafka_instances_ips.txt);
do
        IPS+="\"${IP}:9092\","
done
IPS=${IPS::-1}
echo "BOOTSTRAP_SERVERS=$IPS" >> /opt/fastapi_gunicorn_uvicorn_traefik_docker/app/.env.example
echo "KAFKA_INTERNAL_VM=$(cat kafka_internal_ip.txt)" >> /opt/fastapi_gunicorn_uvicorn_traefik_docker/app/.env.example