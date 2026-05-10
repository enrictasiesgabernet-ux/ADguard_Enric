#!/bin/bash
# ============================================================
#  ADguard_Enric - Script de desplegament automatitzat
#  Pràctica 0378 · Tallafocs ASIC · IES El Calamot
# ============================================================

set -e  # Aturar si hi ha error

# Colors per al terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sense color

echo -e "${BLUE}"
echo "  █████╗ ██████╗  ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗ "
echo " ██╔══██╗██╔══██╗██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗"
echo " ███████║██║  ██║██║  ███╗██║   ██║███████║██████╔╝██║  ██║"
echo " ██╔══██║██║  ██║██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║"
echo " ██║  ██║██████╔╝╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝"
echo " ╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ "
echo -e "${NC}"
echo -e "${GREEN}  Desplegament AdGuard Home amb Docker${NC}"
echo -e "  Pràctica 0378 · Enric · IES El Calamot\n"
echo "============================================================"

# ---- 1. Comprovar Docker ----
echo -e "\n${YELLOW}[1/5] Comprovant Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker no està instal·lat!${NC}"
    echo "Executa primer: sudo apt install docker.io docker-compose-plugin -y"
    exit 1
fi
echo -e "${GREEN}✓ Docker trobat: $(docker --version)${NC}"

if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}ERROR: Docker Compose no trobat!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose disponible${NC}"

# ---- 2. Comprovar port 53 ----
echo -e "\n${YELLOW}[2/5] Comprovant port 53...${NC}"
if ss -tulnp 2>/dev/null | grep -q ':53 '; then
    echo -e "${YELLOW}⚠ El port 53 està en ús. Intentant alliberar-lo...${NC}"
    
    # Desactivar systemd-resolved si és qui l'ocupa
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        sudo systemctl stop systemd-resolved
        sudo systemctl disable systemd-resolved
        echo -e "${GREEN}✓ systemd-resolved aturat${NC}"
        
        # Configurar DNS temporal
        sudo rm -f /etc/resolv.conf
        echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
        echo -e "${GREEN}✓ resolv.conf configurat amb 8.8.8.8${NC}"
    else
        echo -e "${RED}ERROR: Port 53 ocupat per un altre procés. Allibera'l manualment.${NC}"
        ss -tulnp | grep ':53'
        exit 1
    fi
else
    echo -e "${GREEN}✓ Port 53 disponible${NC}"
fi

# ---- 3. Crear directoris de volums ----
echo -e "\n${YELLOW}[3/5] Preparant directoris de volums...${NC}"
mkdir -p adguard_work adguard_conf screenshots
echo -e "${GREEN}✓ Directoris creats: adguard_work/, adguard_conf/, screenshots/${NC}"

# ---- 4. Iniciar AdGuard Home ----
echo -e "\n${YELLOW}[4/5] Iniciant AdGuard Home...${NC}"

# Detectar docker compose vs docker-compose
if command -v docker compose &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

$COMPOSE_CMD pull
$COMPOSE_CMD up -d

echo -e "${GREEN}✓ Contenidor en marxa!${NC}"

# ---- 5. Verificació ----
echo -e "\n${YELLOW}[5/5] Verificant desplegament...${NC}"
sleep 3

if $COMPOSE_CMD ps | grep -q "Up"; then
    echo -e "${GREEN}✓ AdGuard Home està en funcionament${NC}"
else
    echo -e "${RED}ERROR: El contenidor no sembla estar en marxa${NC}"
    $COMPOSE_CMD logs adguardhome
    exit 1
fi

# Mostrar IP de la màquina
IP=$(hostname -I | awk '{print $1}')

echo ""
echo "============================================================"
echo -e "${GREEN}  DESPLEGAMENT COMPLETAT AMB ÈXIT! 🎉${NC}"
echo "============================================================"
echo ""
echo -e "  ${BLUE}Setup wizard (primer accés):${NC}"
echo -e "  → http://${IP}:3000"
echo ""
echo -e "  ${BLUE}Panell d'administració (post-setup):${NC}"
echo -e "  → http://${IP}:80"
echo ""
echo -e "  ${BLUE}DNS Server (apuntar clients aquí):${NC}"
echo -e "  → ${IP}:53"
echo ""
echo -e "  ${YELLOW}Recorda configurar el DNS de la teva màquina:${NC}"
echo -e "  sudo echo 'nameserver ${IP}' > /etc/resolv.conf"
echo ""
echo "============================================================"
