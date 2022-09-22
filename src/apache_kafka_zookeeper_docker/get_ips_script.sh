i=1
ZOOKEEPER_SERVERS=""
KAFKA_ZOOKEEPER_CONNECT=""
KAFKA_INTERNAL_VM=$(cat kafka_internal_ip.txt)
for IP in $(cat kafka_instances_ips.txt);
do
        echo "KAFKA_VM_IP_${i}=${IP}" >> /opt/apache_kafka_zookeeper_docker/.env
        if [[ "$KAFKA_INTERNAL_VM" == "$IP" ]]
        then
                echo "KAFKA_BROKER_ID=${i}" >> /opt/apache_kafka_zookeeper_docker/.env
                echo "ZOOKEEPER_SERVER_ID=${i}" >> /opt/apache_kafka_zookeeper_docker/.env
        fi
        ZOOKEEPER_SERVERS+="${IP}:2888:3888;"
        KAFKA_ZOOKEEPER_CONNECT+="${IP}:2181,"
        i=$((i+1))
done
ZOOKEEPER_SERVERS=${ZOOKEEPER_SERVERS::-1}
KAFKA_ZOOKEEPER_CONNECT=${KAFKA_ZOOKEEPER_CONNECT::-1}
echo "KAFKA_INTERNAL_VM=$(cat kafka_internal_ip.txt)" >> /opt/apache_kafka_zookeeper_docker/.env
printf "ZOOKEEPER_SERVERS=\'$ZOOKEEPER_SERVERS\'" >> /opt/apache_kafka_zookeeper_docker/.env
printf "\nKAFKA_ZOOKEEPER_CONNECT=\'$KAFKA_ZOOKEEPER_CONNECT\'" >> /opt/apache_kafka_zookeeper_docker/.env