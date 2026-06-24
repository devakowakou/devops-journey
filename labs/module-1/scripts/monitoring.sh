#!/bin/bash
# ===========================================
# monitoring.sh — Monitoring serveur pro
# DevOps Journey — Module 1 — Leçon 1.2
# ===========================================

set -euo pipefail

# ── Couleurs ──────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Config ────────────────────────────────
SEUIL_DISQUE=80
SEUIL_RAM=85
SERVICES=("ssh" "cron")
PORTS=(80 5432)

# ── Logging ───────────────────────────────
log_info()  { echo -e "${GREEN}[✅ OK]${RESET}    $1"; }
log_warn()  { echo -e "${YELLOW}[⚠️  WARN]${RESET}  $1"; }
log_error() { echo -e "${RED}[❌ CRIT]${RESET}  $1"; }
log_title() { echo -e "\n${BOLD}${CYAN}──── $1 ────${RESET}"; }

# ── Fonctions ─────────────────────────────

check_cpu() {
  log_title "CPU & CHARGE"
  local cores load
  cores=$(nproc)
  load=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
  local load_int=${load/,*/}

  log_info "Cores     : $cores"
  log_info "Load 1min : $load"

  # Alerte si load > nombre de cores
  if (( $(echo "$load > $cores" | bc -l 2>/dev/null || echo 0) )); then
    log_warn "Charge élevée ! load($load) > cores($cores)"
  fi
}

check_ram() {
  log_title "MÉMOIRE RAM"
  local total used pct
  total=$(free -m | awk 'NR==2{print $2}')
  used=$(free -m  | awk 'NR==2{print $3}')
  pct=$(( used * 100 / total ))

  if [[ $pct -ge $SEUIL_RAM ]]; then
    log_warn "RAM : ${used}Mo / ${total}Mo (${pct}%) → seuil ${SEUIL_RAM}%"
  else
    log_info "RAM : ${used}Mo / ${total}Mo (${pct}%)"
  fi
}

check_disk() {
  log_title "ESPACE DISQUE"
  while IFS= read -r line; do
    local pct point
    pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
    point=$(echo "$line" | awk '{print $6}')
    if [[ $pct -ge $SEUIL_DISQUE ]]; then
      log_warn "Disque $point : ${pct}% → seuil ${SEUIL_DISQUE}%"
    else
      log_info "Disque $point : ${pct}%"
    fi
  done < <(df -h | awk 'NR>1 && $6 ~ /^\// {print}')
}

check_services() {
  log_title "SERVICES SYSTEMD"
  for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
      log_info "Service $service actif"
    else
      log_error "Service $service INACTIF"
    fi
  done
}

check_ports() {
  log_title "PORTS RÉSEAU"
  for port in "${PORTS[@]}"; do
    if ss -tulnp | grep -q ":${port}"; then
      log_info "Port $port ouvert"
    else
      log_warn "Port $port fermé"
    fi
  done
}

check_logs() {
  log_title "ERREURS RÉCENTES (1h)"
  local nb_erreurs
  nb_erreurs=$(journalctl -p err --since "1 hour ago" --no-pager 2>/dev/null | grep -v "^--" | wc -l)
  if [[ $nb_erreurs -gt 0 ]]; then
    log_warn "$nb_erreurs erreur(s) dans les logs (1h)"
    journalctl -p err --since "1 hour ago" --no-pager 2>/dev/null | grep -v "^--" | tail -3
  else
    log_info "Aucune erreur récente"
  fi
}

# ── Main ──────────────────────────────────
main() {
  echo -e "${BOLD}"
  echo "╔══════════════════════════════════════╗"
  echo "║     MONITORING SERVEUR — $(date +%H:%M:%S)    ║"
  echo "║     $(hostname)   ║"
  echo "╚══════════════════════════════════════╝"
  echo -e "${RESET}"

  check_cpu
  check_ram
  check_disk
  check_services
  check_ports
  check_logs

  echo -e "\n${BOLD}${GREEN}Analyse terminée — $(date)${RESET}\n"
}

main
