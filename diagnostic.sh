#!/bin/bash
# ===========================================
# diagnostic.sh — Inspection rapide serveur
# DevOps Journey — Module 1
# ===========================================

echo "=============================="
echo "  DIAGNOSTIC SERVEUR RAPIDE"
echo "  $(date)"
echo "=============================="

echo ""
echo "--- SYSTÈME ---"
echo "Hostname     : $(hostname)"
echo "OS           : $(lsb_release -d | cut -f2)"
echo "Kernel       : $(uname -r)"
echo "Uptime       : $(uptime -p)"
echo "CPU cores    : $(nproc)"

echo ""
echo "--- RESSOURCES ---"
echo "CPU load     : $(uptime | awk -F'load average:' '{print $2}')"
free -h | grep Mem | awk '{print "RAM          : " $3 " utilisés / " $2 " total"}'
df -h / | tail -1 | awk '{print "Disque /     : " $3 " utilisés / " $2 " total (" $5 " plein)"}'

echo ""
echo "--- RÉSEAU ---"
echo "IP locale    : $(hostname -I | awk '{print $1}')"
echo "Ports ouverts:"
ss -tulnp | grep LISTEN | awk '{print "  " $1 "\t" $5}'

echo ""
echo "--- TOP 3 CPU ---"
ps aux --sort=-%cpu | awk 'NR>1 && NR<=4 {print "  " $11 " — CPU:" $3 "% MEM:" $4 "%"}'

echo ""
echo "--- DERNIÈRES ERREURS ---"
journalctl -p err -b --no-pager | tail -5

echo ""
echo "=============================="
echo "  FIN DU DIAGNOSTIC"
echo "=============================="
