#!/bin/bash
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

echo "generando bundle..."
tail -n +14 sources/abuseipdb-s100-30d.ipv4 | cut -d '#' -f 1 > todos.txt
tail -n +34 sources/firehol_level1.netset >> todos.txt
tail -n +32 sources/firehol_level2.netset >> todos.txt
tail -n +35 sources/firehol_level3.netset >> todos.txt
tail -n +32 sources/firehol_abusers_30d.netset
tail -n +37 sources/botscout_7d.ipset
cat sources/ci-badguys.txt >> todos.txt

echo "eliminando duplicados"
sort -u todos.txt > listado_full.txt
rm todos.txt

echo "actualizando repositorio..."
git add -A
git commit -m "update"$fecha
git checkout main
git pull
git rebase $fecha
git push origin main
git pull origin main
git branch -D $fecha
