#!/usr/bin/env bash
# =====================================================
# sarahah setup: runs on the EC2 server via SSH
# Deploys the whole stack with docker compose.
#
# Required env vars (exported by the pipeline from /tmp/sarahah.env):
#   AWS_REGION, ECR_BASE, USERS_TABLE, MESSAGES_TABLE,
#   QUEUE_NAME, JWT_SECRET
# Optional:
#   ENABLE_MONITORING=true   (also needs GRAFANA_ADMIN_PASSWORD)
#
# Files expected in /tmp (copied by the pipeline):
#   sarahah.env, docker-compose.prod.yml, prometheus.yml (monitoring only)
# =====================================================
set -euo pipefail

: "${AWS_REGION:?AWS_REGION is required}"
: "${ECR_BASE:?ECR_BASE is required}"
: "${USERS_TABLE:?USERS_TABLE is required}"
: "${MESSAGES_TABLE:?MESSAGES_TABLE is required}"
: "${QUEUE_NAME:?QUEUE_NAME is required}"
: "${JWT_SECRET:?JWT_SECRET is required}"
: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${SSL_EMAIL:?SSL_EMAIL is required}"

ENABLE_MONITORING="${ENABLE_MONITORING:-false}"
APP_DIR=/opt/sarahah

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
die() { log "ERROR: $*"; exit 1; }

# ---------- 1. Dependencies ----------
install_dependencies() {
  log "-> Installing prerequisites..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg unzip jq awscli

  # Docker apt repo (added once)
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
  fi

  if ! command -v docker &>/dev/null; then
    log "-> Installing Docker Engine + compose plugin..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  elif ! sudo docker compose version &>/dev/null; then
    # Docker exists (e.g. docker.io from user_data) but the compose plugin does not
    log "-> Docker found, installing the compose plugin..."
    sudo apt-get install -y docker-compose-plugin
  else
    log "OK: Docker and compose already installed."
  fi

  sudo systemctl enable --now docker
  sudo usermod -aG docker ubuntu || true
}

# ---------- 2. ECR login ----------
login_ecr() {
  log "-> Logging into ECR ($ECR_BASE)..."
  aws ecr get-login-password --region "$AWS_REGION" \
    | sudo docker login --username AWS --password-stdin "$ECR_BASE"
}

# ---------- 3. Project files ----------
prepare_files() {
  log "-> Preparing $APP_DIR ..."
  [ -f /tmp/sarahah.env ]             || die "/tmp/sarahah.env not found"
  [ -f /tmp/docker-compose.prod.yml ] || die "/tmp/docker-compose.prod.yml not found"

  sudo mkdir -p "$APP_DIR/monitoring"
  sudo install -m 644 /tmp/docker-compose.prod.yml "$APP_DIR/docker-compose.yml"
  sudo install -m 600 /tmp/sarahah.env "$APP_DIR/.env"

  if [ "$ENABLE_MONITORING" = "true" ]; then
    : "${GRAFANA_ADMIN_PASSWORD:?GRAFANA_ADMIN_PASSWORD is required when monitoring is enabled}"
    [ -f /tmp/prometheus.yml ] || die "/tmp/prometheus.yml not found"
    sudo install -m 644 /tmp/prometheus.yml "$APP_DIR/monitoring/prometheus.yml"
  fi
}

# ---------- 4. Remove containers created by the old docker run version ----------
remove_legacy_containers() {
  for c in fastapi-app nginx node-exporter cadvisor prometheus grafana; do
    sudo docker rm -f "$c" &>/dev/null || true
  done
}

# ---------- 5. Deploy ----------
deploy() {
  cd "$APP_DIR"

  local profile=()
  if [ "$ENABLE_MONITORING" = "true" ]; then
    profile=(--profile monitoring)
  fi

  log "-> Pulling images (retries while the image reaches ECR)..."
  for i in $(seq 1 30); do
    if sudo docker compose "${profile[@]}" pull; then
      break
    fi
    [ "$i" -lt 30 ] || die "Failed to pull images"
    log "   images not ready, retry $i/30..."
    sleep 20
  done

  log "-> Starting containers..."
  sudo docker compose "${profile[@]}" up -d --remove-orphans
}

# ------------ssl certificate ----------------------
setup_ssl_certificate() {
  log "-> Setting up SSL certificate with certbot..."
  
  cd /opt/sarahah
  if [ -d "./certbot/conf/live/${DOMAIN_NAME}" ]; then
  log " SSL Certificate already exites "
  else
    log "-> Requesting new SSL Certificate "
    
    sudo docker compose run --rm \
      --entrypoint certbot \
      certbot certonly \
      --webroot \
      -w /var/www/certbot \
      -d "${DOMAIN_NAME}" \
      --email "${SSL_EMAIL}" \
      --agree-tos --no-eff-email
    log "-> Reloading Nginx ... "
    sudo docker compose exec nginx -s reload
  fi
}

# ---------- 6. Health check through nginx ----------
wait_healthy() {
  log "-> Waiting for http://localhost/health ..."
  for _ in $(seq 1 120); do
    if curl -fsS http://localhost/health >/dev/null 2>&1; then
      log "OK: the app answers through nginx."
      return 0
    fi
    sleep 5
  done
  cd "$APP_DIR"
  sudo docker compose ps || true
  sudo docker compose logs --tail 50 fastapi-app nginx || true
  die "The app did not become healthy"
}

main() {
  log "Starting sarahah setup..."
  install_dependencies
  login_ecr
  prepare_files
  remove_legacy_containers
  deploy
  setup_ssl_certificate
  wait_healthy
  sudo docker image prune -f >/dev/null
  log "Setup complete."
  cd "$APP_DIR"
  sudo docker compose ps
}
main "$@"
