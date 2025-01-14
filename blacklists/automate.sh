#!/bin/bash
echo "creando branch"
fecha="$(date +"%Y%m%d")"
git checkout -b $fecha origin/main 

echo "refrescando listas..."
wget https://cinsarmy.com/list/ci-badguys.txt
wget https://github.com/borestad/blocklist-abuseipdb/raw/refs/heads/main/abuseipdb-s100-30d.ipv4
wget https://iplists.firehol.org/files/firehol_level1.netset
wget https://iplists.firehol.org/files/firehol_level2.netset
wget https://iplists.firehol.org/files/firehol_level3.netset

echo "actualizando repositorio..."
git add .
git commit -m "update"$fecha
git checkout main
git merge --ff-only origin/$fecha
git push origin main
