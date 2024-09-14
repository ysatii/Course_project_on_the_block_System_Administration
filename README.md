# Курсовой проект по блоку "Системное администрирование"

Для успешного выполнения задачи, ее небодимо разбить на на этапы
1.	Запуск необходимого количества виртуальных машин, балансиров, сетей с использованием terraform
2.	Установка необходимых скриптов с использованием ansible
3.	Проверка работоспособности
4.	Создание резервных копий 
5.	Проверка на соответствование минимальным требованиям 

## Этап 1. Terraform. 
1.	Необходимо создать  6 виртуальных машин и один load balansir
- web1 
- web 2
- elasticsearch
- zabbix
- kibana
- bastion
- load balansir – передача трафика на web1 и web2 

2. схема сети
![рис 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/network_diagram.jpg)

Создать сеть и разделить ее на подсети
- общедоступная сеть, zabbix, kibana, load balancer, bastion
- закрытый сегмент 1, web1, elasticsearch, 
- закрытый сегмент 2, web2

3.	Создание security group, для пропуска нужного трафика
- web, принимаем трафик 80 порт, трафик 22 от bastion
    - web 2, принимаем трафик 80 порт, трафик 22 от bastion
    - elasticsearch, принимаем трафик  порт, трафик 22 от bastion, обмен трафиком с kibana
    - zabbix, принимаем трафик  порт, трафик 22 от bastion
    - kibana принимаем трафик  порт, трафик 22 от bastion
     bastion – только 22 порт , фактически служит как прокси 22 порта для сети
     Каждая машина в сети имеет днс имя для общения, можно обращаться по нему

4.	Резервное копирование, снятие снепшотов и установка расписания.  Время в расписании  устанавливается по GMT+0 

5. провести проверку работоспобности.

## Этап 2 использование ansible 
На каждой виртуальной машине должно быть установлено программное обеспечение согласно списка 
  - web,  nginx, zabbix agen, index1
    - web 2, nginx, zabbix agent,index2
    - elasticsearch, elasticsearch, zabbix agent
    - zabbix, zabbix,appatch, pgsql,php zabbix agent 
    - kibana, kibana zabbix agent
    - bastion , zabbix agent
Программные продукты elasticsearch, zabbix, kibana – можно установить скопировав пакеты на соответствующие сервера и запустить их установку либо использовать докер
Можно разделить скрипты ansible на три этапа
1.	Установка и настройка  web серверов
2.	Установка и настройка kibana и elasticsearch, ELK -Стек
3.	Развертывание zabbix 
-	Установка и настройка zabbix для работы с БД pgsql
-	Запуск и настройка apache, php 
-	Поднять дамп БД. Для автоматизации процесса можем заранее установить  zabbix, произвести необходимые настройки 
БД  PGSQL, можно поднять на одной машине с  zabbix, либо использовать кластерную версию на яндекс облаке. 



В данный моент времени реализован terrafor скрпит для создания виртуальных машин 
## Развертывание инфраструктуры:
из папки terraform
```sh
terraform init
terraform apply -target=module.vpc_up --auto-approve
```

image_backup
```sh
cd image_backup
terraform apply --auto-approve
```


Запускаем плейбук web.yml из директории ansible.
```sh
ansible-playbook web.yml
```
В результате работы плейбука будет настроено:
- веб сервер nginx
- веб страница index.html и index.html  на webserver2
- 

ssh -o ProxyCommand="ssh -i /home/lamer/.ssh/test -W %h:%p test@89.169.152.12" test@zabbix-server.ru-central1.internal  


Отчет по работе 

* [Сайт](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Sait.md)
* [Мониторинг](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Monitoring.md)
* [Логи](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Logs.md)
* [Сеть](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/network.md.md)
* [Резервное копирование](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/backup.md.md)
* Дополнительно


 


 