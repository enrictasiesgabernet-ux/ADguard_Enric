#!/bin/bash
# ============================================================
#  ADguard_Enric - Script de test de bloqueig DNS
#  Verifica que AdGuard Home bloqueja correctament
# ============================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DNS_SERVER="${1:-127.0.0.1}"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  Test de Filtratge DNS - AdGuard Home${NC}"
echo -e "${BLUE}  Servidor DNS: ${DNS_SERVER}${NC}"
echo -e "${BLUE}============================================================${NC}\n"

# Comprovar que dig està instal·lat
if ! command -v dig &> /dev/null; then
    echo -e "${YELLOW}Instal·lant dnsutils (dig)...${NC}"
    sudo apt install -y dnsutils
fi

# ---- DOMINIS QUE HAN DE BLOQUEJAR-SE ----
echo -e "${YELLOW}[TEST 1] Dominis de publicitat (han de retornar 0.0.0.0):${NC}\n"

BLOCKED_DOMAINS=(
    "doubleclick.net"
    "ads.google.com"
    "googletagmanager.com"
    "pagead2.googlesyndication.com"
    "ad.doubleclick.net"
    "track.adform.net"
)

blocked_ok=0
blocked_fail=0

for domain in "${BLOCKED_DOMAINS[@]}"; do
    result=$(dig +short "$domain" @"$DNS_SERVER" 2>/dev/null | head -1)
    
    if [[ "$result" == "0.0.0.0" ]] || [[ -z "$result" ]]; then
        echo -e "  ${GREEN}✓ BLOQUEJAT${NC}  $domain → ${result:-'(sense resposta)'}"
        ((blocked_ok++))
    else
        echo -e "  ${RED}✗ NO BLOQUEJAT${NC}  $domain → $result"
        ((blocked_fail++))
    fi
done

echo ""

# ---- DOMINIS QUE HAN DE RESOLDRE ----
echo -e "${YELLOW}[TEST 2] Dominis legítims (han de resoldre correctament):${NC}\n"

ALLOWED_DOMAINS=(
    "google.com"
    "github.com"
    "wikipedia.org"
    "debian.org"
    "cloudflare.com"
)

allowed_ok=0
allowed_fail=0

for domain in "${ALLOWED_DOMAINS[@]}"; do
    result=$(dig +short "$domain" @"$DNS_SERVER" 2>/dev/null | head -1)
    
    if [[ -n "$result" ]] && [[ "$result" != "0.0.0.0" ]]; then
        echo -e "  ${GREEN}✓ RESOLT${NC}     $domain → $result"
        ((allowed_ok++))
    else
        echo -e "  ${RED}✗ ERROR${NC}       $domain → ${result:-'(sense resposta)'}"
        ((allowed_fail++))
    fi
done

echo ""

# ---- RESUM ----
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  RESUM DE RESULTATS${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "  Dominis bloquejats correctament: ${GREEN}${blocked_ok}/${#BLOCKED_DOMAINS[@]}${NC}"
echo -e "  Dominis legítims resolts:        ${GREEN}${allowed_ok}/${#ALLOWED_DOMAINS[@]}${NC}"

total_ok=$((blocked_ok + allowed_ok))
total=$((${#BLOCKED_DOMAINS[@]} + ${#ALLOWED_DOMAINS[@]}))

echo ""
if [[ $total_ok -eq $total ]]; then
    echo -e "  ${GREEN}🎉 TOTS ELS TESTS PASSATS! AdGuard Home funciona correctament.${NC}"
else
    echo -e "  ${YELLOW}⚠ Alguns tests han fallat. Comprova la configuració d'AdGuard.${NC}"
    echo -e "  ${YELLOW}  - Verifica que les blocklists estan activades${NC}"
    echo -e "  ${YELLOW}  - Comprova que el DNS apunta a ${DNS_SERVER}${NC}"
fi
echo ""
echo -e "  Dashboard: ${BLUE}http://$(hostname -I | awk '{print $1}'):80${NC}"
echo -e "${BLUE}============================================================${NC}"
