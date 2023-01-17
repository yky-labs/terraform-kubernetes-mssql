# (c) 2023 yky-labs
# This code is licensed under MIT license (see LICENSE for details)

variable "name" {
  type        = string
  description = "The deploy name. Used to contextualize the name of the generated resources."
  default     = "mssql"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace."
}

variable "create_namespace" {
  type        = bool
  description = "Create the Kunernetes namespace."
  default     = false
}

variable "mssql_version" {
  type    = string
  default = "latest"
}

variable "accept_eula" {
  type = string
  validation {
    condition = var.accept_eula == "Y"
    error_message = "Must accept EULA."
  }
}

variable "sa_password" {
  type      = string
  default   = null
  sensitive = true
}

variable "edition" {
  type    = string
  default = "Developer"
}

variable "data_disk_size" {
  type    = string
  default = "10Gi"
}

variable "backup_disk_size" {
  type    = string
  default = "20Gi"
}

variable "request_memory" {
  type    = string
  default = "2Gi"
}

variable "request_cpu" {
  type    = string
  default = "1000m"
}

variable "limit_memory" {
  type    = string
  default = "2Gi"
}

variable "limit_cpu" {
  type    = string
  default = "1000m"
}
