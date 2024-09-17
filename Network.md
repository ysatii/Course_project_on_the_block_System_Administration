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


![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net1.jpg)  


![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net1_1.jpg)  


![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net1_2.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net1_3.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net1_4.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net1_5.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net1_6.jpg) 

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net1_7.jpg)  


## Создадим таблицу маршрутизации и группы безопастности
### Код  terrafom создания Таблица маршрутизации и группы безопастности 
<details>
<summary>Нажмите сдесь что бы раскрыть блок</summary>

```


resource "yandex_vpc_route_table" "bastion-route" {
  name        = "bastion-route"

  depends_on = [ yandex_compute_instance.bastion ]

  network_id = yandex_vpc_network.bastionet.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.bastion.network_interface.0.ip_address
  }
}

#security_ for internet
resource "yandex_vpc_security_group" "sg-internet" {
  name        = "sg-internet"
  network_id  = yandex_vpc_network.bastionet.id

  egress {
    protocol       = "ANY"    
    v4_cidr_blocks = ["0.0.0.0/0"] 
    from_port      = 0
    to_port        = 65535 
  }

  ingress {
    protocol       = "ICMP"    
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

#security_group for bastion
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion"
  network_id  = yandex_vpc_network.bastionet.id

  ingress {
    protocol          = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]  
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]        
    port           = 22
   }  
}

#security_group for alby
resource "yandex_vpc_security_group" "alb-wb" {
  name        = "load-balansir"
  network_id  = yandex_vpc_network.bastionet.id

  ingress {
    protocol       = "TCP"   
    v4_cidr_blocks = ["0.0.0.0/0"]    
    port           = 80
   }

   ingress {
     protocol       = "TCP"   
     v4_cidr_blocks = ["0.0.0.0/0"]    
     port           = 443
   }

   ingress {
     protocol       = "TCP"   
     predefined_target = "loadbalancer_healthchecks"        
     port           = 30080     
   }
}

#security_group for web
resource "yandex_vpc_security_group" "web-sg" {
  name        = "webserver"
  network_id  = yandex_vpc_network.bastionet.id
  
  ingress {
    protocol       = "TCP"    
    security_group_id = yandex_vpc_security_group.alb-wb.id
  }

  ingress {
    protocol          = "TCP"      
    security_group_id = yandex_vpc_security_group.bastion-sg.id   
    port              = 22
   }    

  ingress {
    protocol       = "TCP"    
    security_group_id = yandex_vpc_security_group.zabbix-sg.id   
    from_port         = 10050
    to_port           = 10051
  }
}

#security_group for elasticsearch
resource "yandex_vpc_security_group" "elastic-sg" {
  name        = "elastic"
  network_id  = yandex_vpc_network.bastionet.id
  
  ingress {
    protocol       = "TCP"    
    v4_cidr_blocks = ["0.0.0.0/0"]  
    port           = 9200
  }
  
   ingress {
    protocol       = "TCP"    
    security_group_id = yandex_vpc_security_group.zabbix-sg.id   
    from_port         = 10050
    to_port           = 10051
  }


  ingress {
    protocol          = "TCP"      
    security_group_id = yandex_vpc_security_group.bastion-sg.id   
    port              = 22
   }    
}

#security_group for kibana
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana"
  network_id  = yandex_vpc_network.bastionet.id
  
  ingress {
    protocol       = "TCP"    
    v4_cidr_blocks = ["0.0.0.0/0"]  
    port           = 5601
  }

  ingress {
    protocol          = "TCP"      
    security_group_id = yandex_vpc_security_group.bastion-sg.id   
    port              = 22
  }    

  ingress {
    protocol       = "TCP"    
    security_group_id = yandex_vpc_security_group.zabbix-sg.id   
    from_port         = 10050
    to_port           = 10051
  }
  
}

#security_group for zabbix
resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix"
  network_id  = yandex_vpc_network.bastionet.id
  
  ingress {
    protocol       = "TCP"    
    v4_cidr_blocks = ["0.0.0.0/0"]  
    from_port         = 10050
    to_port           = 10051
  }

  ingress {
    protocol       = "TCP"    
    v4_cidr_blocks = ["0.0.0.0/0"]  
    port         = 80
  }

  ingress {
    protocol          = "TCP"      
    security_group_id = yandex_vpc_security_group.bastion-sg.id   
    port              = 22
  }    
}
```

</details>

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2.jpg)  


![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2_1.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2_2.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2_3.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2_4.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2_5.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2_6.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2_7.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2_8.jpg)  

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/net2_9.jpg)  