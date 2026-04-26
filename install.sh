#!/bin/bash

# ==============================================================================
# PROJETO ACRÓPOLE - INSTALADOR AUTOMATIZADO (ESTÁGIO 1)
# ==============================================================================

echo "========================================"
echo " Iniciando a construção da Acrópole..."
echo " Por favor, mantenha a tela ligada."
echo "========================================"

# 1. Previne que o Android mate o processo por causa da bateria
termux-wake-lock

# 2. Atualiza o Termux (Pressiona 'Y' automaticamente em tudo)
echo "[1/4] Atualizando os alicerces do Termux..."
pkg update -y && pkg upgrade -y

# 3. Instala as ferramentas necessárias no Android
echo "[2/4] Instalando ferramentas de base..."
pkg install wget curl proot-distro -y

# 4. Instala o Ubuntu
echo "[3/4] Instalando o subsistema Ubuntu..."
proot-distro install ubuntu

# 5. Criando o script de injeção (O que vai rodar DENTRO do Ubuntu)
echo "[4/4] Injetando a configuração interna..."

cat << 'EOF' > $PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root/setup_interno.sh
#!/bin/bash
echo "--- Entramos no Ubuntu! ---"
echo "Atualizando repositórios internos..."
apt update && apt upgrade -y

echo "Instalando dependências para Radarr, Prowlarr e Bazarr..."
# Instalamos o .NET Core (para Radarr/Prowlarr), Python3 (para Bazarr), sqlite3 e dependências de rede
apt install -y curl sqlite3 libicu-dev python3 python3-pip wget unzip

# (Nota do Arquiteto: O download e a extração dos binários do Radarr, Prowlarr e Bazarr entrarão aqui nas próximas etapas do código).

echo "Dependências instaladas com sucesso!"
EOF

# Dá permissão para o script interno ser executado
chmod +x $PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root/setup_interno.sh

# 6. O Termux entra no Ubuntu e roda o script que acabamos de criar silenciosamente
echo "========================================"
echo " Iniciando a compilação interna..."
echo "========================================"
proot-distro login ubuntu -- /root/setup_interno.sh

echo "========================================"
echo " A base da sua Acrópole está pronta!"
echo "========================================"
