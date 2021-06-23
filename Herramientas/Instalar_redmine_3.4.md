Instalación de Redmine

Índice

#Actualización e Instalación de requisitos
Base de Datos (MARIADB/POSTGRESQL)
#MARIADB
#POSTGRESQL
#Requisitos RUBY
#Creación del Usuario REDMINE
*** INSTALACIÓN DE REDMINE ***
Descarga de Redmine
Configuración base de datos





#Se deshabilita NetworkManager
chkconfig NetworkManager off

#Se habilita network (por si las moscas)
chkconfig network on

#Se pone selinux en permissive (en vez de enforcing)
vi /etc/selinux/config

#Actualización e Instalación de requisitos
yum update -y

#Reiniciamos
reboot

#Requisitos
yum -y groupinstall "Development Tools"
yum -y install openssl-devel readline-devel zlib-devel curl-devel libyaml-devel ImageMagick ImageMagick-devel wget nano mc git epel-release


Base de Datos (MARIADB/POSTGRESQL)

#MARIADB

#Se instala MariaDB
yum install mariadb-server mariadb-devel

#Configuraciones para utf8 
nano /etc/my.cnf.d/server.cnf 

#Modificar la sección:
###
 [Mysqld]
 character-set-server = utf8
####

#nano /etc/my.cnf.d/mysql-clients.cnf 



Modificar la sección:

###
 [Mysql]
 default-character-set = utf8
 show-warnings
###

#Se inicia y habilita MARIADB
systemctl start mariadb.service
systemctl status mariadb
systemctl enable mariadb.service

#Instalación Segura
mysql_secure_installation 

Creación de la Base de Datos
mysql -uroot -p
  CREATE DATABASE xxx;
  grant all on xxx.* to 'yyy'@'localhost' identified by 'zzz' with grant option;
  flush privileges;


#POSTGRESQL
#Instalamos repositorio y paquetes postgres
yum -y install centos-release-scl
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum -y install postgresql11-libs postgresql11-devel

#Inicializamos la base de datos
/usr/pgsql-9.6/bin/postgresql96-setup initdb

#Iniciamos y habilitamos postgres
 systemctl start postgresql-9.6
 systemctl enable postgresql-9.6

#Seteamos password del usuario postgres
su - postgres
psql
\password postgres

#Creamos la Base de Datos (como usuario postgres)
psql -U postgres -c "CREATE DATABASE redmine WITH  OWNER = postgres ENCODING = 'UTF8' LC_COLLATE = 'es_PY.UTF-8' LC_CTYPE = 'es_PY.UTF-8' TEMPLATE=template0;"

#Configuramos la autenticación como md5 en todos los casos (reemplazar peer e ident por md5).
vi /var/lib/pgsql/9.6/data/pg_hba.conf

#Reiniciamos postgres
systemctl restart postgresql-9.6
#Requisitos RUBY
#COMO ROOT
cd /tmp
wget -O ruby-install-0.8.0.tar.gz https://github.com/postmodern/ruby-install/archive/v0.8.0.tar.gz
tar -xzvf ruby-install-0.8.0.tar.gz
cd ruby-install-0.8.0
make install
ruby-install ruby 2.4
export PATH=$PATH:/opt/rubies/ruby-2.4.10/bin
cd && rm -Rf /tmp/ruby-install-0.7.0

Adicionalmente agregamos “:/opt/rubies/ruby-2.4.10/bin” en /etc/enviroment y /etc/sudoers al final de la linea “secure_path”, esto a fin de permitir la ejecución con sudo de comandos ruby, gem, etc. Una vez realizado esto reiniciamos:
sudo reboot

#si es centos, poner en el archivo /etc/profile.d/ruby.sh:

export PATH=$PATH:/opt/rubies/ruby-2.4.10/bin
#Creación del Usuario REDMINE
useradd redmine
passwd redmine


*** INSTALACIÓN DE REDMINE ***
Descarga de Redmine
cd /opt
wget http://www.redmine.org/releases/redmine-3.4.13.tar.gz
tar zxf redmine-3.4.13.tar.gz 
mv redmine-3.4.13 redmine
rm redmine-3.4.13.tar.gz 

Configuración base de datos
#Copiamos los archivos de configuración
cd redmine/config
cp database.yml.example database.yml

#Editamos el archivo de configuración que acabamos de crear, y modificamos la sección correspondiente. Comentamos el resto:
nano database.yml
MYSQL
production:
  adapter: mysql2
  database: xxx
  host: localhost
  username: yyy
  password: "zzzz"
  encoding: utf8

POSTGRES
production:
  adapter: postgresql
  database: redmine
  host: localhost
  username: postgres
  password: "cambiar123"


#Se modifican los permisos
chmod 600 database.yml

#Configuración de la aplicación
#En este archivo se configura el correo y los path de los distintos utilitarios, usualmente no se requiere modificaciones.

cp configuration.yml.example configuration.yml
nano configuration.yml
chmod 600 configuration.yml
#PERMISOS
chown -R redmine.redmine /opt/redmine
#Damos permisos de elevacion de privilegios para el usuario redmine
usermod -aG wheel redmine

#SE CONTINUA LA INSTALACION como el usuario redmine
su - redmine
cd /opt/redmine/
gem list

#Instalación de bundler 1.17.3 (compatibilidad ruby 2.4.6)
sudo gem install bundler -v 1.17.3 --no-rdoc --no-ri

##PARA POSTGRES
bundle config build.pg --with-pg-config=/usr/pgsql-9.6/bin/pg_config
bundle install --path vendor/bundler --without development test

#Se genera el token del aplicativo
bundle exec rake generate_secret_token

#Creacion de la estructura de la base de datos
bundle exec rake db:migrate RAILS_ENV=production




#*** GENERACIÓN DEL SERVICIO ***

#Instalación de Unicorn
su - redmine
cd /opt/redmine

#Creacion del archivo Gemfile.local
nano Gemfile.local

#Dentro del archivo agregar:
#####
gem "unicorn"
#####

#Instalar unicorn
bundle update

#Para probar:
bundle exec unicorn_rails -l 3000 -E production


#CREAR ARCHIVO DE CONFIGURACION DE UNICORN
cd /opt/redmine/config
wget http://unicorn.bogomips.org/examples/unicorn.conf.rb
mv unicorn.conf.rb unicorn.rb
nano unicorn.rb

#Se modifica las siguientes lineas del archivo a gusto:

#####
worker_processes 4							#Cantidad de procesos esclavos de unicorn
user "redmine", "redmine"						#Usuario con el que se corre la aplicacion
working_directory "/opt/redmine"					#Directorio de trabajo
listen "/opt/redmine/tmp/sockets/unicorn.sock", :backlog => 32		#Socket con el cual nginx se comunicara
listen 8080, :tcp_nopush => true					#Puerto de Unicorn
timeout 180								#Tiempo de espera de las operaciones de Unicorn
pid "/opt/redmine/tmp/pids/unicorn.pid"					#PID
stderr_path "/opt/redmine/log/unicorn.log"				#Log ERROR
stdout_path "/opt/redmine/log/unicorn.log"				#Log 
#####



#*** GENERACION del Servicio ***
sudo nano /etc/systemd/system/redmine-unicorn.service


#Contenido del archivo:
#************************************************************************

[Unit]
Description=Redmine Unicorn Server

Before=network-pre.target
Wants=network-pre.target

DefaultDependencies=no
Requires=local-fs.target
After=local-fs.target


[Service]
WorkingDirectory=/opt/redmine
Environment=RAILS_ENV=production
SyslogIdentifier=redmine-unicorn
PIDFile=/opt/redmine/tmp/pids/unicorn.pid

ExecStart=/opt/rubies/ruby-2.4.6/bin/bundle exec "unicorn_rails -c config/unicorn.rb -E production"
ExecStop=/usr/bin/kill -QUIT $MAINPID
ExecReload=/bin/kill -USR2 $MAINPID

[Install]
WantedBy=multi-user.target


**************************************************************************

#Se habilita e inicia el servicio:
sudo systemctl enable redmine-unicorn.service
sudo systemctl start redmine-unicorn.service

#Se verifica el correcto inicio:
sudo systemctl status redmine-unicorn.service

OBS: si falla el inicio del servicio, revisar los logs y si salta error del ENV. Tocar el archivo /opt/redmine/vendor/bundler/ruby/2.4.0/bin/unicorn_rails y ajustar ruby poniendo la ruta completa Ej.: /opt/rubies/ruby-2.4.6/bin/ruby

Reiniciar el servicio y debería funcionar, atender que el puerto que se pretende usar no este ocupado

#*** Instalación NGINX ***
#Se agrega el repositorio:
sudo nano /etc/yum.repos.d/nginx.repo

Contenido:

***
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
***

#Instalamos de NGINX
sudo yum -y install nginx


#Habilitación, inicio y verificación del servicio NGINX:
sudo service firewalld start
#Se habilita http en forma pública
sudo firewall-cmd --add-service http --zone=public --permanent
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx

#Creamos el archivo de configuracion de NGINX
sudo nano /etc/nginx/conf.d/redmine.conf

Contenido:

############################################################
upstream unicorn-redmine {
    server unix:/opt/redmine/tmp/sockets/unicorn.sock;
}

server {
    listen 80;
    server_name xxx.yyy.zzz;

    root /opt/redmine/public;
    client_max_body_size 1G;

    location / {
        try_files $uri/index.html $uri.html $uri @app;
    }

    location @app {
        proxy_redirect off;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_connect_timeout 32500;
        proxy_read_timeout 35000;
        proxy_send_timeout 32500;
        proxy_pass http://unicorn-redmine;
    }

    error_page 500 502 503 504 /500.html;
}
############################################################


#Se reinicia NGINX
sudo systemctl restart nginx

Luego de esto podra acceder a la instancia en la direccion http://xxx.yyy.zzz dado que el nginx hara el proxy_pass directamente al socket de Unicorn


CREDENCIALES POR DEFECTO

Usuario: admin
Password: admin



*** SERVICIOS ***

Comando para iniciar/parar/reiniciar/status del SERVICIO
#systemctl start/stop/restart/status SERVICIO

MARIADB
#systemctl start mariadb.service

UNICORN
#sudo systemctl start redmine-unicorn.service

NGINX
#sudo systemctl start nginx

FIREWALLD
#sudo systemctl start firewalld



*** INSTALACION PLUGIN AGIL ***

Descarga del plugin
#su - redmine
#cd /opt/redmine/plugins/
#wget http://redminecrm.com/license_manager/15337/redmine_agile-1_3_5-light.zip
#unzip redmine_agile-1_3_5-light.zip 
#rm redmine_agile-1_3_5-light.zip 

Instalacion del plugin
#cd /opt/redmine
#bundle install --without development test
#bundle exec rake redmine:plugins NAME=redmine_agile RAILS_ENV=production

Se reinicial servicio de unicorn
#sudo systemctl restart redmine-unicorn.service


PLUGINS


https://www.redmine.org/plugins/redmine_shared_api
https://www.redmine.org/plugins/custom-workflows-plug-in
https://www.redmine.org/issues/20384 Workflow/Workbench
https://www.redmine.org/plugins/scrum-plugin
https://redmine.ociotec.com/projects/advanced-roadmap
https://www.redmine.org/plugins/redmine_multiprojects_issue
https://www.redmine.org/plugins/redmine_recurring_tasks
