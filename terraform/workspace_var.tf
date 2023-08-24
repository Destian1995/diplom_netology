 locals {
  cores = {
    diplom-stage = 2
    diplom-prod = 4
  }
  disk_size = {
    diplom-stage = 15
    diplom-prod = 30
  }

  memory = {
    diplom-stage = 2
    diplom-prod = 4
  }
  disk_type = {
    diplom-stage = "network-ssd"
    diplom-prod = "network-ssd"
  }

  subnet-type = {
    diplom-stage = yandex_vpc_subnet.subnet-stage.id
    diplom-prod = yandex_vpc_subnet.subnet-prod.id
  }

  zone = {
    diplom-stage = "ru-central1-b"
    diplom-prod = "ru-central1-a"
  }
  } 
