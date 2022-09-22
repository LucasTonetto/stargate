i=1
echo "global:" >> /opt/kafka_test_monitoring/prometheus/prometheus.yml
echo "  scrape_interval: 5s" >> /opt/kafka_test_monitoring/prometheus/prometheus.yml
echo "  evaluation_interval: 5s" >> /opt/kafka_test_monitoring/prometheus/prometheus.yml
echo "scrape_configs:" >> /opt/kafka_test_monitoring/prometheus/prometheus.yml
echo "  - job_name: 'kafka'" >> /opt/kafka_test_monitoring/prometheus/prometheus.yml
echo "    static_configs:" >> /opt/kafka_test_monitoring/prometheus/prometheus.yml
echo "      - targets:" >> /opt/kafka_test_monitoring/prometheus/prometheus.yml
for IP in $(cat kafka_instances_ips.txt);
do
        echo "          - '${IP}:8080'" >> /opt/kafka_test_monitoring/prometheus/prometheus.yml
        i=$((i+1))
done