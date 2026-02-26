# Configuration accès bureau à distance (VNC via Tailscale)

## Ordi distant (serveur)

### Dépendances
```bash
sudo apt install openssh-server x11vnc
```
- `openssh-server` — pour recevoir les connexions SSH
- `x11vnc` — partage de l'écran
- `tailscale` — réseau privé ([installation](https://tailscale.com/download/linux))

### Configuration (une seule fois)

**Désactiver Wayland pour forcer X11 :**
```bash
sudo nano /etc/gdm3/custom.conf
```
Ajouter/décommenter :
```
WaylandEnable=false
```

**Autoriser x11vnc sans mot de passe sudo :**
```bash
sudo visudo
```
Ajouter en bas : (remplacer username par un utilisateur sur l'ordinateur distant)
```
username ALL=(ALL) NOPASSWD: /usr/bin/x11vnc
```

**Activer SSH et Tailscale au démarrage :**
```bash
sudo systemctl enable --now ssh
sudo systemctl enable --now tailscaled
```

---

## Ton ordi (Tclient)

### Dépendances
```bash
sudo apt install tigervnc-viewer
```
- `tigervnc-viewer` — client VNC
- `openssh-client` — installé par défaut sur Ubuntu
- `tailscale` — réseau privé ([installation](https://tailscale.com/download/linux))

### Configuration (une seule fois)

**Copier la clé SSH vers l'ordi distant :**
```bash
ssh-keygen -t ed25519   # si pas déjà fait
ssh-copy-id username@<IP_TAILSCALE_DISTANT> #remplacer username par le même utilisateur sur l'ordinateur distant
```

---

## Utilisation

Lancer le script `connect.sh` depuis ton ordi :
```bash
./connect.sh
```

Le script :
1. Vérifie que Tailscale tourne des deux côtés
2. Détecte automatiquement le fichier Xauthority
3. Lance x11vnc sur l'ordi des distant
4. Crée un tunnel SSH sécurisé
5. Ouvre vncviewer
6. Ferme tout proprement à la fin

> **Note :** L'ordinateur distant doit être connecté à la session graphique avant de lancer le script.
