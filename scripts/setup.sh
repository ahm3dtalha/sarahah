#!/usr/bin/env bash
# =====================================================
# sarahah setup — runs on the EC2 server via SSH
# Requires env vars:
#   AWS_REGION, ECR_BASE, USERS_TABLE, MESSAGES_TABLE,
#   QUEUE_NAME, JWT_SECRET
# =====================================================
set -euo pipefail

: "${AWS_REGION:?AWS_REGION is required}"
: "${ECR_BASE:?ECR_BASE is required}"
: "${USERS_TABLE:?USERS_TABLE is required}"
: "${MESSAGES_TABLE:?MESSAGES_TABLE is required}"
: "${QUEUE_NAME:?QUEUE_NAME is required}"
: "${JWT_SECRET:?JWT_SECRET is required}"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
die() { log "❌ ERROR: $*"; exit 1; }

# ---------- 1. Dependencies ----------
install_dependencies() {
  log "→ Installing prerequisites..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg unzip jq awscli

  if command -v docker &>/dev/null; then
    log "✔ Docker already installed."
    return
  fi

  log "→ Installing Docker..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo systemctl enable --now docker
  sudo usermod -aG docker ubuntu || true
}

# ---------- 2. ECR login ----------
login_ecr() {
  log "→ Logging into ECR ($ECR_BASE)..."
  aws ecr get-login-password --region "$AWS_REGION" \
    | sudo docker login --username AWS --password-stdin "$ECR_BASE"
}

# ---------- 3. Pull with retry ----------
pull_image() {
  local image="$1"
  for i in $(seq 1 30); do
    if sudo docker pull "$image"; then
      return 0
    fi
    log "   image not ready, retry $i/30..."
    sleep 20
  done
  die "Failed to pull image: $image"
}

# ---------- 4. Network ----------
ensure_network() {
  sudo docker network inspect app-net &>/dev/null \
    || { log "→ Creating network app-net"; sudo docker network create app-net; }
}

# ---------- 5. Containers ----------
recreate_container() {
  local name="$1"; shift
  sudo docker stop "$name" 2>/dev/null || true
  sudo docker rm   "$name" 2>/dev/null || true
  sudo docker run -d --name "$name" --network app-net \
    --restart unless-stopped "$@"
}

deploy_app() {
  log "→ Deploying fastapi-app..."
  pull_image "$ECR_BASE/fastapi-app:latest"
  recreate_container fastapi-app \
    -e AWS_REGION="$AWS_REGION" \
    -e USERS_TABLE="$USERS_TABLE" \
    -e MESSAGES_TABLE="$MESSAGES_TABLE" \
    -e QUEUE_NAME="$QUEUE_NAME" \
    -e JWT_SECRET="$JWT_SECRET" \
    "$ECR_BASE/fastapi-app:latest"

  log "→ Deploying nginx..."
  pull_image "$ECR_BASE/nginx-app:latest"
  recreate_container nginx \
    -p 80:80 \
    "$ECR_BASE/nginx-app:latest"
}

# ---------- Main ----------
main() {
  log "🚀 Starting sarahah setup..."
  install_dependencies
  login_ecr
  ensure_network
  deploy_app
  log "✅ Setup complete. Containers:"
  sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
}

main "$@"