# Base Debian + Node 20 (compatible with n8n 2.6.3)
FROM node:20-bullseye-slim

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    curl \
    git \
    ca-certificates \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a virtualenv for Python packages
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip, setuptools, wheel
RUN pip install --upgrade pip setuptools wheel

# Install Python libraries
RUN pip install --no-cache-dir \
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
    pyjwt \
    playwright==1.48.0

# Install Chromium dependencies and browser for Playwright.
# The running production container was installed in-place with zero downtime;
# this section makes future image builds reproducible.
RUN python -m playwright install-deps chromium

RUN mkdir -p /home/node/.cache/ms-playwright \
    && chown -R node:node /home/node/.cache

USER node
RUN python -m playwright install chromium

USER root

# Install n8n globally
RUN npm install -g n8n@2.6.3

USER node

EXPOSE 5678

CMD ["n8n"]
