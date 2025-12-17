🚀 n8n Multi-Setup Documentation (Custom Image)

📄 Introduction
This repository documents a production-ready, multi-user n8n setup using Docker and Docker Compose, extended with a **custom n8n Docker image** that includes Python 3 and common data/automation libraries. This allows workflows to run advanced Python logic directly inside n8n (via Execute Command / Python usage).

The setup uses PostgreSQL for persistence and LDAP (Active Directory) for authentication and is suitable for organizational environments.

---

✨ Key Setup Details

* **n8n Version:** 1.122.5 (free, stable)
* **Custom Image:** n8n-custom:1.122.5 (extends official image)
* **Python:** Python 3 + pip + common libraries (requests, pandas, numpy, sqlalchemy, …)
* **Database:** PostgreSQL 16
* **Authentication:** LDAP (Active Directory)
* **Server OS:** Ubuntu 22.04.5 LTS
* **Docker Version:** 28.5.1
* **Docker Compose:** v2.40.2 (plugin-based)
* **Ports:**

  * n8n: 5678 (HTTP)
  * PostgreSQL: 5432 (localhost only)
* **Resources:** 6 CPU cores, 12 GB RAM, ~165 GB free disk
* **Timezone:** Asia/Tehran (UTC+3:30)
* **Install Path:** /opt/n8n-multi
* **Hostname:** your-n8n-host.com (optionally behind Nginx)

This setup is designed for **multi-user organizational use**, with LDAP users defaulting to the `editor` role.

---

🔒 Security Notes

* All secrets shown are placeholders.
* Use a `.env` file for credentials and keys.
* Add `.env` to `.gitignore`.
* Rotate encryption keys and API keys regularly.

---

📋 Prerequisites

* OS: Ubuntu 22.04 LTS (kernel 5.15+)
* Docker Engine: 28.5.1+
* Docker Compose plugin: v2.40.2+
* Hardware (minimum):

  * 4 GB RAM
  * 2 CPU cores
  * 50 GB disk
* Network access to LDAP server (e.g. ldap://your-ldap-server:389)
* Firewall: allow TCP 5678 if accessed externally

---

⬇️ Installing Docker (if not installed)

```bash
sudo apt update
sudo apt install docker.io docker-compose -y
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
# Log out and log back in
```

---

🛠️ Installation Steps

### 1️⃣ Create Project Directory

```bash
sudo mkdir -p /opt/n8n-multi
cd /opt/n8n-multi
sudo chown -R $USER:$USER .
```

---

### 2️⃣ Environment Variables (.env)

Create a `.env` file:

```env
# Database
DB_PASSWORD=your_db_password

# n8n security
ENCRYPTION_KEY=your_encryption_key   # openssl rand -base64 32
API_KEY=your_api_key
N8N_HOST=your-n8n-host.com

# LDAP
LDAP_URL=ldap://your-ldap-server:389
LDAP_BIND_DN=CN=your_bind_dn,OU=GlobalServiceAccounts,OU=DKHighLevelObjects,DC=example,DC=com
LDAP_BIND_CREDENTIALS=your_ldap_bind_credentials
LDAP_SEARCH_BASE=dc=example,dc=com
```

Add `.env` to `.gitignore`.

---

### 3️⃣ Persistent Volumes

```bash
mkdir -p n8n_data postgres_data
sudo chown -R 1000:1000 n8n_data     # n8n (node user)
sudo chown -R 999:999 postgres_data  # PostgreSQL
```

---

### 4️⃣ Custom Dockerfile (Python-enabled n8n)

This Dockerfile extends the official n8n image and adds Python + libraries.

```Dockerfile
FROM docker.n8n.io/n8nio/n8n:1.122.5

USER root

# Install Python and system dependencies (Alpine-based image)
RUN apk update && apk add --no-cache \
    python3 \
    py3-pip \
    python3-dev \
    build-base \
    curl \
    git \
    ca-certificates \
    libffi-dev \
    openssl-dev

# Install common Python libraries (PEP 668 compatible)
RUN pip3 install --no-cache-dir --break-system-packages \
    requests \
    urllib3 \
    httpx \
    pandas \
    numpy \
    scipy \
    pydantic \
    python-dateutil \
    pytz \
    python-dotenv \
    tenacity \
    rich \
    loguru \
    jsonschema \
    lxml \
    beautifulsoup4 \
    xmltodict \
    openpyxl \
    xlrd \
    sqlalchemy \
    psycopg2-binary \
    redis \
    boto3 \
    cryptography \
    pyjwt

USER node
```

---

### 5️⃣ Docker Compose Configuration

```yaml
services:
  postgres:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_DB: n8n_base
      POSTGRES_USER: n8n_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
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
    build:
      context: .
      dockerfile: Dockerfile
    image: n8n-custom:1.122.5
    restart: always
    env_file:
      - .env
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
      N8N_RUNNERS_ENABLED: "true"
      N8N_GIT_NODE_DISABLE_BARE_REPOS: "true"
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
```

---

### 6️⃣ Build & Run

```bash
docker compose build --no-cache n8n
docker compose up -d
```

Verify:

```bash
docker compose ps
docker compose logs -f n8n
```

---

### 7️⃣ Python Verification (Inside n8n)

```bash
docker exec n8n-multi-n8n-1 python3 -c "import requests, pandas, numpy, sqlalchemy; print('Python OK inside n8n')"
```

---

💾 Data Persistence

* `n8n_data`: workflows, credentials, logs
* `postgres_data`: PostgreSQL data directory

---

☁️ Backup & Restore
**Backup:**

```bash
docker exec n8n-multi-postgres-1 pg_dump -U n8n_user n8n_base > backups/db.sql
tar -czf backups/n8n_data.tar.gz n8n_data
```

**Restore:**

```bash
docker compose down
tar -xzf backups/n8n_data.tar.gz
docker compose up -d
docker exec -i n8n-multi-postgres-1 psql -U n8n_user -d n8n_base < backups/db.sql
```

---

🔧 Maintenance Notes

* `docker builder prune -f` is safe (does NOT delete volumes or data)
* Update n8n by bumping the image tag and rebuilding
* Consider HTTPS with Nginx + Let’s Encrypt for production

---

📜 License
MIT – free to use, fork, and adapt for internal or public deployments.
