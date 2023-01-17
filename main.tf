# (c) 2023 yky-labs
# This code is licensed under MIT license (see LICENSE for details)

locals {
  namespace   = (var.create_namespace) ? kubernetes_namespace_v1.this[0].metadata[0].name : var.namespace
  sa_password = (var.sa_password != null) ? var.sa_password : random_password.sa_password[0].result
}

resource "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "random_password" "sa_password" {
  count = (var.sa_password == null) ? 1 : 0

  length      = 32
  min_lower   = 5
  min_upper   = 5
  min_numeric = 5
  special     = false
}

resource "kubernetes_secret_v1" "sa_password" {
  metadata {
    name      = "${var.name}-sa-password"
    namespace = local.namespace
  }
  data = {
    "MSSQL_SA_PASSWORD" = local.sa_password
  }
}

resource "kubernetes_persistent_volume_claim_v1" "data" {
  metadata {
    name      = "${var.name}-data"
    namespace = local.namespace
  }
  wait_until_bound = false
  spec {
    access_modes = [ "ReadWriteOnce" ]
    resources {
      requests = {
        storage = var.data_disk_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "backup" {
  metadata {
    name      = "${var.name}-backup"
    namespace = local.namespace
  }
  wait_until_bound = false
  spec {
    access_modes = [ "ReadWriteOnce" ]
    resources {
      requests = {
        storage = var.backup_disk_size
      }
    }
  }
}

# https://hub.docker.com/_/microsoft-mssql-server
# https://learn.microsoft.com/en-us/sql/linux/quickstart-sql-server-containers-kubernetes?view=sql-server-ver16

resource "kubernetes_stateful_set_v1" "this" {
  metadata {
    name      = var.name
    namespace = local.namespace
  }
  spec {
    service_name = var.name
    replicas     = 1
    selector {
      match_labels = {
        "app" = var.name
      }
    }
    template {
      metadata {
        labels = {
          "app" = var.name
        }
      }
      spec {
        termination_grace_period_seconds = 30
        security_context {
          fs_group = 10001
        }
        container {
          name = var.name
          image = "mcr.microsoft.com/mssql/server:${var.mssql_version}"
          resources {
            requests = {
              "memory" = var.request_memory
              "cpu"    = var.request_cpu
            }
            limits = {
              "memory" = var.limit_memory
              "cpu"    = var.limit_cpu
            }
          }
          port {
            container_port = 1433
          }
          env {
            name  = "ACCEPT_EULA"
            value = var.accept_eula
          }
          env {
            name  = "MSSQL_PID"
            value = var.edition
          }
          env {
            name = "MSSQL_SA_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.sa_password.metadata[0].name
                key  = "MSSQL_SA_PASSWORD"
              }
            }
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/opt/mssql"
          }
          volume_mount {
            name       = "backup"
            mount_path = "/var/opt/backup"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.data.metadata[0].name
          }
        }
        volume {
          name = "backup"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.backup.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "this" {
  metadata {
    name      = var.name
    namespace = local.namespace
  }
  spec {
    selector = {
      "app" = var.name
    }
    port {
      port        = 1433
      target_port = 1433
    }
  }

  depends_on = [
    kubernetes_stateful_set_v1.this
  ]
}
