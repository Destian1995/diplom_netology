# output "internal_ip_address_vm_instance_ForEach" {
#   value = values(yandex_compute_instance.ForEach).*.network_interface.0.ip_address
# }

# output "external_ip_address_vm_instance_ForEach" {
#   value = values(yandex_compute_instance.ForEach).*.network_interface.0.nat_ip_address
# }

output "internal_ip_address_vm_instance_worker" {
  value = yandex_compute_instance.worker.*.network_interface.0.ip_address
}

output "external_ip_address_vm_instance_worker" {
  value = yandex_compute_instance.worker.*.network_interface.0.nat_ip_address
}

output "internal_ip_address_vm_instance_master" {
  value = yandex_compute_instance.master.*.network_interface.0.ip_address
}

output "external_ip_address_vm_instance_master" {
  value = yandex_compute_instance.master.*.network_interface.0.nat_ip_address
}

output "internal_ip_address_vm_instance_jenkins" {
  value = yandex_compute_instance.jenkins.*.network_interface.0.ip_address
}

output "external_ip_address_vm_instance_jenkins" {
  value = yandex_compute_instance.jenkins.*.network_interface.0.nat_ip_address
}