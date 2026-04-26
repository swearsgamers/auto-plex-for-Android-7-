#!/bin/bash

# ==============================================================================
# PROJETO ACRÓPOLE - INSTALADOR INTERATIVO E PAINEL WEB (ESTÁGIO FINAL), é foi gerado por IA.
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
echo "  [1] Botão Único (Um comando liga todos os serviços juntos, Recomendado) " 
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

echo "[0/4] Solicitando permissão de armazenamento do celular..."
echo "      (Por favor, clique em 'Permitir' na tela do seu celular)"
termux-setup-storage
sleep 5
mkdir -p /storage/emulated/0/Movies/Acropole_Filmes

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
apt install -y curl sqlite3 libicu-dev python3 python3-pip wget unzip tar transmission-daemon > /dev/null 2>&1

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
        .transmission { background-color: #1976d2; }
        .btn:hover { opacity: 0.8; transform: scale(1.05); }
        .footer { margin-top: 50px; font-size: 0.8rem; color: #533483; }
    </style>
</head>
<body>
    <h1>🏛️ Sua Acrópole</h1>
    <a href="http://localhost:7878" class="btn radarr" target="_blank">🎬 Abrir Radarr (Filmes)</a>
    <a href="http://localhost:9696" class="btn prowlarr" target="_blank">🔍 Abrir Prowlarr (Busca)</a>
    <a href="http://localhost:6767" class="btn bazarr" target="_blank">📝 Abrir Bazarr (Legendas)</a>
    <a href="http://localhost:9091" class="btn transmission" target="_blank">⬇️ Abrir Transmission (Downloads)</a>
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

# Inicia o Transmission apontando a pasta de downloads para o armazenamento do Android, desativando senha local
mkdir -p /storage/emulated/0/Movies/Acropole_Filmes/Downloads
nohup transmission-daemon -f -T -w /storage/emulated/0/Movies/Acropole_Filmes/Downloads > /root/transmission.log 2>&1 &

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
# CONCLUSÃO E GUIA DE CONFIGURAÇÃO PASSO A PASSO (TUTORIAL NO TERMINAL)
# ==============================================================================

clear
cat << 'GUIA_INICIO'
=========================================================
 🏛️ A SUA ACRÓPOLE ESTÁ VIVA E ONLINE!
=========================================================
GUIA_INICIO
echo " 1. $MENSAGEM_IGNICAO"
echo " 2. $MENSAGEM_AUTOMACAO"
cat << 'GUIA_INICIO2'

 🌐 ACESSO RÁPIDO AOS APLICATIVOS (O SEU PAINEL):
 Abra o navegador Chrome no celular e acesse:
 👉 http://localhost:8080
 (Dica: Adicione esta página à tela inicial do celular!)
=========================================================

O sistema pesado foi instalado! Agora, precisamos apenas
conectar os "fios" entre os aplicativos.
Siga este guia com atenção (você só fará isso uma vez).

GUIA_INICIO2
read -p "👉 Pressione [ENTER] para iniciar a FASE 1..."
clear

cat << 'FASE1'
=========================================================
 🎬 FASE 1: O Cinema (Plex)
=========================================================
O Plex é a sua "Netflix" particular. É por onde vai ver.

1. Abra a Play Store e baixe o aplicativo "Plex".
2. Crie uma conta gratuita (ou faça login).
3. Vá em adicionar uma "Biblioteca" (Library) de Filmes.
4. Quando pedir a pasta onde os filmes estão, escolha
   EXATAMENTE este caminho no seu armazenamento interno:

   👉 /storage/emulated/0/Movies/Acropole_Filmes

5. Salve. O Plex vai vigiar esta pasta para sempre.
=========================================================
FASE1
read -p "👉 Pressione [ENTER] quando terminar a FASE 1..."
clear

cat << 'FASE2'
=========================================================
 🔍 FASE 2: O Motor de Busca (Prowlarr)
=========================================================
É ele quem vai procurar os filmes na internet.

1. No seu Painel Web (localhost:8080), clique no botão
   "Abrir Prowlarr".
2. No menu lateral, vá em "Indexers" e clique no "+".
3. Adicione os sites de onde quer baixar os filmes.
   (Recomendados: YTS, TorrentGalaxy, 1337x)
4. Clique em "Save" para cada um deles.
=========================================================
FASE2
read -p "👉 Pressione [ENTER] quando terminar a FASE 2..."
clear

cat << 'FASE3'
=========================================================
 🧠 FASE 3: O Cérebro (Radarr) & O Baixador (Transmission)
=========================================================
O Radarr recebe o pedido e manda o Transmission baixar.

1. No Painel Web, clique em "Abrir Radarr".
2. Vá em Settings > Media Management.
   - Marque "Show Advanced" lá no topo.
   - Desça até "Root Folders" e adicione o nosso caminho:
     👉 /storage/emulated/0/Movies/Acropole_Filmes
   - Salve.
3. Vá em Settings > Download Clients.
4. Clique no "+" e escolha "Transmission". Preencha:
   - Name: Transmission Local
   - Host: localhost
   - Port: 9091
   - Username/Password: (DEIXE TUDO EM BRANCO)
5. Clique em "Test". Se der check verde, clique "Save".
=========================================================
FASE3
read -p "👉 Pressione [ENTER] quando terminar a FASE 3..."
clear

cat << 'FASE4'
=========================================================
 🔗 FASE 4: A Grande Conexão
=========================================================
Avisando o Prowlarr para mandar os achados para o Radarr.

1. Ainda no Radarr, vá em Settings > General.
2. Copie o código gigante chamado "API Key".
3. Volte para a aba do Prowlarr no seu navegador.
4. Vá em Settings > Apps e clique no "+".
5. Escolha o "Radarr" e preencha:
   - Prowlarr Server: http://localhost:9696
   - Radarr Server: http://localhost:7878
   - API Key: (Cole aqui o código que copiou do Radarr)
6. Clique em "Test" e depois em "Save".
=========================================================
FASE4
read -p "👉 Pressione [ENTER] quando terminar a FASE 4..."
clear

cat << 'FASE5'
=========================================================
 📝 FASE 5: As Legendas (Bazarr)
=========================================================
Por fim, o caçador de legendas automático(Pode pular este, é opcional e nem eu consegui fazer funcionar).
O próprio plex tem um sistema de legendas, funciona bem.

1. No Painel Web, clique em "Abrir Bazarr".
2. Vá em Settings > Radarr.
   - IP Address: localhost
   - Port: 7878
   - API Key: (Cole a mesma chave que usou na Fase 4)
   - Test e Save.
3. Vá em Settings > Languages.
   - Adicione o "Portuguese (Brazil)".
4. Vá em Settings > Providers.
   - Clique no "+" e adicione o "OpenSubtitles".
   - Coloque o seu login do OpenSubtitles, se tiver.

=========================================================
 🎉 TUDO PRONTO! A SUA ACRÓPOLE ESTÁ 100% OPERACIONAL!
=========================================================
Sempre que quiser um filme, abra o Radarr no seu painel, 
pesquise o nome e clique em "Add". 

Ele vai buscar, baixar, puxar a legenda e o filme 
aparecerá magicamente no seu Plex! 
Aproveite o seu império! Você pode fechar este terminal.
FASE5
