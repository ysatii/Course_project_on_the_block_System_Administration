module "vpc_up" {
  source = "./vpc_up"  
  yandex_cloud_token = var.yandex_cloud_token
}

module "image_backup" {
  source = "./image_backup" 
  yandex_cloud_token = var.yandex_cloud_token 
}

variable "yandex_cloud_token" {
 type        = string
 }


output "bastion_nat_ip_address" {
  value = module.vpc_up.bastion_nat_ip_address
}

output "kibana_nat_ip_address" {
  value = module.vpc_up.kibana_nat_ip_address
}

output "zabbix_nat_ip_address" {
  value = module.vpc_up.zabbix_nat_ip_address
}
