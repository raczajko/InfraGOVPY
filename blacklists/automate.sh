#!/bin/bash
source /etc/profile
cd $blupdate
echo "$(pwd)"
echo "creando branch"
fecha="$(date +"%Y%m%d%H%M")"
git checkout -b $fecha origin/main 

echo "refrescando listas..."
wget https://cinsarmy.com/list/ci-badguys.txt -O sources/ci-badguys.txt
wget https://github.com/borestad/blocklist-abuseipdb/raw/refs/heads/main/abuseipdb-s100-30d.ipv4 -O sources/abuseipdb-s100-30d.ipv4
wget https://iplists.firehol.org/files/firehol_level1.netset -O sources/firehol_level1.netset
wget https://iplists.firehol.org/files/firehol_level2.netset -O sources/firehol_level2.netset
wget https://iplists.firehol.org/files/firehol_level3.netset -O sources/firehol_level3.netset
wget https://iplists.firehol.org/files/firehol_abusers_30d.netset -O sources/firehol_abusers_30d.netset
wget https://iplists.firehol.org/files/botscout_7d.ipset -O sources/botscout_7d.ipset
wget https://lists.blocklist.de/lists/all.txt -O sources/blocklist_de_all.txt

echo "generando bundle..."
#listado_full
tail -n +14 sources/abuseipdb-s100-30d.ipv4 | cut -d '#' -f 1 > todos.txt
tail -n +34 sources/firehol_level1.netset >> todos.txt
tail -n +32 sources/firehol_level2.netset >> todos.txt
tail -n +35 sources/firehol_level3.netset >> todos.txt
tail -n +32 sources/firehol_abusers_30d.netset >> todos.txt
tail -n +37 sources/botscout_7d.ipset >> todos.txt
cat sources/blocklist_de_all.txt >> todos.txt
cat sources/ci-badguys.txt >> todos.txt
echo "eliminando duplicados"
iprange --print-ranges todos.txt > listado_full.txt

#listado_fail2ban
tail -n +14 sources/abuseipdb-s100-30d.ipv4 | cut -d '#' -f 1 > todosf2b.txt
tail -n +35 sources/firehol_level3.netset >> todosf2b.txt
tail -n +37 sources/botscout_7d.ipset >> todosf2b.txt
cat sources/blocklist_de_all.txt >> todosf2b.txt
cat sources/ci-badguys.txt >> todosf2b.txt
iprange --print-single-ips todosf2b.txt > listado_fail2ban.txt

echo "generando listado para Forti...."
split -a 3 -l 300000 listado_full.txt listado_forti_

echo "generando md5sum de los listados..."
md5sum listado_full.txt > listado_full.txt.md5
md5sum listado_fail2ban.txt > listado_fail2ban.txt.md5

echo "limpiando archivos temporales"
rm -f todos.txt todosf2b.txt

echo "actualizando repositorio..."
git add -A
git commit -m "update"$fecha
git checkout main
git pull
git rebase $fecha
git push origin main
git pull origin main
git branch -D $fecha
