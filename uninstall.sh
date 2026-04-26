#!/bin/bash

# ==============================================================================
# PROJETO ACRÓPOLE - DESINSTALADOR (TEAR DOWN)
# ==============================================================================

clear
echo "========================================================="
echo " ⚠️ AVISO DE DEMOLIÇÃO - ACRÓPOLE ⚠️"
echo "========================================================="
echo "Este script irá apagar completamente o servidor,"
echo "incluindo Radarr, Prowlarr, Bazarr, Transmission e o"
echo "subsistema Linux do seu Termux."
echo ""
read -p "Tem certeza que deseja destruir a Acrópole? [S/N]: " CONFIRMA

if [[ "$CONFIRMA" != "S" && "$CONFIRMA" != "s" ]]; then
    echo "Demolição cancelada. A Acrópole permanece de pé!"
    exit 0
fi

echo "========================================================="
echo "Iniciando a demolição profunda..."
echo "========================================================="

# 1. Libera o uso de bateria (Wake Lock)
termux-wake-unlock

# 2. Força a paragem de todos os serviços que possam estar a rodar
echo "[1/4] Desligando os motores..."
pkill -f "Radarr" > /dev/null 2>&1
pkill -f "Prowlarr" > /dev/null 2>&1
pkill -f "bazarr.py" > /dev/null 2>&1
pkill -f "transmission-daemon" > /dev/null 2>&1
pkill -f "http.server" > /dev/null 2>&1

# 3. Limpa os scripts de arranque e atalhos na raiz do Termux
echo "[2/4] Removendo atalhos e automações..."
rm -f $HOME/ligar_acropole.sh
rm -f $HOME/ligar_radarr.sh
rm -rf $HOME/.termux/boot

# 4. O Golpe de Misericórdia: Remove o Ubuntu PRoot e todo o seu conteúdo
echo "[3/4] Destruindo a fundação (Ubuntu PRoot)..."
proot-distro remove ubuntu > /dev/null 2>&1

echo "[4/4] Limpeza do sistema..."
apt autoremove -y > /dev/null 2>&1
apt clean > /dev/null 2>&1

# ==============================================================================
# TRATAMENTO DOS DADOS DO USUÁRIO (FILMES)
# ==============================================================================
echo "========================================================="
echo "Os programas e o sistema foram completamente apagados."
echo "No entanto, a pasta com os filmes baixados ainda existe"
echo "no seu celular:"
echo "👉 /storage/emulated/0/Movies/Acropole_Filmes"
echo "---------------------------------------------------------"
read -p "Deseja APAGAR também todos os filmes baixados? [S/N]: " APAGAR_FILMES

if [[ "$APAGAR_FILMES" == "S" || "$APAGAR_FILMES" == "s" ]]; then
    echo "Queimando a biblioteca de mídia..."
    rm -rf /storage/emulated/0/Movies/Acropole_Filmes
    echo "Mídia apagada com sucesso."
else
    echo "Os seus filmes foram mantidos a salvo no armazenamento."
fi

echo "========================================================="
echo " 💥 DEMOLIÇÃO CONCLUÍDA!"
echo "========================================================="
echo "O seu Termux está limpo e pronto para um novo começo."
echo "Se desejar, você já pode desinstalar o aplicativo Termux."
echo "========================================================="
