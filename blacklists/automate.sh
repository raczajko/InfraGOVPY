#!/bin/bash
cd $blupdate
echo "$(pwd)"
echo "creando branch"
fecha="$(date +"%Y%m%d%H")"
git checkout -b $fecha origin/main 

echo "refrescando listas..."
wget https://cinsarmy.com/list/ci-badguys.txt -O ci-badguys.txt
wget https://github.com/borestad/blocklist-abuseipdb/raw/refs/heads/main/abuseipdb-s100-30d.ipv4 -O abuseipdb-s100-30d.ipv4
wget https://iplists.firehol.org/files/firehol_level1.netset -O firehol_level1.netset
wget https://iplists.firehol.org/files/firehol_level2.netset -O firehol_level2.netset
wget https://iplists.firehol.org/files/firehol_level3.netset -O firehol_level3.netset

echo "generando bundle..."
tail -n +14 abuseipdb-s100-30d.ipv4 | cut -d '#' -f 1 > todos.txt
tail -n +34 firehol_level1.netset >> todos.txt
tail -n +32 firehol_level2.netset >> todos.txt
tail -n +35 firehol_level3.netset >> todos.txt
cat ci-badguys.txt >> todos.txt

echo "actualizando repositorio..."
git add .
git commit -m "update"$fecha
git checkout main
git pull
git rebase $fecha
git push origin main
git pull origin main
