terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

variable "yandex_cloud_token" {
  type        = string
}

provider "yandex" {
  token     = var.yandex_cloud_token
  cloud_id  = "b1ggavufohr5p1bfj10e"
  folder_id = "b1g0hcgpsog92sjluneq"
  zone      = "ru-central1-a"
}

#
#webserver1 disk_id
data "yandex_compute_instance" "webserver1" {
  name = "webserver1"
} 

output "webserver1_disk_id" {
  value = "${data.yandex_compute_instance.webserver1.boot_disk[0].disk_id}"
}

#webserver2 disk_id
data "yandex_compute_instance" "webserver2" {
  name = "webserver2"
} 

output "webserver2_disk_id" {
  value = "${data.yandex_compute_instance.webserver2.boot_disk[0].disk_id}"
}

#bastion disk_id
data "yandex_compute_instance" "bastion" {
  name = "bastion"
}

output "bastion_disk_id" {
  value = "${data.yandex_compute_instance.bastion.boot_disk[0].disk_id}"
}

#elasticsearch disk_id
data "yandex_compute_instance" "elastic" {
  name = "elastic"
}

output "elastic_disk_id" {
  value = "${data.yandex_compute_instance.elastic.boot_disk[0].disk_id}"
}

#kibana disk_id
data "yandex_compute_instance" "kibana-server" {
  name = "kibana-server"
}

output "kibana_disk_id" {
  value = "${data.yandex_compute_instance.kibana-server.boot_disk[0].disk_id}"
}

#zabbix_server disk_id
data "yandex_compute_instance" "zabbix-server" {
  name = "zabbix-server"
}  

output "zabbix_disk_id" {
  value = "${data.yandex_compute_instance.zabbix-server.boot_disk[0].disk_id}"
}

resource "yandex_compute_snapshot_schedule" "snapshot-auto" {
  name = "snapshot-auto"

  schedule_policy {
	expression = "18 20 ? * *" # time in UTC±0:00
  }

   snapshot_spec {
    description = "cron"
    labels = {
      id = "auto"
    }
  }


  snapshot_count = 7
    
  disk_ids = [
    data.yandex_compute_instance.webserver1.boot_disk[0].disk_id, 
    data.yandex_compute_instance.webserver2.boot_disk[0].disk_id,
    data.yandex_compute_instance.bastion.boot_disk[0].disk_id,
    data.yandex_compute_instance.elastic.boot_disk[0].disk_id,
    data.yandex_compute_instance.kibana-server.boot_disk[0].disk_id,
    data.yandex_compute_instance.zabbix-server.boot_disk[0].disk_id
    ]
}

# data "yandex_compute_snapshot_schedule" "snapshot_schedule" {
#  name = "myvpc"
# }

# output "snapshot_schedule" {
#  value = "${data.yandex_compute_snapshot_schedule.snapshot_schedule.status}"
# }


resource "yandex_compute_snapshot" "webserver1" {
  name           = "webserver1"
  description = "snapshot webserver1"
  source_disk_id =  data.yandex_compute_instance.webserver1.boot_disk[0].disk_id
}

resource "yandex_compute_snapshot" "webserver2" {
  name           = "webserver2"
  description = "snapshot webserver2"
  source_disk_id =  data.yandex_compute_instance.webserver2.boot_disk[0].disk_id
}

resource "yandex_compute_snapshot" "bastion" {
  name           = "bastion"
  description = "snapshot bastion"
  source_disk_id =  data.yandex_compute_instance.bastion.boot_disk[0].disk_id
}

resource "yandex_compute_snapshot" "elastic" {
  name           = "elastic"
  description = "snapshot elastic"
  source_disk_id =  data.yandex_compute_instance.elastic.boot_disk[0].disk_id
}

resource "yandex_compute_snapshot" "kibana-server" {
  name           = "kibana-server"
  description = "snapshot kibana"
  source_disk_id =  data.yandex_compute_instance.kibana-server.boot_disk[0].disk_id
}
resource "yandex_compute_snapshot" "zabbix-server" {
  name           = "zabbix"
  description = "snapshot zabbix"
  source_disk_id =  data.yandex_compute_instance.zabbix-server.boot_disk[0].disk_id
}


    