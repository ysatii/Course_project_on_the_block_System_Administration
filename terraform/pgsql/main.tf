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

 



resource "yandex_vpc_route_table" "bastion-route" {
  name        = "bastion-route"

  depends_on = [ yandex_compute_instance.bastion ]

  network_id = yandex_vpc_network.bastionet.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.bastion.network_interface.0.ip_address
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
    version = 15
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