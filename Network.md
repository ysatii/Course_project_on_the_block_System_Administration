# Курсовой проект по блоку "Системное администрирование"

## Сеть
[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)





### Код код terrafom для создания сети и подсетей
<details>
<summary>Нажмите сдесь что бы раскрыть блок</summary>

```
#network
resource "yandex_vpc_network" "bastionet" {
  name = "bastionet"
}

#subnets
resource "yandex_vpc_subnet" "web-sub-a" {
  name = "web-sub-a"
  v4_cidr_blocks = ["10.0.1.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.bastionet.id
  route_table_id = yandex_vpc_route_table.bastion-route.id
   
}

resource "yandex_vpc_subnet" "web-sub-b" {
  name = "web-sub-b"
  v4_cidr_blocks = ["10.0.2.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.bastionet.id
  route_table_id = yandex_vpc_route_table.bastion-route.id
   
}

resource "yandex_vpc_subnet" "external" {
  name = "external"
  v4_cidr_blocks = ["10.0.3.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.bastionet.id
}
```
</details>

## Создадим расписаниедля создания снимков дисков
### Код  terrafom создания расписания снимков дисков 
<details>
<summary>Нажмите сдесь что бы раскрыть блок</summary>

```

```

</details>




![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/backup1_2.jpg)  

