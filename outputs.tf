output "spark_job_command" {
    value = "gcloud dataproc jobs submit pyspark --cluster ${google_dataproc_cluster.stargate_cluster_stage.name} gs://${var.bucket_name}/main.py --region ${var.region} --properties spark.jars.packages=org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.3 --jars gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.24.2.jar"
    description = "Comando para startar a job de Spark"
}

output "fastapi_url" {
    value = "http://${google_compute_global_address.fastapi-kafka-stargate-address.address}/"
    description = "Acessar em aba anônima a documentação da FastAPI"
}

output "prometheus_url" {
    value = "http://${google_compute_instance.kafka_test_and_monitoring_instance.network_interface.0.access_config.0.nat_ip}:9090/"
    description = "Acessar Prometheus para verificar coleta de métricas do Kafka"
}

output "grafana_url" {
    value = "http://${google_compute_instance.kafka_test_and_monitoring_instance.network_interface.0.access_config.0.nat_ip}:3000/"
    description = "Acessar Grafana para acessar Dashboard de monitoramento do Kafka"
}
