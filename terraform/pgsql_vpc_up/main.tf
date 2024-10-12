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

output "zabbix_nat_ip_address" {
  value = yandex_compute_instance.zabbix-server.network_interface.0.nat_ip_address
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

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.web-sub-b.id
    name = "cl2"
    replication_source_name = "cl1"
    assign_public_ip = false
  }

  #  host {
  #  zone      = "ru-central1-b"
  #  subnet_id = yandex_vpc_subnet.web-sub-b.id
  #  name = "cl3"
  #  replication_source_name = "cl1"
  #  assign_public_ip = false
  #}
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
}

output "postgresql_cluster_id" {
  value = yandex_mdb_postgresql_cluster.postgres.id
}

resource "local_file" "tf_ansible_vars_file" {
  content = <<-DOC
    pg_cluster_id: ${yandex_mdb_postgresql_cluster.postgres.id}
    pg_admin_password: ${var.pg_admin_password}
    bastion_host: ${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} 
    zabbix_server_ip: ${yandex_compute_instance.zabbix-server.network_interface.0.nat_ip_address}
    DOC
  filename = "../../ansible/group_vars/all.yml"
}