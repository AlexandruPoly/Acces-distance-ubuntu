#!/bin/bash

DISTANT_IP="100.1.1.1"
DISTANT_USER="username"
DISPLAY_NUM=":1"

# Nettoyage des instances précédentes
echo "==> Nettoyage des instances précédentes..."
ssh $DISTANT_USER@$DISTANT_IP "sudo pkill x11vnc" 2>/dev/null
pkill -f "ssh -N -L 590" 2>/dev/null
pkill vncviewer 2>/dev/null
sleep 2

# Vérifier Tailscale local
echo "==> Vérification de Tailscale en local..."
if ! tailscale status &>/dev/null; then
    echo "Tailscale n'est pas actif en local, démarrage..."
    sudo systemctl start tailscaled
    sleep 2
fi
echo "    Tailscale local OK"

# Vérifier que l'ordi distant est joignable via Tailscale
echo "==> Vérification que l'ordi distant est joignable..."
RETRY=0
until ping -c1 -W2 $DISTANT_IP &>/dev/null; do
    RETRY=$((RETRY+1))
    if [ $RETRY -ge 10 ]; then
        echo "ERREUR : impossible de joindre $DISTANT_IP après 10 tentatives."
        echo "Vérifie que Tailscale tourne sur l'ordi distant."
        exit 1
    fi
    echo "    Attente... ($RETRY/10)"
    sleep 3
done
echo "    Ordi distant joignable OK"

# Détecter le fichier Xauthority dynamiquement via ps
echo "==> Détection du fichier Xauthority..."
VNC_AUTH=$(ssh $DISTANT_USER@$DISTANT_IP "ps wwwaux | grep -o '\-auth [^ ]*Xauthority' | head -1 | awk '{print \$2}'")
echo "    Xauthority: $VNC_AUTH"

if [ -z "$VNC_AUTH" ]; then
    echo "ERREUR : fichier Xauthority introuvable. La session graphique est-elle ouverte ?"
    exit 1
fi

# Lancer x11vnc sur l'ordi distant
echo "==> Lancement de x11vnc sur l'ordi distant..."
ssh -f $DISTANT_USER@$DISTANT_IP "sudo x11vnc -auth $VNC_AUTH -forever -usepw -display $DISPLAY_NUM -noshm"
sleep 3

# Vérifier que x11vnc tourne et récupérer le port
PORT=$(ssh $DISTANT_USER@$DISTANT_IP "ss -tlnp | grep -o '590[0-9]*'" | head -1)
echo "    x11vnc sur port $PORT"

if [ -z "$PORT" ]; then
    echo "ERREUR : x11vnc ne semble pas tourner."
    exit 1
fi

# Créer le tunnel SSH
echo "==> Création du tunnel SSH..."
ssh -f -N -L ${PORT}:localhost:${PORT} $DISTANT_USER@$DISTANT_IP
sleep 1

# Connexion VNC
echo "==> Connexion VNC..."
vncviewer localhost:${PORT}

# Fermeture
echo "==> Fermeture..."
ssh $DISTANT_USER@$DISTANT_IP "sudo pkill x11vnc"
pkill -f "ssh -N -L 590"
echo "==> Tout est fermé."
