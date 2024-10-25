# Курсовой проект по блоку "Системное администрирование"

## Дополнительные задания

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/extended/README.md)


## Порядок запуска пайплайн ansible и terraform для поднятие инфраструктуры подолнительного для задания 1

### Развертывание инфраструктуры:
<details>
<summary>Нажмите для просмотра листинга скрипта /terraform/pgsql_vpc_up/main.tf</summary>

```
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

#webserver
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

  network_interface {
    subnet_id          = count.index == 0? yandex_vpc_subnet.web-sub-a.id : yandex_vpc_subnet.web-sub-b.id  
    security_group_ids = [ yandex_vpc_security_group.web-sg.id, yandex_vpc_security_group.sg-internet.id ]
  }

  metadata = {
    user-data = "${file("./metadata/meta_web.yml")}"
  }
}

#bastion
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

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
      image_id = "fd806u1okplml22f4pmo"
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {    
    subnet_id          =  yandex_vpc_subnet.external.id  
    security_group_ids = [ yandex_vpc_security_group.bastion-sg.id, yandex_vpc_security_group.sg-internet.id, yandex_vpc_security_group.zabbix-sg.id ]  
    nat                = true  
  }
  
  metadata = {
    user-data = "${file("./metadata/meta_bastion.yml")}"
  }
}

output "bastion_nat_ip_address" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

#elasticsearch
resource "yandex_compute_instance" "elastic" {
  name        = "elastic"
  hostname    = "elastic"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 4
    memory        = 4
    core_fraction = 20
  }
  
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {    
    subnet_id          =  yandex_vpc_subnet.web-sub-a.id
    security_group_ids = [ yandex_vpc_security_group.elastic-sg.id, yandex_vpc_security_group.sg-internet.id ]     
  }
  
  metadata = {
    user-data = "${file("./metadata/meta_web.yml")}"
  }
}

#kibana
resource "yandex_compute_instance" "kibana-server" {
  name        = "kibana-server"
  hostname    = "kibana-server"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }
  
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s4a9mnca2bmgol2r8"
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {    
    subnet_id          = yandex_vpc_subnet.external.id     
    security_group_ids = [ yandex_vpc_security_group.kibana-sg.id, yandex_vpc_security_group.sg-internet.id ]  
    nat = true    
  }
  
  metadata = {
    user-data = "${file("./metadata/meta_web.yml")}"
  }
}

output "kibana_nat_ip_address" {
  value = yandex_compute_instance.kibana-server.network_interface.0.nat_ip_address
}

#zabbix_server
resource "yandex_compute_instance" "zabbix-server" {
  name        = "zabbix-server"
  hostname    = "zabbix-server"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

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
      image_id = "fd8s4a9mnca2bmgol2r8" # image_id = "fd8rpsoinvpbjub1fn9g"   # 
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {    
    subnet_id          = yandex_vpc_subnet.web-sub-b.id     
    security_group_ids = [ yandex_vpc_security_group.zabbix-sg.id, yandex_vpc_security_group.sg-internet.id]  
    
  }
  
  metadata = {
    user-data = "${file("./metadata/meta_web.yml")}"
  }
}

output "zabbix_ip_address" {
  value = yandex_compute_instance.zabbix-server.network_interface.0.ip_address
}


#zabbix_web_server
resource "yandex_compute_instance" "zabbix-web" {
  name        = "zabbix-web"
  hostname    = "zabbix-web"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

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
      image_id = "fd8s4a9mnca2bmgol2r8" # image_id = "fd8rpsoinvpbjub1fn9g"   # 
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {    
    subnet_id          = yandex_vpc_subnet.external.id       
    security_group_ids = [ yandex_vpc_security_group.zabbix-sg.id, yandex_vpc_security_group.sg-internet.id, yandex_vpc_security_group.postgres.id ]  
    nat = true    
  }
  
  metadata = {
    user-data = "${file("./metadata/meta_web.yml")}"
  }
}

output "zabbix_web_nat_ip_address" {
  value = yandex_compute_instance.zabbix-web.network_interface.0.nat_ip_address
}




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

output "lb_external_ip_address" {
  value = yandex_alb_load_balancer.lb1.listener.0.endpoint.0.address.0.external_ipv4_address[0].address
}



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
  description = "открываем только 22 порт"
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
  description = "Для веб серверов"
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


#-------------------------------------
#security_group for postgres
resource "yandex_vpc_security_group" "postgres" {
  name        = "postgres"
  network_id  = yandex_vpc_network.bastionet.id

  ingress {
    protocol          = "TCP"      
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]  
    port              = 6432
  }  

  


}

resource "yandex_mdb_postgresql_cluster" "postgres" {
  name        = "zabbix-cluster"
  description = "PostgreSQL cluster for my test"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.bastionet.id
  security_group_ids = [yandex_vpc_security_group.postgres.id, yandex_vpc_security_group.sg-internet.id]

  config {
    version = 14
    autofailover = true
    resources {
      resource_preset_id = "s2.micro"  #"b1.medium"  #
      disk_type_id       = "network-ssd"
      disk_size          = 10
    }
    postgresql_config = {
      max_connections                   = 200
      max_locks_per_transaction         = 100
      max_parallel_workers              = 5
      max_prepared_transactions         = 4
      enable_parallel_hash              = true
      autovacuum_vacuum_scale_factor    = 0.34
      default_transaction_isolation     = "TRANSACTION_ISOLATION_READ_COMMITTED"
      shared_preload_libraries          = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
    }
    access {
      data_lens = true
      web_sql = true
      serverless = true
      data_transfer = true
    }
    performance_diagnostics {
      enabled = true
      sessions_sampling_interval = 10
      statements_sampling_interval = 60
    }

  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 12
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.web-sub-a.id
    name = "cl1"
    assign_public_ip = false
  }
  
  # для создания второй ноды кластера раскоментируйте код ниже
  # host {
  #  zone      = "ru-central1-b"
  #  subnet_id = yandex_vpc_subnet.web-sub-b.id
  #  name = "cl2"
  #  replication_source_name = "cl1"
  #  assign_public_ip = false
  # }
  # создание второй ноды кластера  

  # для создания третьей ноды кластрера раскоментируйте код ниже
  #  host {
  #   zone      = "ru-central1-b"
  #  subnet_id = yandex_vpc_subnet.web-sub-b.id
  #  name = "cl3"
  #  replication_source_name = "cl1"
  #  assign_public_ip = false
  # }
  ##### создание третьей ноды кластрера  
}

resource "yandex_mdb_postgresql_database" "zabbix" {
  cluster_id = yandex_mdb_postgresql_cluster.postgres.id
  name       = "zabbix"
  owner      = yandex_mdb_postgresql_user.zabbix.name
  lc_collate = "en_US.UTF-8"
  lc_type    = "en_US.UTF-8"
  extension {
    name = "uuid-ossp"
  }
  extension {
    name = "xml2"
  }
}

resource "yandex_mdb_postgresql_user" "zabbix" {
  cluster_id = yandex_mdb_postgresql_cluster.postgres.id
  name       = "zabbix"
  password   = var.pg_admin_password
  conn_limit = 150
  settings = {
    default_transaction_isolation = "read committed"
    log_min_duration_statement    = 5000
  }
  grants = [ "mdb_admin", "mdb_monitor", "mdb_replication" ]
}

output "postgresql_cluster_id" {
  value = yandex_mdb_postgresql_cluster.postgres.id
}

resource "local_file" "tf_ansible_vars_file" {
  content = <<-DOC
    pg_cluster_id: ${yandex_mdb_postgresql_cluster.postgres.id}
    pg_admin_password: ${var.pg_admin_password}
    bastion_host: ${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} 
    zabbix_server_ip: ${yandex_compute_instance.zabbix-server.network_interface.0.ip_address}
    zabbix_web_ip_address: ${yandex_compute_instance.zabbix-web.network_interface.0.nat_ip_address}
    DOC
  filename = "../../ansible/group_vars/all.yml"
}
```
</details>


из папки terraform
```sh
cd pgsql_vpc_up
terraform init  
terraform apply --auto-approve
```

Данный скрипт создат виртуальные машины и кластер облачной pgsql по умолчанию подымаеться одна нода - master, для убыстрения создания облака!
что бы создать дполнительные ноды нужно раскоментировать кодя ля создания дополнительных нод! это убыстрит работу с облаком! slave серевера автоматически будут нгастроены для работы с master нодой 




### Установка программного обеспечения
* 1_elk.yml - установка стека 
* 2_web.yml - установка и настройка веб сервиса
* 4_zabbix_agent_copy_all.yml - установка zabbix агента на все виртуальные машины кластера
* 10_zabbix_server_ony.yml - установка серверной части сервиса мониторинга zabbix при использовании облачной БД pgsql Яндекс облака
 <details>
  <summary>Нажмите для просмотра листинга скрипта</summary>

```
---
- name: Установка и настройка zabbix (серверная часть)
  hosts: zabbix_server
  gather_facts: no
  vars:
    db_host_cloud: c-{{ pg_cluster_id }}.rw.mdb.yandexcloud.net  
    db_port_cloud: 6432
    db_name_cloud: "{{ db_name_local }}"
    db_user_cloud: "{{ db_user_local }}"
    db_password_cloud: "{{ db_password_local }}"
  become: yes
  tasks:

  - name: Проверка доступности
    ping:

  - name: Обновление системы и установка зависимостей
    apt:
      update_cache: yes
      name: ['wget', 'curl', 'postgresql-contrib', 'mc']
      state: present

  - name: Копирование установочного пакета zabbix репозитория
    copy:
      src: packages/{{ pkg_zabbix }}
      dest: /tmp/

  - name: Установка zabbix репозитория
    command: dpkg -i /tmp/{{ pkg_zabbix }}

  - name: Обновление кеша установщика
    apt:
      update_cache: yes

  - name: Установка Zabbix Server и необходимых компонентов
    apt:
      name: ['zabbix-server-pgsql', 'zabbix-agent', 'zabbix-sql-scripts']
      state: present

 
  - name: Копируем файл внутри удаленной машины
    copy:
      src: /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz
      dest: /tmp/server.sql.gz


  - name : Распаковываем server.sql.gz 
    shell:
      cmd: |
        cd /tmp
        zcat server.sql.gz >  server.sql

  - name: "Ansible | Print a variable"
    debug:
      msg: "Использован кластер облачной yandex-cloud со следующими настройками Хост = {{ db_host_cloud }}, имя базы данных = {{ db_name_cloud }},  пользователь базы= {{ db_user_cloud }}, пароль базы = {{ db_password_cloud }}, db_port = {{db_port_cloud}}"

  - name: Загружаем начальные данные в базу zabbix
    community.postgresql.postgresql_db:
        name: "{{ db_name_cloud }}"
        login_host: "{{ db_host_cloud }}"
        login_password: "{{db_password_cloud}}"
        login_user: "{{ db_user_cloud }}"
        port: "{{db_port_cloud}}"
        state: restore
        target: /tmp/server.sql.gz
    become: yes


  - name: Копируем файл настроек zabbix сервера zabbix_server.conf
    template:
      src: templates/zabbix_server.conf2.j2
      mode: 0644
      dest: /etc/zabbix/zabbix_server.conf

  - name: Устанавливаем пароль базы данных PostgreSQL
    lineinfile:
       dest: /etc/zabbix/zabbix_server.conf
       regexp: '^# DBPassword='
       line: 'DBPassword={{ db_password_cloud }}' 
 
 
  - name: Устанавливаем  адврес хоста кластера yandex cloud PostgreSQL
    lineinfile:
       dest: /etc/zabbix/zabbix_server.conf
       regexp: '# DBHost='
       line: 'DBHost={{ db_host_cloud }}' 

  - name: Устанавливаем порт кластера yandex-cloud PostgreSQL 
    lineinfile:
       dest: /etc/zabbix/zabbix_server.conf
       regexp: '# DBPort='
       line: 'DBPort={{ db_port_cloud }}' 

  - name: Перезапуск сервиса Zabbix Server
    systemd:
      name: zabbix-server
      state: restarted
      enabled: yes

  - name: Перезапуск сервиса Zabbix Agent
    systemd:
      name: zabbix-agent
      state: restarted
      enabled: yes

```
</details>

* 11_zabix_web_only.yml - установка web-части сервиса мониторинга zabbix при использовании облачной БД pgsql Яндекс облака 

<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```


- name: Установка и настройка Zabbix (веб-часть)
  hosts: zabbix_web_server
  gather_facts: no
  vars:
    db_host_cloud: c-{{ pg_cluster_id }}.rw.mdb.yandexcloud.net  
    db_port_cloud: 6432
    db_name_cloud: "{{ db_name_local }}"
    db_user_cloud: "{{ db_user_local }}"
    db_password_cloud: "{{ db_password_local }}"
  become: yes
  tasks:

  - name: Обновление кеш
    apt:
      update_cache: yes

  - name: Копирование установочного пакета zabbix репозитория
    copy:
      src: packages/{{ pkg_zabbix }}
      dest: /tmp/

  - name: Установка zabbix репозитория
    command: dpkg -i /tmp/{{ pkg_zabbix }}

  - name: Обновление кеша установщика
    apt:
      update_cache: yes

  - name: Обновление системы и установка зависимостей для веб-части
    apt:
      update_cache: yes
      name: ['mc', 'wget', 'curl', 'nginx', 'php-fpm', 'php-pgsql', 'php-bcmath', 'php-mbstring', 'php-gd', 'php-xml', 'zabbix-frontend-php', 'zabbix-nginx-conf', 'zabbix-server-pgsql','zabbix-agent', 'zabbix-sql-scripts', 'zabbix-server-pgsql']
      state: present

  - name : Очищаем файл настроек web интерйейса zabbix.conf.php
    shell:
      cmd: |
        echo -n > /etc/zabbix/web/zabbix.conf.php



  - name: Генеририуем соержимое файла настроек web интерфейса /etc/zabbix/web/zabbix.conf.php
    become: yes
    blockinfile:
        path: /etc/zabbix/web/zabbix.conf.php
        block: |
         <?php
         // Zabbix GUI configuration file.

          $DB['TYPE']				= 'POSTGRESQL';
          $DB['SERVER']			= '{{ db_host_cloud }}';
          $DB['PORT']			= '{{ db_port_cloud }}';
          $DB['DATABASE']		= '{{ db_name_cloud }}';
          $DB['USER']			= '{{ db_user_cloud }}';
          $DB['PASSWORD']		= '{{ db_password_cloud }}';

          // Schema name. Used for PostgreSQL.
          $DB['SCHEMA']			= '';

          // Used for TLS connection.
          $DB['ENCRYPTION']		= false;
          $DB['KEY_FILE']			= '';
          $DB['CERT_FILE']		= '';
          $DB['CA_FILE']			= '';
          $DB['VERIFY_HOST']		= false;
          $DB['CIPHER_LIST']		= '';

          // Vault configuration. Used if database credentials are stored in Vault secrets manager.
          $DB['VAULT_URL']		= '';
          $DB['VAULT_DB_PATH']	= '';
          $DB['VAULT_TOKEN']		= '';

          // Use IEEE754 compatible value range for 64-bit Numeric (float) history values.
          // This option is enabled by default for new Zabbix installations.
          // For upgraded installations, please read database upgrade notes before enabling this option.
          $DB['DOUBLE_IEEE754']	= true;

          // Uncomment and set to desired values to override Zabbix hostname/IP and port.
          // $ZBX_SERVER			= '';
          // $ZBX_SERVER_PORT		= '';

          $ZBX_SERVER_NAME		= 'my-zabbix-cloud';

          $IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;
 

  - name: Настройка PHP для Zabbix
    blockinfile:
      path: /etc/php/8.1/fpm/php.ini
      block: |
        post_max_size = 16M
        upload_max_filesize = 2M
        max_execution_time = 300
        max_input_time = 300
        memory_limit = 128M
        date.timezone = Europe/Moscow

  
  - name : Очищаем файл настроек /etc/nginx/conf.d/zabbix.conf
    shell:
      cmd: |
        echo -n > /etc/nginx/conf.d/zabbix.conf

  - name: Настроиваем  Nginx для Zabbix /etc/nginx/conf.d/zabbix.conf
    blockinfile:
      path: /etc/nginx/conf.d/zabbix.conf
      block: |
          server {
              listen 80;
              server_name  {{ server_name }};

              root /usr/share/zabbix;

              index index.php index.html index.htm;

              location / {
                  try_files $uri $uri/ =404;
              }

              location ~ \.php$ {
                  fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
                  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                  include fastcgi_params;
              }

              location ~ /\.ht {
                  deny all;
              }
          }

  - name: Перезапуск сервисов Nginx и PHP-FPM
    systemd:
      name: "{{ item }}"
      state: restarted
      enabled: yes
    with_items:
      - nginx
      - php8.1-fpm

  - name: Печать адреса сервера zabbix
    ansible.builtin.debug:
        msg: "Для работы с zabbix перейдите по адресу http://{{ zabbix_web_ip_address }} логин 'Admin' пароль 'zabbix'"


- name: Установка и настройка zabbix (серверная часть)
  hosts: zabbix_server
  gather_facts: no
  
  become: yes
  tasks:

  - name: Проверка доступности
    ping:

  - name: Перезапуск сервиса Zabbix Server
    systemd:
      name: zabbix-server
      state: restarted
      enabled: yes

  - name: Перезапуск сервиса Zabbix Agent
    systemd:
      name: zabbix-agent
      state: restarted
      enabled: yes

```
</details>

## При необходимости можно запровести востановление или бэкапирование БД севриса мониторинга zabbix
* 9_restore_pg_sql_cloud.yml – поднять файл с бэкапом при использовании облачной БД pgsql Яндекс облака 
  <details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
---
- name: Установка библиотеки psycopg2 для Python
  hosts: zabbix_server
  tasks:
    - name: Установить библиотеку psycopg2
      apt:
        name: python3-psycopg2
        state: present
      become: yes

- name: Востановление базы данных с очисткой данных 
  hosts: zabbix_server
  become: yes
  vars:
    state: present
    db_host_cloud: c-{{ pg_cluster_id }}.rw.mdb.yandexcloud.net  
    db_port_cloud: 6432
    db_name_cloud: "{{ db_name_local }}"
    db_user_cloud: "{{ db_user_local }}"
    db_password_cloud: "{{ db_password_local }}"
  tasks:
  

    - name: Копирование файла zabbix.backup с дампом pgsql 
      copy:
        src: "{{restore_dir}}/{{restore_file}}"
        dest: /tmp/

    - name: Установка и активация расширений uuid-ossp и xml2
      postgresql_query:
        db: "{{ db_name_cloud }}"
        login_user: "{{ db_user_cloud }}"
        login_password: "{{ db_password_cloud }}"
        login_host: "{{ db_host_cloud }}"
        login_port: "{{ db_port_cloud }}"
        query: |
          DO $$
          BEGIN
            -- Проверка и установка расширения uuid-ossp
            IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') THEN
              CREATE EXTENSION "uuid-ossp";
            END IF;

            -- Проверка и установка расширения xml2
            IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'xml2') THEN
              CREATE EXTENSION "xml2";
            END IF;
          END $$;
      register: extensions_setup

    - name: Удаление внешних ключей с таблиц
      command: >
            psql -h {{ db_host_cloud  }} -U {{ db_user_cloud }} -p "{{ db_port_cloud }}" -d {{ db_name_cloud }} -c "{{ item }}"
      with_items: "{{ fk_constraints }}"
      environment:
          PGPASSWORD: "{{ db_password_cloud }}"
      ignore_errors: yes  # Игнорируем ошибки, если ключ уже не существует

    - name: Удаление всех внешних ключей
      postgresql_query:
        db: "{{ db_name_cloud }}"
        login_user: "{{ db_user_cloud }}"
        login_password: "{{ db_password_cloud }}"
        login_host: "{{ db_host_cloud }}"
        login_port: "{{ db_port_cloud }}"
        query: |
          DO $$ DECLARE
              r RECORD;
          BEGIN
              FOR r IN (SELECT conname, conrelid::regclass FROM pg_constraint WHERE contype = 'f') LOOP
                  EXECUTE 'ALTER TABLE ' || r.conrelid || ' DROP CONSTRAINT ' || r.conname;
              END LOOP;
          END $$;


    - name: Получение списка таблиц в схеме public
      postgresql_query:
        db: "{{ db_name_cloud }}"
        login_user: "{{ db_user_cloud }}"
        login_password: "{{ db_password_cloud }}"
        login_host: "{{ db_host_cloud }}"
        login_port: "{{ db_port_cloud }}"
        query: "SELECT tablename FROM pg_tables WHERE schemaname = 'public';"
      register: tables_list
      failed_when: tables_list.query_result is not defined

    
    - name: Проверка наличия таблиц
      debug:
        msg: "Список таблиц: {{ tables_list.query_result }}"
      when: tables_list.query_result is defined

    - name: Очистка данных из таблиц по одной с паузой 1 секунда, чтобы неблокировать поток выполнения
      postgresql_query:
        db: "{{ db_name_cloud }}"
        login_user: "{{ db_user_cloud }}"
        login_password: "{{ db_password_cloud }}"
        login_host: "{{ db_host_cloud }}"
        login_port: "{{ db_port_cloud }}"
        query: "TRUNCATE TABLE {{ item.tablename }} CASCADE;"
      loop: "{{ tables_list.query_result }}"
      loop_control:
        pause: 1  # Пауза 1 секунда между выполнением команд


    - name: Временное отключение проверок внешних ключей
      postgresql_query:
        db: "{{ db_name_cloud }}"
        login_user: "{{ db_user_cloud }}"
        login_password: "{{ db_password_cloud }}"
        login_host: "{{ db_host_cloud }}"
        login_port: "{{ db_port_cloud }}"
        query: "SET session_replication_role = replica;"


    - name: Восстановление базы данных из дампа
      command: >
        pg_restore -h "{{ db_host_cloud }}" -p "{{ db_port_cloud }}" -U "{{ db_user_cloud }}" -d "{{ db_name_cloud }}" --data-only --disable-triggers --exit-on-error -v /tmp/zabbix.backup
      environment:
        PGPASSWORD: "{{ db_password_cloud }}"
      register: restore_result



    - name: Включение проверок внешних ключей обратно
      postgresql_query:
        db: "{{ db_name_cloud }}"
        login_user: "{{ db_user_cloud }}"
        login_password: "{{ db_password_cloud }}"
        login_host: "{{ db_host_cloud }}"
        login_port: "{{ db_port_cloud }}"
        query: "SET session_replication_role = DEFAULT;"

    

```
</details>

* 8_backup_pg_sql_cloud.yml – создать бэкап при использовании облачной БД pgsql Яндекс облака 
  <details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
---

- name: Бэкапирование базы данных 
  hosts: zabbix_server 
  gather_facts: yes
  vars:
    backup_file: "/tmp/{{backup_f}}"
    timestamp: "{{ ansible_date_time.iso8601 }}"
    new_name: "/tmp/{{ db_name_local }}_{{ timestamp }}dump.backup"
    db_host_cloud: c-{{ pg_cluster_id }}.rw.mdb.yandexcloud.net  
    db_port_cloud: 6432
    db_name_cloud: "{{ db_name_local }}"
    db_user_cloud: "{{ db_user_local }}"
    db_password_cloud: "{{ db_password_local }}"
  tasks:


     
    - name: Проверяем, существует ли файл на удаленном сервере
      ansible.builtin.stat:
        path: "{{ backup_file }}"
      register: file_stat
      become: yes

    - name: Удаляем файл, если он существует
      ansible.builtin.file:
        path: "{{ backup_file }}"
        state: absent
      become: yes
      when: file_stat.stat.exists
    
    - name: Создаем дамп базы данных
      command: >
        pg_dump -h {{ db_host_cloud }} -p {{ db_port_cloud }} -U {{ db_user_cloud }} -F c -b -v -f "{{ backup_file }}" "{{ db_name_cloud}}"
      environment:
        PGPASSWORD: "{{ db_password_cloud }}"   
      register: dump_result

    - name: Проверяем создан ли бэкап
      debug:
        msg: "Дамп успешно создан: {{ backup_file }}"
      when: dump_result.rc == 0

    - name: Ошибка создания бэкапа
      debug:
        msg: "Ошибка создания базы данных {{ db_name_local }}"
      when: dump_result.rc != 0

    - name: Получаем файл дамп базы данных с удаленного сервера
      ansible.builtin.fetch:
        src: "{{ backup_file }}"
        dest: templates2/
        flat: yes
      become: yes



    - name: переименовываем файл дампа pgsql, добавляем дата время
      shell:
        cmd: |
          mv "{{ backup_file }}" "{{new_name}}"



    - name: Получаем файл дамп базы данных с удаленного сервера время и дата
      ansible.builtin.fetch:
        src: "{{new_name}}"
        dest: "templates2/rezerv/"
        flat: yes
      become: yes
```
</details>





 