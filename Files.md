# Курсовой проект по блоку "Системное администрирование"

 
## Файловая структура проекта
[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)

* ansible - Папка содержит скрипты для автоматической установки П.О., установочные пакеты, файлы настроект, HTML страницы проекта  
  * files/packages/  - Папка содержит пакеты *.deb для установки на сервера
  * group_vars - Групповые переменные ansible
  * templates - Папка содержит файлы настроек установленных пакетов
  * templates2 - Папка содержит Файл HTML для второго сервера если нужно проверить работу балансировщика явно!
  * 1_elk.yml
  * 2_web.yml
  * 3_conf_zabbix_copy.yml
  * 4_zabbix_copy_all.yml
  * 5_zabbix_bastion.yml
  * ansible/ansible.cfg
  * ansible/inventory.ini
* img - Папка содержит рисунки, смены, принт-скрины
* terraform - Папка содержит скрипты терраформ
  * image_backup
    * metadata
  * metadata
  * vpc_up
    * metadata
* .gitignore
* Ansible.md - Файл содержит описание скриптов ansible, какое П.О. и на какие машины будет установлено
* Analysis.md - Файл содержит анализ задачи 
* Backup.md - Файл содержит код terraform для бэкапирования виртуальных машин
* Files.md - Файл содержит описание файловой структуры проекта
* Infrastructure.md - Файл содержит код terraform для поднятия инфраструктуры 
* Logs.md - Файл содержит отчет о системе логирования
* Monitoring.md - Файл содержит отчет о системе мониторинга
* Network.md - Файл содержит отчет о создания виртуалььной сети, таблиц маршрутизации, групп безопастности
* README.md - основной файл отчета
* Sait.md - Файл содержит отчет о работе балнсировщика и WEB-сервиса
* test
* test.pub

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)