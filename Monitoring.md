# Курсовой проект по блоку "Системное администрирование"

 
## Мониторинг
[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)

### Произведем установку Zabbix  
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_1.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_2.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_3.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_4.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_5.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_6.jpg)

### Добавим все машины в систему мониторинга  
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_7.jpg)

### Все агенты Zabbix в сети и передают данные
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_8.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_9.jpg)

### Создадим свои дашборды Утилизация памяти, уилизация процессора
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_10.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_11.jpg)

### Создаем дашборд утилизация диска
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_12.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_13.jpg)

### Мониторинг сервиса nginx  
https://mhost.by/knowledgebase/204/monitoring-nginx-s-pomoshchiu-zabbix.html?ysclid=m19lwfsgj1832761257 
Статья описывает что нужно сделать что бы корректно получать данные
в качестве примера на машине webserver1.ru-central1.internal
создадим файл  /etc/nginx/conf.d/stub_status.conf 
с содеримым 
```
server {
    listen 127.0.0.1:80;
    server_name 127.0.0.1;
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }

    location = /basic_status {
        stub_status;
        allow 127.0.0.1;
        allow ::1;
        deny all;
    }
}
```


Далее произвести проверку корректности кофигурации, привести перезагрузку сервиса  
```
nginx -t
systemctl restart nginx
systemctl status nginx
```


строки  
```
error_log /var/log/nginx/error.log;
access_log /var/log/nginx/access.log;
```
нужно заменить на 
```
 /etc/nginx/nginx.conf
 log_format main '$remote_addr - $remote_user [$time_local] "$request" ' '$status $body_bytes_sent 
 "$http_referer" ' ' "$http_user_agent" "$http_x_forwarded_for"';
 error_log /var/log/nginx/error.log notice;
 access_log /var/log/nginx/access.log main;
 ```

 Далее произвести проверку корректности кофигурации, привести перезагрузку сервиса 
 ```
nginx -t
systemctl restart nginx
systemctl status nginx
systemctl restart nginx
```




Добавим новый сервер в систему мониторинга, установим шаблон "Nginx by Zabbix agent"
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_19.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_20.jpg)

![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_14.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_15.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_16.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_17.jpg)
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/zabbix1_18.jpg)

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)