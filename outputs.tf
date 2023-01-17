# (c) 2023 yky-labs
# This code is licensed under MIT license (see LICENSE for details)

output "sa_password" {
  value     = local.sa_password
  sensitive = true
}
