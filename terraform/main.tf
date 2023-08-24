resource "yandex_compute_instance" "master" {
  name = "master-${format(var.count_format, var.count_offset+count.index+1)}"
  zone = local.zone[terraform.workspace]
  count = 1

  resources {
    cores  = local.cores[terraform.workspace]
    memory = local.memory[terraform.workspace]
  }

  boot_disk {
    initialize_params {
      image_id = "fd8emvfmfoaordspe1jr"
      type = local.disk_type[terraform.workspace]
      size = local.disk_size[terraform.workspace]
    }
  }

  network_interface {
    subnet_id = local.subnet-type[terraform.workspace]
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "worker" {
  name = "worker-${format(var.count_format, var.count_offset+count.index+1)}"
  zone = local.zone[terraform.workspace]
  count = 2

  resources {
    cores  = local.cores[terraform.workspace]
    memory = local.memory[terraform.workspace]
  }

  boot_disk {
    initialize_params {
      image_id = "fd8emvfmfoaordspe1jr"
      type = local.disk_type[terraform.workspace]
      size = local.disk_size[terraform.workspace]
    }
  }

  network_interface {
    subnet_id = local.subnet-type[terraform.workspace]
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "jenkins" {
  name = "jenkins-${format(var.count_format, var.count_offset+count.index+1)}"
  zone = local.zone[terraform.workspace]
  count = 1

  resources {
    cores  = local.cores[terraform.workspace]
    memory = local.memory[terraform.workspace]
  }

  boot_disk {
    initialize_params {
      image_id = "fd8emvfmfoaordspe1jr"
      type = local.disk_type[terraform.workspace]
      size = local.disk_size[terraform.workspace]
    }
  }

  network_interface {
    subnet_id = local.subnet-type[terraform.workspace]
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("id_rsa.pub")}"
  }
}

