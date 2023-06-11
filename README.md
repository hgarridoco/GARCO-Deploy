[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)
[![Website](https://img.shields.io/badge/Website-Open%20me-243742.svg)](https://garcoconsulting.es/)

# GARCO Deploy

Repository to generate Odoo container and run postgres container

## Steps

```bash
    git submodule update --init --recursive
    docker-compose up -d --build
```

### Add customer submodules

First need to generate ssh key to add to settings
```bash 
    ssh-keygen -t ed25519 -C "hector.garrido@garcoconsulting.es"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    cat ~/.ssh/id_ed25519.pub 
```
Then add customer repository like submodule 
```bash
    git submodule add https://github.com/hgarridoco/repourl -b 16.0
```