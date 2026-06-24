# Leçon 1.1 — Linux pour DevOps

**Date :** 2026-03-05
**Module :** 1 — Fondations Linux

## Ce que j'ai appris
- /etc : configs des services
- /var/log : logs système
- /proc : processus en cours en temps réel
- /usr/local/bin : mes scripts custom

## Commandes importantes
```bash
btop                          # monitoring temps réel moderne
journalctl -p err -b          # erreurs depuis le boot
journalctl -f                 # logs en live
ss -tulnp                     # ports ouverts (remplace netstat)
df -h                         # espace disque
ps aux --sort=-%cpu | head    # top consommateurs CPU
free -h                       # mémoire disponible
```

## Bonnes pratiques retenues
- Disque > 80% = alerte en prod
- PostgreSQL (5432) ne doit PAS écouter sur 0.0.0.0
- Clés SSH = chmod 600 obligatoire
- ss remplace netstat en 2026

## À retenir absolument
journalctl est la porte d'entrée pour tous les logs en prod

## Incident résolu — Disque plein (84% → 60%)

### Commandes d'investigation disque
```bash
sudo du -sh /*          # vue globale premier niveau
sudo du -d1 -h /var     # creuser un dossier
sudo du -d1 -h /snap    # voir les snaps installés
snap saved              # voir les snapshots snap
```

### Cause identifiée
- 5 IDEs JetBrains via snap = 18Go
- Snap garde snapshots après suppression

### Solution appliquée
```bash
sudo snap remove <nom>          # supprime le snap
snap saved                      # liste les snapshots
sudo snap forget <id>           # supprime le snapshot
sudo systemctl restart snapd    # force libération
```

### Règle d'or
- Sur serveur production → jamais snap, utiliser apt ou binaires
- Disque > 80% = alerte, > 90% = urgence
- Toujours investiguer avant de supprimer