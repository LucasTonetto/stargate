######################################################
# Configurações Cloud Storage
######################################################

resource "google_storage_bucket" "bucket_stargate" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true
  storage_class = "STANDARD"
  labels = {
    project     = "${var.project_name}"
    stargate    = var.bucket_name
  }
}

resource "google_storage_bucket_object" "static_spark_start_script" {
  name          = "spark_start_script.sh"
  source        = "src/apache_spark_streaming/spark_start_script.sh"
  bucket        = google_storage_bucket.bucket_stargate.name
}

data "archive_file" "zip_code" {
  type          = "zip"
  source_dir    = "src"
  output_path   = "src/zip/stargate_folder.zip"
}

resource "google_compute_project_metadata" "project_metadata" {
  metadata = {
    PROJECT_ID = var.project_id
    BIGQUERY_DATASET = var.bigquery_dataset
    ALLOWED_HOSTS = "${var.allowed_hosts}"
    BUCKET_NAME = var.bucket_name
    KAFKA_TOPIC_NAME = var.kafka_topic_name
    KAFKA_CONSUMER_GROUP = var.spark_stargate_group
  }
}


resource "google_storage_bucket_object" "static_stargate_src" {
  name          = "stargate_folder.zip"
  source        = "./src/zip/stargate_folder.zip"
  bucket        = google_storage_bucket.bucket_stargate.name
  depends_on    = [data.archive_file.zip_code, google_storage_bucket.bucket_stargate]
}

resource "google_storage_bucket_object" "static_spark_job" {
  name          = "main.py"
  source        = "src/apache_spark_streaming/main.py"
  content_type  = "text/x-python"
  bucket        = google_storage_bucket.bucket_stargate.name
}

######################################################
# Máquinas e Grupos - Apache Kafka + Zookeeper + Docker
######################################################

resource "google_compute_instance_template" "kafka_zookeeper_instance_template" {
  name                    = "${var.project_name}-${var.kafka_name_prefix}-instance-template"
  machine_type            = var.kafka_machine_type
  region                  = var.region

  // boot disk
  disk {
    // create a new boot disk from an image
    source_image          = "debian-cloud/debian-11"
    auto_delete           = true
    boot                  = true
    disk_size_gb          = var.kafka_disk_size
    disk_type             = var.kafka_disk_type
  }

  // networking
  network_interface {
    network               = var.network
    access_config {}
  }

  tags = var.kafka_network_tags

  metadata_startup_script = "${file("./start-scripts/kafka_zookeeper_vm_start_script.sh")}"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email                 = var.service_account_email
    scopes                = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on          = [google_storage_bucket.bucket_stargate, google_storage_bucket_object.static_stargate_src]
}

resource "google_compute_instance_group_manager" "kafka_zookeeper_instance_group_manager" {
  name                = "${var.project_name}-${var.kafka_name_prefix}-instance-group"
  base_instance_name  = "${var.project_name}-${var.kafka_name_prefix}-instance"
  zone                = var.zone
  target_size         = var.kafka_machine_number

  version {
    instance_template = google_compute_instance_template.kafka_zookeeper_instance_template.id
  }

  # stateful_disk {
  #   device_name       = "${var.project_name}-${var.kafka_name_prefix}-boot"
  # }

  depends_on          = [google_compute_instance_template.kafka_zookeeper_instance_template]

}

######################################################
# Máquinas e Grupos - FastAPI + Gunicorn + Uvicorn
######################################################

resource "google_compute_instance_template" "fastapi_kafka_producer_instance_template" {
  name                    = "${var.project_name}-${var.fastapi_name_prefix}-instance-template"
  machine_type            = var.fastapi_machine_type
  region                  = var.region

  // boot disk
  disk {
    // create a new boot disk from an image
    source_image          = "debian-cloud/debian-11"
    auto_delete           = true
    boot                  = true
    disk_size_gb          = var.fastapi_disk_size
    disk_type             = var.fastapi_disk_type
  }

  // networking
  network_interface {
    network = var.network
    access_config {}
  }

  tags                    = var.fastapi_network_tags

  metadata_startup_script = "${file("./start-scripts/fastapi_vm_startup_script.sh")}"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email                 = var.service_account_email
    scopes                = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_storage_bucket.bucket_stargate, google_storage_bucket_object.static_stargate_src]
}

resource "google_compute_instance_group_manager" "fastapi_kafka_producer_instance_group_manager" {
  name                      = "${var.project_name}-${var.fastapi_name_prefix}-instance-group"
  base_instance_name        = "${var.project_name}-${var.fastapi_name_prefix}-instance"
  zone                      = var.zone
  wait_for_instances_status = "STABLE"
  target_size               = var.fastapi_machine_number

  named_port {
    name = "http"
    port = "80"
  }

  version {
    instance_template       = google_compute_instance_template.fastapi_kafka_producer_instance_template.id
  }

  auto_healing_policies {
    health_check            = google_compute_health_check.healthcheck-mig.id
    initial_delay_sec       = "300"
  }

  depends_on                = [google_compute_instance_template.fastapi_kafka_producer_instance_template, google_compute_instance_group_manager.kafka_zookeeper_instance_group_manager]
}

######################################################
# DataProc e Máquinas de Apache Spark
######################################################

resource "google_dataproc_cluster" "stargate_cluster_stage" {
  name                          = "${var.project_name}-${var.spark_name_prefix}-cluster"
  region                        = var.region
  graceful_decommission_timeout = "120s"
  labels = {
    project                     = "${var.project_name}"
  }

  cluster_config {
    staging_bucket = google_storage_bucket.bucket_stargate.name

    master_config {
      num_instances             = var.spark_machine_number >= 3 ? var.spark_machine_number - 2 : 1
      machine_type              = var.spark_machine_type
      disk_config {
        boot_disk_type          = var.spark_disk_type
        boot_disk_size_gb       = var.spark_disk_size
      }
    }

    endpoint_config {
        enable_http_port_access = "true"
    }

    worker_config {
      num_instances             = var.spark_machine_number >= 3 ? var.spark_machine_number - 1 : 0
      min_cpu_platform          = "Intel Skylake"
      disk_config {
        boot_disk_size_gb       = var.spark_disk_size
        num_local_ssds          = 1
      }
    }

    preemptible_worker_config {
      num_instances             = 0
    }

    # Override or set some custom properties
    software_config {
      image_version             = "2.0.35-debian10"
      override_properties       = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      }
    }

    gce_cluster_config {
      #tags = ["foo", "bar"]
      # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
      service_account           = var.service_account_email
      service_account_scopes    = [
        "cloud-platform"
      ]

      #metadata = {
      #  BUCKET_NAME = var.bucket_name
      #}
    }

    # You can define multiple initialization_action blocks
    initialization_action {
      script      = "gs://${var.bucket_name}/spark_start_script.sh"
      timeout_sec = 500
    }

  }
}

######################################################
# Máquina de Teste e Monitoramento do Apache Kafka
######################################################

resource "google_compute_instance" "kafka_test_and_monitoring_instance" {
  name                    = "${var.project_name}-${var.kafka_test_monitoring_name_prefix}-instance"
  machine_type            = var.kafka_test_monitoring_machine_type
  zone                    = var.zone

  // boot disk
  boot_disk {
    // create a new boot disk from an image
    initialize_params {
      image               = "debian-cloud/debian-11"
      size                = var.kafka_test_monitoring_disk_size
      type                = var.kafka_test_monitoring_disk_type
    }
    auto_delete           = true
  }

  // networking
  network_interface {
    network               = var.network
    access_config {}
  }

  tags                    = var.kafka_test_monitoring_network_tags

  metadata_startup_script = "${file("./start-scripts/kafka_test_and_monitoring_vm_start_script.sh")}"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email                 = var.service_account_email
    scopes                = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on              = [google_storage_bucket.bucket_stargate, google_storage_bucket_object.static_stargate_src, google_compute_instance_group_manager.kafka_zookeeper_instance_group_manager]
}

######################################################
# Regras de Firewall - Kafka Broker - FastAPI - Grafana e Prometheus
######################################################

resource "google_compute_firewall" "kafka_broker_29092_jmx_8080" {
  name          = var.kafka_firewall_rule_name
  network       = var.network

  allow {
    protocol    = "tcp"
    ports       = var.kafka_firewall_rule_port
  }

  allow {
    protocol    = "udp"
    ports       = var.kafka_firewall_rule_port
  }

  source_ranges = ["0.0.0.0/0"]
  
  target_tags   = ["${var.kafka_firewall_rule_name}"]
}

resource "google_compute_firewall" "fastapi_8000" {
  name          = var.fastapi_firewall_rule_name
  network       = var.network

  allow {
    protocol    = "tcp"
    ports       = var.fastapi_firewall_rule_port
  }

  allow {
    protocol    = "udp"
    ports       = var.fastapi_firewall_rule_port
  }

  source_ranges = ["0.0.0.0/0"]
  
  target_tags   = ["${var.fastapi_firewall_rule_name}"]
}

resource "google_compute_firewall" "prometheus_9090_grafana_3000" {
  name          = var.test_monitoring_firewall_rule_name
  network       = var.network

  allow {
    protocol    = "tcp"
    ports       = var.test_monitoring_firewall_rule_port
  }

  allow {
    protocol    = "udp"
    ports       = var.test_monitoring_firewall_rule_port
  }

  source_ranges = ["0.0.0.0/0"]
  
  target_tags   = ["${var.test_monitoring_firewall_rule_name}"]
}

######################################################
# Load Balancing FastAPI
######################################################

resource "google_compute_backend_service" "fastapi-kafka-producer-backend-service" {
  name                            = "${var.load_balancing_name}-${var.project_name}-producer-backend-service"
  port_name                       = "http"
  session_affinity                = "NONE"
  protocol                        = "HTTP"
  timeout_sec                     = 600

  connection_draining_timeout_sec = "300"  
  health_checks                   = [google_compute_health_check.healthcheck-lb.id]
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  locality_lb_policy              = "ROUND_ROBIN"
  

  enable_cdn                      = "true"
  cdn_policy {
    cache_key_policy {
      include_host                = "true"
      include_protocol            = "true"
      include_query_string        = "true"
    }

    cache_mode                    = "CACHE_ALL_STATIC"
    client_ttl                    = "3600"
    default_ttl                   = "3600"
    max_ttl                       = "86400"
    negative_caching              = "false"
    serve_while_stale             = "0"
    signed_url_cache_max_age_sec  = "0"
  }

  backend {
    group = google_compute_instance_group_manager.fastapi_kafka_producer_instance_group_manager.instance_group
    capacity_scaler               = 1
    balancing_mode                = "UTILIZATION"
    max_connections_per_instance  = 0
    max_utilization               = 0.8
  }
  
  depends_on                      = [google_compute_instance_group_manager.fastapi_kafka_producer_instance_group_manager, google_compute_managed_ssl_certificate.fastapi-kafka-stargate-ssl]
  
  log_config {
    enable      = true
    sample_rate = 1    
  }

}

# Regra de direcionamento de tráfego
resource "google_compute_global_forwarding_rule" "fastapi-kafka-frontend-lb" {
  name                  = "${var.load_balancing_name}-${var.project_name}-frontend-lb"
  ip_address            = google_compute_global_address.fastapi-kafka-stargate-address.address
  ip_protocol           = "TCP"
  port_range            = "443-443"
  target                = google_compute_target_https_proxy.fastapi-kafka-stargate-lb-target-proxy.self_link
  load_balancing_scheme = "EXTERNAL_MANAGED"
  depends_on            = [ google_compute_target_https_proxy.fastapi-kafka-stargate-lb-target-proxy, google_compute_global_address.fastapi-kafka-stargate-address]
}

resource "google_compute_global_forwarding_rule" "fastapi-kafka-frontend-lb-forwarding-rule" {
  name                  = "${var.load_balancing_name}-${var.project_name}-frontend-lb-forwarding-rule"
  ip_address            = google_compute_global_address.fastapi-kafka-stargate-address.address
  ip_protocol           = "TCP"
  port_range            = "80-80"
  target                = google_compute_target_http_proxy.fastapi-kafka-stargate-frontend-lb-target-proxy.self_link
  load_balancing_scheme = "EXTERNAL_MANAGED"
  depends_on            = [ google_compute_target_http_proxy.fastapi-kafka-stargate-frontend-lb-target-proxy, google_compute_global_address.fastapi-kafka-stargate-address]
}

resource "google_compute_target_https_proxy" "fastapi-kafka-stargate-lb-target-proxy" {
  name                  = "${var.load_balancing_name}-${var.project_name}-lb-target-proxy"
  url_map               = google_compute_url_map.fastapi-kafka-frontend-lb.id
  proxy_bind            = false
  quic_override         = "NONE"

  ssl_certificates      = [google_compute_managed_ssl_certificate.fastapi-kafka-stargate-ssl.id]
  depends_on            = [google_compute_url_map.fastapi-kafka-frontend-lb]    
}

resource "google_compute_target_http_proxy" "fastapi-kafka-stargate-frontend-lb-target-proxy" {
  name                  = "${var.load_balancing_name}-${var.project_name}-frontend-lb-target-proxy"
  url_map               = google_compute_url_map.fastapi-kafka-frontend-lb.id # Para aceitar somente navegação segura (HTTPS), muda pra google_compute_url_map.fastapi-kafka-frontend-lb-redirect.id
  proxy_bind            = false

  depends_on            = [google_compute_url_map.fastapi-kafka-frontend-lb] # Para aceitar somente navegação segura (HTTPS), muda pra [google_compute_url_map.fastapi-kafka-frontend-lb-redirect]
}

resource "google_compute_url_map" "fastapi-kafka-frontend-lb" {
  name            = "${var.load_balancing_name}-${var.project_name}-lb"
  default_service = google_compute_backend_service.fastapi-kafka-producer-backend-service.id
  depends_on      = [google_compute_backend_service.fastapi-kafka-producer-backend-service]
}

## Descomente e altere as lnhas 424 e 428 para permitir somente navegação segura (HTTPS)

# resource "google_compute_url_map" "fastapi-kafka-frontend-lb-redirect" {
#   name            = "${var.load_balancing_name}-${var.project_name}-frontend-lb-redirect"
#   description     = "Automatically generated HTTP to HTTPS redirect for ${var.load_balancing_name}-${var.project_name}-frontend-lb forwarding rule"

#   default_url_redirect {
#     https_redirect         = false
#     redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
#     strip_query            = false
#   }
# }

######################################################
# Health Checks para grupos e load balancing
######################################################

# Load Balancing Health Check - TCP
resource "google_compute_health_check" "healthcheck-lb" {
  name                = "${var.project_name}-healthcheck-lb"
  check_interval_sec  = 60
  timeout_sec         = 60
  healthy_threshold   = 3
  unhealthy_threshold = 5

  log_config {
    enable = true
  }

  tcp_health_check {
    port         = "80"
    proxy_header = "NONE"
  }
}

resource "google_compute_health_check" "healthcheck-mig" {
  name                = "${var.project_name}-healthcheck-mig"
  check_interval_sec  = 60
  timeout_sec         = 60
  healthy_threshold   = 3
  unhealthy_threshold = 5

  log_config {
    enable = true
  }

  http_health_check {
    port                = "80"
    request_path        = "/"
  }
}

# resource "google_compute_firewall" "default-allow-ssh" {
#   name          = "default-allow-ssh"
#   description   = "Allow SSH from anywhere"

#   allow {
#     ports       = ["22"]
#     protocol    = "tcp"
#   }

#   direction     = "INGRESS"
#   disabled      = "false"
#   network       = var.network
#   priority      = "65534"
#   source_ranges = ["0.0.0.0/0"]
# }

# resource "google_compute_firewall" "allow-health-check" {
#   allow {
#     ports       = ["80"]
#     protocol    = "tcp"
#   }

#   direction     = "INGRESS"
#   disabled      = "false"
#   name          = "allow-health-check"
#   network       = var.network
#   priority      = "1000"
#   project       = "dp6-stargate"
#   source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
#   target_tags   = ["allow-health-check"]
# }

######################################################
# Certificação SSL
######################################################

resource "google_compute_managed_ssl_certificate" "fastapi-kafka-stargate-ssl" {
  name      = "${var.load_balancing_name}-${var.project_name}-ssl"

  managed {
    domains = var.fastapi_domain
  }

  type      = "MANAGED"
}

######################################################
# Reservar ip estático para Frontend do LB
######################################################

resource "google_compute_global_address" "fastapi-kafka-stargate-address" {
  address_type  = "EXTERNAL"
  ip_version    = "IPV4"
  name          = "${var.load_balancing_name}-${var.project_name}-address"
  prefix_length = "0"
}

######################################################
# Cloud DNS and Records
######################################################

resource "google_dns_managed_zone" "fastapi-kafka-stargate-dns-com" {
  dns_name      = "${var.load_balancing_name}-${var.project_name}.com."
  description   = "DNS zone for domain: ${var.load_balancing_name}-${var.project_name}.com."

  force_destroy = "false"
  name          = "${var.load_balancing_name}-${var.project_name}-com"
  project       = var.project_id
  visibility    = "public"
}

resource "google_dns_record_set" "fastapi-kafka-stargate-com" {
  managed_zone = google_dns_managed_zone.fastapi-kafka-stargate-dns-com.name
  name         = google_dns_managed_zone.fastapi-kafka-stargate-dns-com.dns_name
  rrdatas      = [google_compute_global_address.fastapi-kafka-stargate-address.address]
  ttl          = "5"
  type         = "A"
  depends_on   = [google_dns_managed_zone.fastapi-kafka-stargate-dns-com, google_compute_global_address.fastapi-kafka-stargate-address]
}

######################################################
# Create BigQuery Dataset
######################################################

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = var.bigquery_dataset
  friendly_name               = var.bigquery_dataset
  description                 = "Stargate dataset for realtime"
  location                    = "US"

  labels = {
    stargate = var.bigquery_dataset
  }

  delete_contents_on_destroy = false

  access {
    role          = "OWNER"
    user_by_email = var.service_account_email
  }
}

######################################################
# GCE Reservation - Commited Use Discount
######################################################

# resource "google_compute_reservation" "gce_fastapi_reservation" {
#   name = "gce-${var.project_name}-${var.fastapi_name_prefix}-reservation"
#   zone = var.zone

#   specific_reservation {
#     count = var.fastapi_machine_number
#     instance_properties {
#       min_cpu_platform = "Intel Cascade Lake"
#       machine_type     = var.fastapi_machine_type
#     }
#   }
# }

# resource "google_compute_reservation" "gce_kafka_reservation" {
#   name = "gce-${var.project_name}-${var.kafka_name_prefix}-reservation"
#   zone = var.zone

#   specific_reservation {
#     count = var.fastapi_machine_number
#     instance_properties {
#       min_cpu_platform = "Intel Cascade Lake"
#       machine_type     = var.kafka_machine_type
#     }
#   }
# }

# resource "google_compute_reservation" "gce_spark_reservation" {
#   name = "gce-${var.project_name}-${var.spark_name_prefix}-reservation"
#   zone = var.zone

#   specific_reservation {
#     count = var.fastapi_machine_number
#     instance_properties {
#       min_cpu_platform = "Intel Cascade Lake"
#       machine_type     = var.spark_machine_type
#     }
#   }
# }

# resource "google_compute_reservation" "gce_kafka_test_monitoring_reservation" {
#   name = "gce-${var.project_name}-${var.kafka_test_monitoring_name_prefix}-reservation"
#   zone = var.zone

#   specific_reservation {
#     count = var.fastapi_machine_number
#     instance_properties {
#       min_cpu_platform = "Intel Cascade Lake"
#       machine_type     = var.kafka_test_monitoring_machine_type
#     }
#   }
# }