# Курсовой проект по блоку "Системное администрирование"

## Сайт 

## Код для создания  Target Group, Backend Group, HTTP router, Application load balancer

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
