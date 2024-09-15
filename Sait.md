# Курсовой проект по блоку "Системное администрирование"

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)
## Сайт 



### Создадим два веб сервера
### Код для создания веб серверов
<details>
<summary>Нажмите сдесь что бы раскрыть блок</summary>

```
resource "yandex_compute_instance" "webserver" {
  count       = 2
  name        = "webserver${count.index + 1}"
  hostname    = "webserver${count.index + 1}"
  platform_id = "standard-v3"
  zone        = "ru-central1-${count.index == 0? "a" : "b"}"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size     = 10
      type     = "network-hdd"
    }
  }

```
</details>

### Создадим  Target Group, Backend Group, HTTP router, Application load balancer

### Код terraform
<details>
<summary>Нажмите сдесь что бы раскрыть блок</summary>

```
#target group
resource "yandex_alb_target_group" "direct-gr" {
  name      = "direct-gr"

  target {
    subnet_id  = yandex_vpc_subnet.web-sub-a.id
    ip_address = yandex_compute_instance.webserver[0].network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.web-sub-b.id
    ip_address = yandex_compute_instance.webserver[1].network_interface.0.ip_address    
  }
}

#backend group
resource "yandex_alb_backend_group" "bg-1" {
  name      = "bg-1"

  http_backend {
    name = "bodra-http"
    port = 80
  target_group_ids = [yandex_alb_target_group.direct-gr.id]
    healthcheck {
      timeout = "10s"
      interval = "2s"
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

#http-router
resource "yandex_alb_http_router" "http-router" {
  name      = "http-router"
}

#virtual host
resource "yandex_alb_virtual_host" "vh-1" {
  name      = "vh-1"
  http_router_id = yandex_alb_http_router.http-router.id
  route {
    name = "vh-route-1"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.bg-1.id
      }
    }
  }
}

#load-balancer
resource "yandex_alb_load_balancer" "lb1" {
  name = "lb1"

  network_id  = yandex_vpc_network.bastionet.id
  security_group_ids = [ yandex_vpc_security_group.alb-wb.id, yandex_vpc_security_group.sg-internet.id ]
  

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.web-sub-a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.web-sub-b.id
    }
  }

  listener {
    name = "listener-1"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http-router.id
      }
    }
  }
}
```
</details>

### Схема балансировки
![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1.jpg)  


### Код Ansible
<details>
<summary>Нажмите сдесь что бы раскрыть блок</summary>

```
  name: Configure web server
  hosts: internal_servers
  gather_facts: no
  become: yes
  tasks:
    - name: Update cache
      apt:
        update_cache: yes

    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Copy index.html
      copy:
        src: templates/index.html
        dest: /var/www/html/
    
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
    
    - name: copy filebeat
      copy:
        src: packages/{{ pkg_name }}
        dest: /var/www/html/

    
    

- name: Configure web server 2
  hosts: webserver2.ru-central1.internal
  gather_facts: no
  become: yes
  tasks:
    - name: Copy index.html server2 
      copy:
        src: templates2/index.html
        dest: /var/www/html/
    
    - name: copy filebeat
      copy:
        src: packages/{{ pkg_name }}
        dest: /var/www/html/


```
</details>
  

### Код Ansible для установки nginx и копирования index.html на оба web вебсервера
На каждый сервер загружаем свою версию файла, что бы понять работае ли  балансировка! Сделано в учебных целях.! 

### Запустим Ansible скрипт 
![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_3.jpg)




### Протестируем сайт 
Получили ответы с обеих веб серверов   
Сервер1  
![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_2.jpg)

Сервер2  
![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_1.jpg)

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)



![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_4.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_5.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_6.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_7.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_8.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_9.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_10.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_11.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_12.jpg)
