#!/bin/bash

# ==============================================================================
# PROJETO ACRÓPOLE - INSTALADOR INTERATIVO E PAINEL WEB (ESTÁGIO FINAL)
# ==============================================================================

clear
echo "========================================================="
echo " BEM-VINDO À ACRÓPOLE - ASSISTENTE DE INSTALAÇÃO"
echo "========================================================="
echo "Antes de construir o seu servidor, precisamos saber"
echo "como você prefere operá-lo."
echo "---------------------------------------------------------"

# PERGUNTA 1: Ignição
echo "[PERGUNTA 1] Como você prefere ligar a sua Acrópole?"
echo "  [1] Botão Único (Um comando liga todos os serviços juntos, Recomendado.) " 
echo "  [2] Manual (Ligar Radarr, Prowlarr e Bazarr separadamente)"
read -p "Escolha uma opção [1 ou 2]: " OPCAO_IGNICAO

echo "---------------------------------------------------------"

# PERGUNTA 2: Automação Total (Termux:Boot)
echo "[PERGUNTA 2] Deseja o sistema Totalmente Automatizado?"
echo "  (Isso preparará o sistema para ligar os servidores"
echo "   sozinho sempre que você reiniciar o celular)."
read -p "Deseja ativar a Automação Total? [S/N]: " OPCAO_AUTOMACAO

echo "========================================================="
echo " Entendido! Iniciando a construção. Pode ir beber um café."
echo " Por favor, não feche esta tela."
echo "========================================================="
sleep 3

termux-wake-lock

echo "[1/4] Atualizando os alicerces do Termux..."
pkg update -y && pkg upgrade -y > /dev/null 2>&1

echo "[2/4] Instalando ferramentas de base..."
pkg install wget curl proot-distro -y > /dev/null 2>&1

echo "[3/4] Instalando o subsistema Ubuntu..."
proot-distro install ubuntu > /dev/null 2>&1

echo "[4/4] Injetando a forja de aplicativos no núcleo..."

cat << 'EOF' > $PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root/setup_interno.sh
#!/bin/bash
apt update && apt upgrade -y > /dev/null 2>&1
apt install -y curl sqlite3 libicu-dev python3 python3-pip wget unzip tar > /dev/null 2>&1

mkdir -p /opt

# --- RADARR ---
wget -q --content-disposition 'http://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm64'
tar -xzf Radarr.master.*.linux-core-arm64.tar.gz -C /opt/
rm Radarr.master.*.tar.gz

# --- PROWLARR ---
wget -q --content-disposition 'http://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=arm64'
tar -xzf Prowlarr.master.*.linux-core-arm64.tar.gz -C /opt/
rm Prowlarr.master.*.tar.gz

# --- BAZARR ---
wget -q https://github.com/morpheus65535/bazarr/releases/latest/download/bazarr.zip -O bazarr.zip
mkdir -p /opt/Bazarr
unzip -q bazarr.zip -d /opt/Bazarr
rm bazarr.zip
python3 -m pip install -q -r /opt/Bazarr/requirements.txt --break-system-packages

# --- PAINEL DE CONTROLE WEB ---
mkdir -p /opt/Painel
cat << 'HTML' > /opt/Painel/index.html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Acrópole - Painel</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #1a1a2e; color: white; text-align: center; padding: 2rem; }
        h1 { color: #e94560; margin-bottom: 2rem; }
        .btn { display: block; width: 80%; max-width: 300px; margin: 15px auto; padding: 15px; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 1.2rem; transition: 0.3s; color: white; }
        .radarr { background-color: #ffc107; color: #333; }
        .prowlarr { background-color: #f44336; }
        .bazarr { background-color: #4caf50; }
        .btn:hover { opacity: 0.8; transform: scale(1.05); }
        .footer { margin-top: 50px; font-size: 0.8rem; color: #533483; }
    </style>
</head>
<body>
    <h1>🏛️ Sua Acrópole</h1>
    <a href="http://localhost:7878" class="btn radarr" target="_blank">🎬 Abrir Radarr (Filmes)</a>
    <a href="http://localhost:9696" class="btn prowlarr" target="_blank">🔍 Abrir Prowlarr (Busca)</a>
    <a href="http://localhost:6767" class="btn bazarr" target="_blank">📝 Abrir Bazarr (Legendas)</a>
    <div class="footer">Sistema Operacional S9 Linux</div>
</body>
</html>
HTML

apt autoremove -y && apt clean > /dev/null 2>&1

# --- SCRIPT INTERNO DE IGNIÇÃO ---
cat << 'START' > /root/iniciar_servicos.sh
#!/bin/bash
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
nohup /opt/Radarr/Radarr -nobrowser > /root/radarr.log 2>&1 &
nohup /opt/Prowlarr/Prowlarr -nobrowser > /root/prowlarr.log 2>&1 &
nohup python3 /opt/Bazarr/bazarr.py > /root/bazarr.log 2>&1 &

# Liga o Painel de Controle na porta 8080
cd /opt/Painel && nohup python3 -m http.server 8080 > /root/painel.log 2>&1 &
echo "Todos os motores estao online!"
START
chmod +x /root/iniciar_servicos.sh

EOF

chmod +x $PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root/setup_interno.sh

echo "Iniciando a compilação interna profunda (Isso demora alguns minutos)..."
proot-distro login ubuntu -- /root/setup_interno.sh

# ==============================================================================
# APLICANDO AS RESPOSTAS DA ENTREVISTA
# ==============================================================================

if [ "$OPCAO_IGNICAO" == "1" ]; then
    cat << 'EOF' > $HOME/ligar_acropole.sh
#!/bin/bash
termux-wake-lock
proot-distro login ubuntu -- /root/iniciar_servicos.sh
EOF
    chmod +x $HOME/ligar_acropole.sh
    MENSAGEM_IGNICAO="Para ligar seu servidor, digite: ./ligar_acropole.sh"
else
    cat << 'EOF' > $HOME/ligar_radarr.sh
#!/bin/bash
proot-distro login ubuntu -- bash -c 'export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 && nohup /opt/Radarr/Radarr -nobrowser > /root/radarr.log 2>&1 &'
echo "Radarr Iniciado."
EOF
    chmod +x $HOME/ligar_radarr.sh
    MENSAGEM_IGNICAO="Scripts individuais criados. Exemplo: ./ligar_radarr.sh"
fi

if [[ "$OPCAO_AUTOMACAO" == "S" || "$OPCAO_AUTOMACAO" == "s" ]]; then
    mkdir -p $HOME/.termux/boot
    cat << 'EOF' > $HOME/.termux/boot/start_acropole.sh
#!/bin/bash
termux-wake-lock
proot-distro login ubuntu -- /root/iniciar_servicos.sh
EOF
    chmod +x $HOME/.termux/boot/start_acropole.sh
    MENSAGEM_AUTOMACAO="[AVISO] Para ligar sozinho ao reiniciar o celular, instale o app 'Termux:Boot'."
else
    MENSAGEM_AUTOMACAO="Automação Total ignorada. Voce ligara manualmente."
fi

# ==============================================================================
# CONCLUSÃO E INSTRUÇÕES FINAIS (O TELA FINAL DO AMIGO)
# ==============================================================================

clear
echo "========================================================="
echo " 🏛️ A SUA ACRÓPOLE ESTÁ PRONTA!"
echo "========================================================="
echo ""
echo " 1. $MENSAGEM_IGNICAO"
echo ""
echo " 2. $MENSAGEM_AUTOMACAO"
echo ""
echo " -------------------------------------------------------"
echo " 🌐 COMO ACESSAR SEUS SITES FACILMENTE (ATALHO):"
echo " -------------------------------------------------------"
echo " Após ligar a Acrópole com o comando acima, abra o"
echo " seu navegador Chrome no celular e digite este endereço:"
echo ""
echo "             http://localhost:8080"
echo ""
echo " Para não precisar digitar isso nunca mais:"
echo " Clique nos 3 pontinhos do Chrome e escolha a opção:"
echo " 'Adicionar à Tela Inicial'."
echo "========================================================="
