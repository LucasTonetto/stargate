i=1
for IP in $(cat kafka_instances_ips.txt);
do
        echo "KAFKA_VM_IP_${i}=${IP}" >> .env
        i=$((i+1))
done