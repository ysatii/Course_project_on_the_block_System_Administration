# Курсовой проект по блоку "Системное администрирование"

 ## Резервное копирование

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)



 
### Код код terrafom создания снимков дисков 
<details>
<summary>Нажмите сдесь что бы раскрыть блок</summary>

```
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
```
</details>


### Код  terrafom создания расписания снимков дисков 
<details>
<summary>Нажмите сдесь что бы раскрыть блок</summary>

```
resource "yandex_compute_snapshot_schedule" "snapshot-auto" {
  name = "snapshot-auto"

  schedule_policy {
	expression = "18 08 ? * *" # time in UTC±0:00
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

```




![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/backup1.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/backup1_1.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/backup1_2.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/backup1_3.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/backup1_4.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/backup1_5.jpg)  


</details>

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)

