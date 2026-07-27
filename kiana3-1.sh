#!/bin/bash
set -euo pipefail

# =====================================================
# 🚀 KIANA-3.1 QWIKLABS-FIXED | GCP CLOUD RUN DEPLOYER
# ✅ Fixed bc crash + local variable bug
# ✅ Custom Firebase SNI: VLESS=firebaseremoteconfigrealtime.googleapis.com | Trojan=firebase-settings.crashlytics.com
# ✅ Full English | NetMod optimized | ARM64 support
# =====================================================

CUSTOM_SNI_VLESS="firebaseremoteconfigrealtime.googleapis.com"
CUSTOM_SNI_TROJAN="firebase-settings.crashlytics.com"

GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'
CYAN='\033[1;36m'; MAGENTA='\033[1;35m'; NC='\033[0m'

list_services() {
  clear
  echo -e "\n${CYAN}📋 ALL DEPLOYED KIANA-XRAY SERVICES${NC}"
  echo "======================================"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  echo "Active Project: $PROJECT_ID"
  echo ""
  gcloud run services list --format="table(metadata.name, status.url, region, metadata.creationTimestamp.date(%Y-%m-%d))" --filter="metadata.name~^xray-" --project="$PROJECT_ID" || {
    echo -e "${YELLOW}ℹ️ No xray- services found. Showing all Cloud Run services:\n${NC}"
    gcloud run services list --format="table(metadata.name, status.url, region)" --project="$PROJECT_ID"
  }
  echo -e "\n======================================"
  read -p "Press [Enter] to return to Main Menu..."
}

delete_service() {
  clear
  echo -e "\n${CYAN}🗑️ DELETE DEPLOYED SERVICE${NC}"
  echo "======================================"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  gcloud run services list --project="$PROJECT_ID" --format="table(metadata.name, region)" --filter="metadata.name~^xray-"
  echo ""
  read -p "Enter service name to DELETE (or press Enter to cancel): " DEL_NAME
  if [ -z "$DEL_NAME" ]; then echo -e "${YELLOW}Cancelled.${NC}"; read -p "Press [Enter] to return..."; return; fi
  read -p "${RED}⚠️  ARE YOU SURE? Type YES to confirm: ${NC}" CONF
  if [ "$CONF" = "YES" ]; then
    DEL_REGION=$(gcloud run services describe "$DEL_NAME" --project="$PROJECT_ID" --format='value(region)' 2>/dev/null || echo "us-central1")
    gcloud run services delete "$DEL_NAME" --project="$PROJECT_ID" --region="$DEL_REGION" --quiet
    echo -e "${GREEN}✅ Successfully deleted: $DEL_NAME${NC}"
  else echo -e "${YELLOW}Cancelled.${NC}"; fi
  read -p "Press [Enter] to return..."
}

select_region() {
  echo -e "\n${CYAN}🌍 SELECT CLOUD RUN REGION${NC}"
  echo "======================================"
  echo "--- NORTH AMERICA ---"
  echo "1) us-central1      (Iowa, US - Lowest cost)"
  echo "2) us-east1         (South Carolina, US)"
  echo "3) us-east4         (N.Virginia, US - Lowest latency PH)"
  echo "4) us-west1         (Oregon, US)"
  echo ""
  echo "--- ASIA PACIFIC (Lowest latency PH) ---"
  echo "5) asia-east1       (Taiwan 🇹🇼 - ⭐ RECOMMENDED)"
  echo "6) asia-southeast1  (Singapore 🇸🇬)"
  echo "7) asia-southeast2  (Jakarta 🇮🇩)"
  echo "8) asia-south1      (Mumbai 🇮🇳)"
  echo "9) asia-northeast1  (Tokyo 🇯🇵)"
  echo "10) asia-northeast3 (Seoul 🇰🇷)"
  echo "11) australia-southeast1 (Sydney 🇦🇺)"
  echo ""
  echo "--- EUROPE ---"
  echo "12) europe-west1    (Belgium)"
  echo "13) europe-west4    (Netherlands)"
  echo "14) europe-west9    (Paris, France)"
  echo ""
  echo "0) Enter custom region code manually"
  echo ""
  read -p "Select region [1-14, default=5 Taiwan]: " R
  R=${R:-5}
  case $R in
    1) REGION="us-central1" ;; 2) REGION="us-east1" ;; 3) REGION="us-east4" ;; 4) REGION="us-west1" ;;
    5) REGION="asia-east1" ;; 6) REGION="asia-southeast1" ;; 7) REGION="asia-southeast2" ;; 8) REGION="asia-south1" ;;
    9) REGION="asia-northeast1" ;; 10) REGION="asia-northeast3" ;; 11) REGION="australia-southeast1" ;;
    12) REGION="europe-west1" ;; 13) REGION="europe-west4" ;; 14) REGION="europe-west9" ;;
    0) read -p "Enter full region code (e.g. asia-east1): " REGION ;;
    *) echo -e "${YELLOW}⚠️ Invalid selection! Defaulting to Taiwan${NC}"; REGION="asia-east1" ;;
  esac
  echo -e "${GREEN}✅ Selected Region: $REGION${NC}"
}

deploy_service() {
  clear
  echo -e "${MAGENTA}
╔══════════════════════════════════════════════╗
║      🚀 KIANA-3.1 QWIKLABS-FIXED DEPLOYER    ║
║  Custom Firebase SNI | Trojan + VLESS WS/TLS║
╚══════════════════════════════════════════════╝${NC}"

  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ ERROR: No GCP project selected!${NC}"
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    read -p "Press [Enter] to return..."; return
  fi
  echo -e "${CYAN}Active GCP Project: $PROJECT_ID${NC}"
  gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project="$PROJECT_ID" --quiet >/dev/null 2>&1

  UUID="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16 | sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/\1-\2-\3-\4-\5/')"
  PASSWORD="$(openssl rand -hex 6)"
  RAND="$(openssl rand -hex 3)"
  SERVICE_NAME="xray-balanced-$RAND"
  BUILD_DIR="$(mktemp -d)"
  trap 'rm -rf "$BUILD_DIR"' EXIT
  cd "$BUILD_DIR" || exit 1
  echo -e "${GREEN}✅ Generated secure credentials${NC}"

  select_region

  echo -e "\n${CYAN}💻 SELECT CPU ARCHITECTURE${NC}"
  echo "1) AMD64 (Universal)"
  echo "2) ARM64 Graviton (⭐ Faster crypto, cheaper)"
  read -p "Select [1-2, default=2]: " ARCH
  ARCH=${ARCH:-2}
  if [ "$ARCH" = "2" ]; then ARCH_FLAG="--architecture arm64"; XRAY_BIN="Xray-linux-arm64-v8a.zip"; PLATFORM="linux/arm64"; echo -e "${GREEN}✅ ARM64 selected${NC}"; else ARCH_FLAG=""; XRAY_BIN="Xray-linux-64.zip"; PLATFORM="linux/amd64"; echo -e "${GREEN}✅ AMD64 selected${NC}"; fi

  echo -e "\n${CYAN}💰 SELECT BILLING MODE${NC}"
  echo "1) Request-Based"
  echo "2) Instance-Based (⭐ Most stable)"
  read -p "Select [1-2, default=2]: " B
  B=${B:-2}
  if [ "$B" = "2" ]; then BILLING_FLAGS="--no-cpu-throttling --startup-cpu-boost"; BMODE="Instance-Based"; else BILLING_FLAGS="--cpu-throttling --startup-cpu-boost"; BMODE="Request-Based"; fi
  echo -e "${GREEN}✅ Billing Mode: $BMODE${NC}"

  echo -e "\n${CYAN}⚙️ RESOURCE ALLOCATION${NC}"
  echo "Allowed vCPU: 0.5 | 1 | 2 | 4"
  while true; do read -p "vCPU [default=2]: " CPU; CPU=${CPU:-2}; [[ "$CPU" =~ ^(0.5|1|2|4)$ ]] && break || echo -e "${RED}Invalid! Use 0.5/1/2/4${NC}"; done
  case $CPU in
    0.5) VALID_MEM=("256Mi" "512Mi" "1Gi") ;; 1) VALID_MEM=("512Mi" "1Gi" "2Gi" "4Gi") ;;
    2) VALID_MEM=("1Gi" "2Gi" "4Gi" "8Gi") ;; 4) VALID_MEM=("2Gi" "4Gi" "8Gi" "16Gi") ;;
  esac
  echo "Valid memory for $CPU vCPU: ${VALID_MEM[*]}"
  while true; do
    read -p "Memory [default=${VALID_MEM[1]}]: " MEMORY; MEMORY=${MEMORY:-${VALID_MEM[1]}}
    VALID=0; for V in "${VALID_MEM[@]}"; do [[ "$V" == "$MEMORY" ]] && VALID=1 && break; done
    [[ $VALID -eq 1 ]] && break || echo -e "${RED}Invalid for $CPU vCPU!${NC}"
  done
  [[ "$CPU" =~ ^(0.5|1)$ ]] && CONCURRENCY=300 || CONCURRENCY=800
  echo -e "${GREEN}✅ Resources: ${CPU} vCPU / ${MEMORY}${NC}"

  echo -e "\n${CYAN}📈 SCALING${NC}"
  while true; do read -p "Min instances [0/1, default=0]: " MIN; MIN=${MIN:-0}; [[ "$MIN" =~ ^[0-9]+$ ]] && break; done
  while true; do read -p "Max instances [1-2, default=1]: " MAX; MAX=${MAX:-1}; [[ "$MAX" =~ ^[1-2]$ ]] && break; done

  echo -e "\n${CYAN}🔐 PROTOCOL${NC}"
  echo "1) Trojan + VLESS WS/TLS"
  echo "2) Add VLESS REALITY"
  read -p "Select [1-2, default=1]: " P_CHOICE; P_CHOICE=${P_CHOICE:-1}; SHORT_ID=""
  if [ "$P_CHOICE" = "2" ]; then SHORT_ID="$(openssl rand -hex 4)"; echo -e "${GREEN}✅ REALITY added${NC}"; fi

  read -p "Enable HTTP/2? [Y/n]: " H2; H2_FLAG=$([[ ! "$H2" =~ ^[Nn]$ ]] && echo "--use-http2" || echo "")

  echo -e "\n${YELLOW}💸 Estimated cost: ~$3.50/month for 2vCPU/2Gi always-on${NC}"
  read -p "Proceed? [Y/n]: " GO; [[ "$GO" =~ ^[Nn]$ ]] && return

  # Build files
  cat > config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "policy": { "levels": { "0": { "handshake": 2, "connIdle": 86400, "bufferSize": 2097152 } } },
  "inbounds": [
    { "tag": "trojan-ws", "port": 10001, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [{"password": "$PASSWORD", "level": 0}] }, "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/tr-ws?ed=2560" }, "sockopt": { "tcpNoDelay": true, "tcpFastOpen": true } } },
    { "tag": "vless-ws", "port": 10002, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [{"id": "$UUID", "level": 0}], "decryption": "none" }, "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vl-ws?ed=2560" }, "sockopt": { "tcpNoDelay": true, "tcpFastOpen": true } } }
EOF
  [ "$P_CHOICE" = "2" ] && cat >> config.json <<EOF
    ,{ "tag": "vless-reality", "port": 10003, "listen": "127.0.0.1", "protocol": "vless", "settings": { "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision", "level": 0}], "decryption": "none" }, "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true }, "streamSettings": { "network": "tcp", "security": "reality", "realitySettings": { "dest": "www.google.com:443", "serverNames": ["www.google.com"], "privateKey": "GENERATE", "shortIds": ["$SHORT_ID"] }, "sockopt": { "tcpNoDelay": true } } }
EOF
  cat >> config.json <<'EOF'
  ], "outbounds": [{"protocol": "freedom", "settings": { "domainStrategy": "UseIPv4v6" }}]
}
EOF

  cat > nginx.conf <<'EOF'
worker_processes auto; worker_rlimit_nofile 65535;
events { worker_connections 4096; use epoll; multi_accept on; }
http { include mime.types; default_type application/octet-stream; sendfile on; tcp_nodelay on; keepalive_timeout 86400; client_max_body_size 0; proxy_buffering off; proxy_http_version 1.1; map $http_upgrade $connection_upgrade { default upgrade; '' close; }
  server { listen 8080; server_name _; location /health { return 200 "OK\n"; } location / { proxy_pass https://www.google.com; } location /tr-ws { proxy_pass http://127.0.0.1:10001; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection upgrade; } location /vl-ws { proxy_pass http://127.0.0.1:10002; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection upgrade; } }
}
EOF

  cat > entrypoint.sh <<'EOF'
#!/bin/sh
if grep -q "GENERATE" /etc/xray.json; then K=$(/usr/local/bin/xray x25519 2>/dev/null | grep Private | awk '{print $3}'); sed -i "s/GENERATE/$K/" /etc/xray.json; fi
/usr/local/bin/xray run -c /etc/xray.json & sleep 3; exec /usr/local/openresty/bin/openresty -g 'daemon off;'
EOF
  chmod +x entrypoint.sh

  cat > Dockerfile <<EOF
FROM --platform=$PLATFORM alpine:3.24 AS builder
RUN apk add --no-cache curl unzip; WORKDIR /build
RUN curl -fsSL "https://github.com/XTLS/Xray-core/releases/latest/download/$XRAY_BIN" -o x.zip && unzip -q x.zip xray && chmod +x xray
FROM --platform=$PLATFORM openresty/openresty:alpine-fat
COPY --from=builder /build/xray /usr/local/bin/xray
COPY config.json /etc/xray.json; COPY nginx.conf /nginx.conf; COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/xray /entrypoint.sh; EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
EOF

  AR_REGION="us-central1"; REPO="kiana-xray"; IMG="$AR_REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$SERVICE_NAME"
  gcloud artifacts repositories create "$REPO" --location="$AR_REGION" --project="$PROJECT_ID" --quiet >/dev/null 2>&1 || true
  gcloud auth configure-docker "$AR_REGION-docker.pkg.dev" --quiet >/dev/null 2>&1
  echo -e "\n${CYAN}🏗️ Building image...${NC}"; gcloud builds submit --project="$PROJECT_ID" --tag "$IMG" --quiet .
  echo -e "${CYAN}🚀 Deploying...${NC}"
  gcloud run deploy "$SERVICE_NAME" --image "$IMG" --project="$PROJECT_ID" --region "$REGION" --allow-unauthenticated --port 8080 --memory "$MEMORY" --cpu "$CPU" --concurrency "$CONCURRENCY" --timeout 3600 --min-instances "$MIN" --max-instances "$MAX" --execution-environment gen2 $ARCH_FLAG $BILLING_FLAGS $H2_FLAG --quiet

  SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --project="$PROJECT_ID" --region "$REGION" --format='value(status.url)')
  REAL_DOMAIN="${SERVICE_URL#https://}"
  TROJAN_LINK="trojan://${PASSWORD}@${CUSTOM_SNI_TROJAN}:443?path=%2Ftr-ws%3Fed%3D2560&security=tls&type=ws&sni=${CUSTOM_SNI_TROJAN}&host=${REAL_DOMAIN}#KIANA-Trojan"
  VLESS_LINK="vless://${UUID}@${CUSTOM_SNI_VLESS}:443?encryption=none&path=%2Fvl-ws%3Fed%3D2560&security=tls&type=ws&sni=${CUSTOM_SNI_VLESS}&host=${REAL_DOMAIN}#KIANA-VLESS"

  clear
  echo -e "${GREEN}✅ DEPLOY SUCCESS!${NC}"
  echo -e "Service: $SERVICE_NAME | Region: $REGION"
  echo -e "URL: $SERVICE_URL | Health: $SERVICE_URL/health"
  echo -e "\n🔹 TROJAN: Address=$CUSTOM_SNI_TROJAN | SNI=$CUSTOM_SNI_TROJAN | Host=$REAL_DOMAIN"
  echo "$TROJAN_LINK"
  echo -e "\n🔹 VLESS: Address=$CUSTOM_SNI_VLESS | SNI=$CUSTOM_SNI_VLESS | Host=$REAL_DOMAIN"
  echo "$VLESS_LINK"
  read -p $'\nPress Enter to return...'
}

while true; do
  clear
  echo -e "${MAGENTA}╔══════════════════════════════════╗\n║   🚀 KIANA-3.1 QWIKLABS-FIXED   ║\n╚══════════════════════════════════╝${NC}"
  echo "1) Deploy NEW Service"
  echo "2) List All Services"
  echo "3) Delete Service"
  echo "4) Exit"
  echo "======================================"
  read -p "Select option [1-4]: " M
  case $M in 1) deploy_service ;; 2) list_services ;; 3) delete_service ;; 4) echo -e "\n👋 Goodbye!"; exit 0 ;; *) echo -e "${RED}Invalid! Use 1-4${NC}"; sleep 1.5 ;; esac
done
