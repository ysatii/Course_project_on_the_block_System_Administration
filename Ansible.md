# Курсовой проект по блоку "Системное администрирование"

## Скрипты ansible

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)

  * 1_elk.yml - Скрипт дя установки стэка ELK  
  * 2_web.yml - Скрипт установливает скрпиты на WEB сервера  
  * 3_conf_zabbix_copy.yml - установка пакета zabbix на машину zabbix-server  
  * 4_zabbix_copy_all.yml - установка zabbix агента на все оставшиеся машины кроме zabbix сервер  
  * 5_pgsql_zabbix.yml - установка zabbix с использованием облачной PGSQL
  * 6_backup_pg_sql_local.yml - Бекапирование базы данных zabbix  
  * 7_restore_pg_sql_local.yml - востановление базы данных zabbix  
  * requirements.yml - файл уставливает нужные для работы коллекции community.postgresql collection, показываем 
  что можем работать не только с встроенными функциями но и расширить функционал за счет коллекций ansible

## пример запуска ansible-playbook из папки ansible

```sh
ansible-playbook 1_elk.yml
```


## 1_elk.yml - Скрипт дя установки стэка ELK
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
---
- name: Настройка и установка elasticsearch
  tags: elasticsearch
  hosts: elasticsearch
  gather_facts: no
  become: yes
  tasks:

    - name: Проверка доступности
      ping:
      register: ping_result

    - name: Копирование пакета elastics
      copy:
        src: packages/{{ pkg_elastic }}
        dest: /tmp/

    - name: Установка пакета elasticsearch .deb
      apt:
        deb: "/tmp/{{ pkg_elastic }}"
        state: present
    
    - name: Копирование файла конфигурации elasticsearch.yml
      copy:
        src: templates/elasticsearch.yml
        mode: 0640
        dest: /etc/elasticsearch/elasticsearch.yml

    - name: переззапуск elasticsearch
      service:
        name: elasticsearch
        state: restarted
        enabled: true

- name: Настройка и установка kibana
  tags: kibana
  hosts: kibana
  gather_facts: no
  become: yes
  tasks:
    - name: Копирование пакета kibana
      copy:
        src: packages/{{ pkg_kibana }}
        dest: /tmp/

    - name: Установка пакета kibana .deb
      apt:
        deb: "/tmp/{{ pkg_kibana }}"
        state: present

    - name: Копирование файла конфигурации kibana.yml
      template:
        src: templates/kibana.yml.j2
        mode: 0640
        dest: /etc/kibana/kibana.yml

    - name: перезапуск kibana
      systemd:
        name: kibana
        state: restarted
        enabled: true
...
```
</details>
Скрипт  скопирует утановит и настроет elasticsearch, kibana на elastic.ru-central1.internal и kibana-server.ru-central1.internal соостветственно!


## 2_web.yml - Скрипт установливает П.О. на WEB сервера
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
---
- name: Установка пакетов на web сервера
  hosts: web_servers
  gather_facts: no
  become: yes
  tasks:

    - name: Проверка доступности
      ping:
      register: ping_result

    - name: Обновление кеш
      apt:
        update_cache: yes

    - name: Установка nginx
      apt:
        name: nginx
        state: present

    - name: Копирование страницы index.html на сервера 
      copy:
        src: templates/index.html
        dest: /var/www/html/
    
    - name: перзапуск nginx
      service:
        name: nginx
        state: restarted
    
    - name: Копирование filebeat
      copy:
        src: packages/{{ pkg_name }}
        dest: /tmp/
    
    - name: Установка filebeat .deb
      apt:
        deb: "/tmp/{{ pkg_name }}"
        state: present

    - name: Копирование файла настроек filebeat.yml
      template:
        src: templates/filebeat.yml.j2
        mode: 0644
        dest: /etc/filebeat/filebeat.yml

    - name: Конфигурирование nginx модуля
      copy:
        dest: /etc/filebeat/modules.d/nginx.yml.disabled
        content: |
          - module: nginx
            # Access logs
            access:
              enabled: true

            # Error logs
            error:
              enabled: true
        mode: 0644
     
    - name: Активируе nginx модуль для filebeat
      shell:
        cmd:  filebeat setup --dashboards && filebeat modules enable system nginx
        
    - name: перезапуск демона systemd
      shell:
        cmd: systemctl daemon-reload
    
    - name: Перезапускаемм Filebeat
      systemd:
        name: filebeat.service
        state: restarted
        enabled: true

 
- name: Мониторинг сервера nginx в zabbix
  hosts: web_servers
  gather_facts: no
  become: yes
  tasks:
    - name: Копируем файл конфигурации stub_status.conf
      template:
        src: templates2/stub_status.conf
        mode: 0644
        dest:  /etc/nginx/conf.d/stub_status.conf

    - name:  Добавляем настройки в /etc/nginx/nginx.conf
      blockinfile:
        path: /etc/nginx/nginx.conf
        marker: "access_log /var/log/nginx/access.log;"
        insertafter: "access_log /var/log/nginx/access.log;"
        block: "{{ lookup('file', 'templates2/nginx.conf') }}"
    
    - name: Убираем строку из error.log
      lineinfile:
        path: /etc/nginx/nginx.conf
        state: absent
        regexp: '^% error_log /var/log/nginx/error.log;'

    - name: Убираем строку из  access.log
      lineinfile:
        path: /etc/nginx/nginx.conf
        state: absent
        regexp: '^%access_log /var/log/nginx/access.log;'

    - name: Перезапускаем nginx
      systemd:
        name: nginx.service
        state: restarted
        enabled: true
...    
```
</details>

Скрипт установит и настроит nginx, filebeat произведет перзагрузку обоих сервисов.  
Также есть закоментированная часть кода для проверки корректности работы балансировщика! 
на второй веб серве будет загружен скрипт, что позвлит понимать с какого из веб серверов идет ответ!


## 3_conf_zabbix_copy.yml - установка пакета zabbix на машину zabbix-server
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
- name: Установка и настройка zabbix 
  hosts: zabbix_server
  gather_facts: no
  vars:
    host: "localhost"                     # адрес хоста
    db_port: 5432                         # PostgreSQL (по умолчанию 5432)
    db_name: "zabbix"                     # базы данных
    db_user: "{{ zabbix_user }}"          # пользователя базы данных
    db_password: "{{ zabbix_password }}"  # пароль пользователя базы данных
  become: yes
  tasks:

  - name: Проверка доступности
    ping:
    register: ping_result
 
  - name: Обновление системы и установка зависимостей
    apt:
      update_cache: yes
      name: ['wget', 'curl', 'nginx', 'postgresql', 'postgresql-contrib', 'php-fpm', 'php-pgsql', 'php-bcmath', 'php-mbstring', 'php-gd', 'php-xml', 'mc']
      state: present
   
 
  
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

  
  - name: Установка  Zabbix Server и компонентов
    become: yes
    apt:
      name: ['zabbix-server-pgsql', 'zabbix-frontend-php', 'zabbix-nginx-conf', 'zabbix-agent', 'zabbix-sql-scripts']
      state: present

          # --------------------------------------------------------------

  - name: Создаем пользователя pgsql и базы данных
    shell:
     cmd: |
        su - postgres -c "psql --command \"CREATE USER {{ zabbix_user }} WITH PASSWORD '{{ zabbix_password }}';\"" && \
        su - postgres -c "psql --command \"CREATE DATABASE zabbix OWNER {{ zabbix_user }};\""         
        

 
  - name: Импортировать начальную структуру базы данных pgsql 
    shell: |
      zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u {{ zabbix_user }} -p {{ zabbix_password }} psql zabbix  | sudo -u {{ zabbix_user }} -p {{ zabbix_password }} psql zabbix
  

  

   #  ----------------------------------------
   
  - name: Копируем zabbix_server.conf файл настроек zabbix
    template:
      src: templates/zabbix_server.conf.j2
      mode: 0644
      dest: /etc/zabbix/zabbix_server.conf
  
    
  - name: Устанавливаем пароль пользователя pgsql в файле /etc/zabbix/zabbix_server.conf
    lineinfile:
       dest: /etc/zabbix/zabbix_server.conf
       regexp: '^# DBPassword='
       line: 'DBPassword={{ db_password }}' 

  - name : Очищаем файл настроек web интерфейса etc/zabbix/web/zabbix.conf.php
    shell:
      cmd: |
        echo -n > /etc/zabbix/web/zabbix.conf.php

  - name: Генерируем содержимое файла настроек web интерфейса /etc/zabbix/web/zabbix.conf.php
    become: yes
    blockinfile:
       path: /etc/zabbix/web/zabbix.conf.php
       block: |
         <?php
         // Zabbix GUI configuration file.

          $DB['TYPE']				= 'POSTGRESQL';
          $DB['SERVER']			= '{{ host }}';
          $DB['DATABASE']		= '{{ db_name }}';
          $DB['USER']			= '{{ db_user }}';
          $DB['PASSWORD']		= '{{ db_password }}';

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

          $ZBX_SERVER_NAME		= 'my-zabbix';

          $IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;
 
  
  
  - name: Настроиваем  PHP для Zabbix /etc/php/8.1/fpm/php.ini
    become: yes
    blockinfile:
       path: /etc/php/8.1/fpm/php.ini
       block: |
         post_max_size = 16M
         upload_max_filesize = 2M
         max_execution_time = 300
         max_input_time = 300
         memory_limit = 128M
         date.timezone = Europe/Moscow

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

  - name: Перезапускаем сервисы Zabbix и Nginx
    become: yes
    systemd:
        name: "{{ item }}"
        state: restarted
        enabled: true  
    with_items:
        - zabbix-server
        - zabbix-agent
        - nginx
        - php8.1-fpm

  - name: Печать адреса сервера zabbix
    ansible.builtin.debug:
        msg: "Для работы с zabbix перейдите по адресу http://{{ zabbix_server_ip }} логин 'Admin' пароль 'zabbix'"

```
</details>
 Скрипт подготовит и настроет zabbix_server для работы, установит postgresql
 установит zabbix агент на веб сервера


## 4_zabbix_copy_all.yml - установка zabbix агента на все оставшиеся машины кроме zabbix сервер
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
- name: Установка Zabbix агента на сервера
  hosts: all-servers
  gather_facts: no
  become: yes
  tasks:
    - name: Проверка доступности
      ping:
      register: ping_result

    - name: Обновление кеш
      apt:
        update_cache: yes
        
    - name: Копируем zabbix пакет
      copy:
        src: packages/{{ pkg_zabbix }}
        dest: /tmp/

    - name: Устанавливаем zabbix репозиторий
      command: dpkg -i /tmp/{{ pkg_zabbix }}

    - name: Устанавливаем zabbix-agent
      apt:
        name: zabbix-agent
        state: present
        update_cache: yes

    - name: Добавляем IP zabbix сервера
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'Server=127.0.0.1'
        replace: 'Server={{ zabbix_server }}'

    - name: Добавляем IP активного сервера
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'ServerActive=127.0.0.1'
        replace: 'ServerActive={{ zabbix_server }}'

    - name: Перезапускаем zabbix agent
      systemd:
        name: zabbix-agent
        state: restarted
        enabled: true   

```
</details>

## 5_pgsql_zabbix.yml - установка zabbix с использованием облачной PGSQL 
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
 - name: Установка zabbix сервера с испольгованием pgsql кластера yandex cloud
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
 
  - name: Обновление системы и установка зависимостей postgresql не устанавливаем 
    apt:
      update_cache: yes
      name: ['wget', 'curl', 'nginx', 'postgresql-contrib', 'php-fpm', 'php-pgsql', 'php-bcmath', 'php-mbstring', 'php-gd', 'php-xml', 'mc']
      state: present

  - name: Копируем zabbix пакет
    copy:
      src: packages/{{ pkg_zabbix }}
      dest: /tmp/

  - name: Устанавливаем zabbix репозиторий 
    command: dpkg -i /tmp/{{ pkg_zabbix }}

  - name: обновляем кеш системы
    apt:
      update_cache: yes

   
  - name: Установливаем Zabbix Server и компоненты
    become: yes
    apt:
      name: ['zabbix-server-pgsql', 'zabbix-frontend-php', 'zabbix-nginx-conf', 'zabbix-agent', 'zabbix-sql-scripts']
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


  - name: Дамп базы данных поднят удачно
    ansible.builtin.debug:
        msg: "Database imported successfully!"

  - name: "Ansible | Print a variable"
    debug:
      msg: "Использован кластер облачной yandex-cloud со следующими настройками Хост = {{ db_host_cloud }}, имя базы данных = {{ db_name_cloud }},  пользователь базы= {{ db_user_cloud }}, пароль базы = {{ db_password_cloud }}, db_port = {{db_port_cloud}}"
 
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

  - name : Очищаем файл настроек web интерйейса zabbix.conf.php
    shell:
      cmd: |
        echo -n > /etc/zabbix/web/zabbix.conf.php


  - name: Генеририуем соержимое йайла настроек web интерфейса /etc/zabbix/web/zabbix.conf.php
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
 
  - name: Настраиваем PHP для работы Zabbix
    become: yes
    blockinfile:
       path: /etc/php/8.1/fpm/php.ini
       block: |
         post_max_size = 16M
         upload_max_filesize = 2M
         max_execution_time = 300
         max_input_time = 300
         memory_limit = 128M
         date.timezone = Europe/Moscow

 
  - name: Настроиваем  Nginx для работы с Zabbix
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

  - name: Перезапускаем сервисы Zabbix и Nginx
    become: yes
    systemd:
        name: "{{ item }}"
        state: restarted
        enabled: true  
    with_items:
        - zabbix-server
        - zabbix-agent
        - nginx
        - php8.1-fpm

  - name: Печать адреса сервера zabbix
    ansible.builtin.debug:
        msg: "Для работы с zabbix перейдите по адресу {{ zabbix_server_ip }} логин 'Admin' пароль 'zabbix'"
```
</details>

## 6_backup_pg_sql_local.yml - Бэкапирование базы данных zabbix
позволяет сохранить наработки при уничтожении облака
 
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
        pg_dump -h {{ db_host_local }} -p {{ db_port_local }} -U {{ db_user_local }} -F c -b -v -f "{{ backup_file }}" "{{ db_name_local}}"
      environment:
        PGPASSWORD: "{{ db_password_local }}"   
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



    - name: Периеименовываем файл имя бд + дата и время создания
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

## 7_restore_pg_sql_local.yml - Востановление базы данных zabbix 
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
---
- name: Востновление дампа базы данных
  hosts: zabbix_server
  become: yes
  vars:
    ansible_user: root
  tasks:
  - name: Копирование файла zabbix.backup с дампом pgsql 
    copy:
      src: "{{restore_dir}}/{{restore_file}}"
      dest: /tmp/

  - name: Создаем файл.pgpass file for PostgreSQL authentication
    copy:
        dest: /{{ ansible_user }}/.pgpass
        content: "localhost:5432:zabbix:postgres:12345678\n"
        owner: "{{ ansible_user }}"
        mode: '0600'

  - name: Создаем run_commands.sh скрипт
    copy:
        dest: /{{ ansible_user }}/run_commands.sh
        content: |
          #!/bin/bash

          # Подключаемся к PostgreSQL и выполняем команды
          sudo -u postgres psql << EOF
          ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, INSERT, DELETE, UPDATE ON TABLES TO zabbix WITH GRANT OPTION;
          CREATE ROLE mdb_replication;
          CREATE ROLE mdb_admin;
          CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
          CREATE EXTENSION IF NOT EXISTS "xml2";
          ALTER USER zabbix WITH SUPERUSER;
          SELECT * FROM pg_available_extensions WHERE name = 'xml2';
          ALTER USER postgres WITH PASSWORD '12345678';
          EOF

          # Выполняем восстановление из бэкапа
          pg_restore -h localhost -p 5432 -U postgres -d zabbix --clean --if-exists -v /tmp/zabbix.backup
        owner: "{{ ansible_user }}"
        mode: '0755'

  - name: Execute run_commands.sh script
    command: /{{ ansible_user }}/run_commands.sh
    become: yes
    become_user: "{{ ansible_user }}"
```
</details>


## requirements.yml - файл уставливает нужные для работы коллекции community.postgresql collection 
## необходимо для play-book 10_zabbix_web.yml и ряду других стриптов, если у Вас нет коллекий запустите этот файл для установки коллекций
 https://docs.ansible.com/ansible/latest/collections/community/postgresql/postgresql_db_module.html#ansible-collections-community-postgresql-postgresql-db-module
<detail>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
collections:
  # Установите коллекцию из Ansible Galaxy.
  - name:  community.postgresql collection 
    version: 3.5.0
    source: https://galaxy.ansible.com
```
</details>



* [Файл инвентаризации](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/ansible/inventory.ini)
 Файл ansible/inventory.ini  Содержит необходимые настройки 

секция  
[all:vars]
/# bastion_host=84.201.159.142  
/# zabbix_server_ip=89.169.147.200  
/# эти значения берем из файла /ansible/group_vars/all.yml его создаст terraform!  

Каждый раз при запуске ansible-playbook адреса bastion_host и zabbix_server берем из файла /ansible/group_vars/all.yml



