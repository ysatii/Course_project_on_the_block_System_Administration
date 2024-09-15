# Курсовой проект по блоку "Системное администрирование"

## Анализ задания

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)

Для успешного выполнения задачи, ее небодимо разбить на на этапы
1.	Запуск необходимого количества виртуальных машин, балансиров, сетей с использованием terraform
2.	Установка необходимых скриптов с использованием ansible
3.	Проверка работоспособности
4.	Создание резервных копий 
5.	Проверка на соответствование минимальным требованиям 

## Этап 1. Terraform. Создание инфраструктуры.
1.	Необходимо создать  6 виртуальных машин и один load balansir
- web 1 
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

## Этап 2 использование ansible Для установки программного обеспеения
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



[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)