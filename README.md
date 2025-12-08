# 🚀 n8n Multi-Setup Documentation

## 📄 Introduction

n8n is an open-source workflow automation tool used for creating and managing automated processes. This documentation provides a complete guide to setting up **n8n** (free version) on a local server using **Docker** and **Docker Compose**. The configuration includes **PostgreSQL** for the database and **LDAP** for organizational authentication.

### ✨ Key Setup Details:

* **n8n Version:** 1.122.5 (free, stable)
* **Database:** PostgreSQL 16
* **Authentication:** LDAP (integration with Active Directory)
* **Server OS:** Ubuntu 22.04.5 LTS
* **Docker Version:** 28.5.1
* **Docker Compose Version:** v2.40.2
* **Ports:** n8n on **5678** (HTTP), PostgreSQL on **5432** (localhost only)
* **Resources:** 6 CPU cores, 12 GB RAM, ~165 GB free disk space
* **Timezone:** Asia/Tehran (UTC+3:30)
* **Installation Path:** `/opt/n8n-multi`
* **Hostname:** `your-n8n-host.com` (replace with your domain; optionally proxied via Nginx)

> This setup is designed for multi-user organizational use, with new users defaulting to the **"editor"** role. LDAP enables seamless login for domain users.

---

### 🔒 Security Note:

Sensitive values (e.g., **passwords, keys**) are placeholders in this documentation. **Replace them with secure, generated values** in production. Use a **`.env`** file for secrets and add it to **`.gitignore`**.

## 📋 Prerequisites

Ensure the following before starting:

* **Operating System:** Ubuntu 22.04 LTS or equivalent (kernel 5.15.0+)
* **Docker:** Version **28.5.1+** (systemd cgroup driver)
* **Docker Compose:** **v2.40.2+**
* **Hardware:** Minimum **4 GB RAM, 2 CPU cores, 50 GB disk space**
* **Network:** Access to your LDAP server (e.g., `ldap://your-ldap-server:389`)
* **Firewall:** Open port **5678** for external access (if required)
* **Additional Tools:** Git for version control (optional but recommended)

### ⬇️ Installing Docker (If Not Installed)

```bash
sudo apt update
sudo apt install docker.io docker-compose -y
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # Log out and log back in

🛠️ Installation Steps

Follow these steps to set up n8n from scratch.
1. Create Project Directory
Bash

sudo mkdir -p /opt/n8n-multi
cd /opt/n8n-multi
sudo chown -R $USER:$USER .  # Use your user or a service account like 'bahram'

2. Configure Docker Compose

Create the docker-compose.yml file (full file at the end). It defines:

    The PostgreSQL service with a persistent volume.

    The n8n service connected to PostgreSQL and LDAP.

    A custom bridge network (n8n-net).

For secrets, create a .env file:
Bash

# Example .env (add to .gitignore)
DB_PASSWORD=your_db_password
ENCRYPTION_KEY=your_encryption_key  # Generate: openssl rand -base64 32
API_KEY=your_api_key
LDAP_BIND_CREDENTIALS=your_ldap_bind_credentials
LDAP_BIND_DN=CN=your_bind_dn,OU=GlobalServiceAccounts,OU=DKHighLevelObjects,DC=example,DC=com
LDAP_URL=ldap://your-ldap-server:389
LDAP_SEARCH_BASE=dc=example,dc=com
N8N_HOST=your-n8n-host.com

Then reference it in docker-compose.yml:
YAML

env_file:
  - .env

3. Set Up Persistent Volumes
Bash

mkdir -p n8n_data postgres_data
sudo chown -R 1000:1000 n8n_data     # For n8n's node user
sudo chown -R 999:999 postgres_data  # For PostgreSQL user

4. Start Services
Bash

docker compose up -d     # Detached mode
docker compose logs -f   # Monitor logs (Ctrl+C to exit)

⚙️ Verify Status:
Bash

docker compose ps            # Check containers
docker compose logs postgres # PostgreSQL logs
docker compose logs n8n      # n8n logs

    Note: PostgreSQL waits for a health check before n8n starts.

5. Configure LDAP (Active Directory)

    Integrates n8n with your LDAP for user authentication.

    Search filter: (&(objectClass=user)(mail={{username}})) (email-based).

    All LDAP users get admin access (N8N_LDAP_IS_ADMIN=true).

    Test: Visit http://your-n8n-host.com:5678 and log in with your domain email.

6. Optional: Nginx Reverse Proxy

For domain proxying (based on common setups):
Bash

sudo apt install nginx -y
cat > /etc/nginx/sites-available/n8n << EOF
server {
    listen 80;
    server_name your-n8n-host.com;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

7. Git and Custom Scripts

    Initialize Git: git init in /opt/n8n-multi for workflow version control.

    Custom scripts (e.g., ad_auth.py) can be added for AD testing.

🧩 Configuration: Key Environment Variables
Variable	Example Value	Description
DB_TYPE	postgresdb	Database type
DB_POSTGRESDB_HOST/_PORT/_DATABASE/_USER	postgres / 5432 / n8n_base / n8n_user	PostgreSQL connection
DB_POSTGRESDB_PASSWORD	your_db_password	DB password (secure it!)
N8N_HOST	your-n8n-host.com	n8n domain
N8N_PORT	5678	Internal port
WEBHOOK_URL	http://your-n8n-host.com/	Webhook base URL
N8N_ENCRYPTION_KEY	your_encryption_key	Data encryption key
N8N_API_KEY	your_api_key	API access key
N8N_LDAP_*	See LDAP table below	LDAP settings
TZ	Asia/Tehran	Timezone
🔑 LDAP Configuration:
Variable	Example Value	Description
N8N_LDAP_ENABLED	true	Enable LDAP
N8N_LDAP_URL	ldap://your-ldap-server:389	LDAP server URL
N8N_LDAP_BIND_DN	"CN=your_bind_dn,..."	Bind DN
N8N_LDAP_BIND_CREDENTIALS	your_ldap_bind_credentials	Bind password
N8N_LDAP_SEARCH_BASE	"dc=example,dc=com"	Search base
N8N_LDAP_SEARCH_FILTER	(&(objectClass=user)(mail={{username}}))	Email filter
N8N_LDAP_UID_FIELD	mail	Username field
N8N_LDAP_IS_ADMIN	true	Users as admin
N8N_USER_DEFAULT_ROLE	editor	Default role
💾 Data Persistence

    n8n_data: /opt/n8n-multi/n8n_data – Config, logs (e.g., n8nEventLog.log), workflows.

    postgres_data: /opt/n8n-multi/postgres_data/pgdata – DB files.

    Logs: Check Docker logs or files in volumes.

🔧 Service Management
Start/Stop/Restart
Bash

cd /opt/n8n-multi
docker compose up -d     # Start
docker compose down      # Stop (keeps volumes)
docker compose restart   # Restart

Monitoring

    Status: docker compose ps

    Logs: docker compose logs -f n8n

    UI: http://your-server-ip:5678

    DB Health: docker exec n8n-multi-postgres-1 pg_isready -U n8n_user -d n8n_base

☁️ Backup and Restore
Backup:
Bash

# DB Dump
docker exec n8n-multi-postgres-1 pg_dump -U n8n_user n8n_base > backups/n8n_backup_$(date +%Y%m%d).sql

# n8n Data
tar -czf backups/n8n_data_$(date +%Y%m%d).tar.gz n8n_data

# Full (stop first)
docker compose down
tar -czf backups/full_$(date +%Y%m%d).tar.gz postgres_data n8n_data docker-compose.yml
docker compose up -d

Restore:
Bash

docker compose down
tar -xzf backups/full_YYYYMMDD.tar.gz
docker compose up -d
# SQL: docker exec -i n8n-multi-postgres-1 psql -U n8n_user -d n8n_base < backups/n8n_backup.sql

🔄 Updates
Bash

cd /opt/n8n-multi
docker compose pull
docker compose up -d
# Update image tag in docker-compose.yml for new versions

🐞 Troubleshooting
Issue	Check / Command
Containers Down	docker compose logs – Check DB/LDAP connectivity.
LDAP Issues	Test with: ldapsearch -x -H ldap://your-ldap-server:389 -D "CN=your_bind_dn,..." -w "your_ldap_bind_credentials" -b "dc=example,dc=com" "(mail=test@example.com)"
Port Conflict	netstat -tuln | grep 5678
Memory Issues	Monitor with free -h; add resource limits in compose.
Crashes	Check crash.journal in n8n_data.
📝 Full docker-compose.yml (Example)
YAML

version: '3.9'

services:
  postgres:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_DB: n8n_base
      POSTGRES_USER: n8n_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}  # From .env
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - n8n-net

  n8n:
    image: docker.n8n.io/n8nio/n8n:1.122.5
    restart: always
    env_file:
      - .env  # Load secrets
    environment:
      # Database
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n_base
      DB_POSTGRESDB_USER: n8n_user
      DB_POSTGRESDB_PASSWORD: ${DB_PASSWORD}
      # Core
      N8N_HOST: ${N8N_HOST}
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      WEBHOOK_URL: http://${N8N_HOST}/
      N8N_PATH: /
      N8N_API_KEY: ${API_KEY}
      N8N_ENCRYPTION_KEY: ${ENCRYPTION_KEY}
      N8N_USER_MANAGEMENT_DISABLED: "false"
      N8N_SECURE_COOKIE: "false"
      N8N_BASIC_AUTH_ACTIVE: "false"
      N8N_BLOCK_ENV_ACCESS_IN_NODE: "false"
      N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS: "true"
      N8N_LOG_LEVEL: "info"
      N8N_LOG_OUTPUT: "console"
      TZ: Asia/Tehran
      GENERIC_TIMEZONE: Asia/Tehran
      N8N_DEFAULT_TIMEZONE: Asia/Tehran
      # LDAP
      N8N_LDAP_ENABLED: "true"
      N8N_LDAP_URL: ${LDAP_URL}
      N8N_LDAP_BIND_DN: ${LDAP_BIND_DN}
      N8N_LDAP_BIND_CREDENTIALS: ${LDAP_BIND_CREDENTIALS}
      N8N_LDAP_SEARCH_BASE: ${LDAP_SEARCH_BASE}
      N8N_LDAP_SEARCH_FILTER: "(&(objectClass=user)(mail={{username}}))"
      N8N_LDAP_UID_FIELD: "mail"
      N8N_LDAP_IS_ADMIN: "true"
      N8N_USER_DEFAULT_ROLE: "editor"
    volumes:
      - ./n8n_data:/home/node/.n8n
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "0.0.0.0:5678:5678"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - n8n-net

networks:
  n8n-net:
    driver: bridge

➕ Additional Notes

    Security: Enable HTTPS via Nginx + Let's Encrypt. Rotate keys regularly.

    Scaling: For advanced multi-tenant, consider n8n queue mode or enterprise.

    Customization: Adjust LDAP filters or add custom nodes as needed.

    License: MIT (feel free to fork and contribute).

    This documentation is self-contained for GitHub. Copy to n8n-docs.md or README.md. For questions, open an Issue!


Would you like me to focus on translating any specific technical terms differently, or are you happy with this English version?
