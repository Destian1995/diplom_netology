terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.78.1"

cloud {
  organization = "Destian"

  workspaces {
    tags = ["stage", "prod"]
   }
 }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id = var.YC_CLOUD_ID
  folder_id = var.YC_FOLDER_ID
  zone = "ru-central1-a"
}
