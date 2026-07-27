#!/bin/bash
set -euo pipefail

# =====================================================
# 🚀 KIANA-3.1 ULTIMATE | GCP CLOUD RUN DEPLOYER (2026)
# ✅ QWIKLABS FIXED VERSION | COST SECTION REMOVED
# ✅ Full English | Custom Firebase SNI Preconfigured
# ✅ Trojan + VLESS WS/TLS | Optional VLESS REALITY
# ✅ Random credentials | Validated resources | ARM64
# =====================================================
# --------------------------
# 🔧 CUSTOM SNI / ADDRESS
# --------------------------
CUSTOM_SNI_VLESS="firebaseremoteconfigrealtime.googleapis.com"
CUSTOM_SNI_TROJAN="firebase-settings.crashlytics.com"
# --------------------------
# 🎨 COLORS
# --------------------------
GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'
CYAN='\033[1;36m'; MAGENTA='\033[1;35m'; NC='\033[0m'

# =====================================================
# 📋 MENU 2: LIST ALL DEPLOYED SERVICES
# =====================================================
list_services() {
  clear
  echo -e "\n${CYAN}📋 ALL DEPLOYED KIANA-XRAY SERVICES${NC}"
  echo "======================================"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  echo "Active Project: $PROJECT_ID"
  echo ""
  gcloud run services list \
    --format="table(metadata.name, status.url, region, metadata.creationTimestamp.date(%Y-%m-%d))" \
    --filter="metadata.name~^xray-" --project="$PROJECT_ID" || {
    echo -e "${YELLOW}ℹ️ No xray- services found. Showing all Cloud Run services:\n${NC}"
    gcloud run services list --format="table(metadata.name, status.url, region)" --project="$PROJECT_ID"
  }
  echo -e "\n======================================"
  read -p "Press [Enter] to return to Main Menu..."
}

# =====================================================
# 🗑️ MENU 3: DELETE A DEPLOYED SERVICE
# =====================================================
delete_service() {
  clear
  echo -e "\n${CYAN}🗑️ DELETE DEPLOYED SERVICE${NC}"
  echo "======================================"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  gcloud run services list --project="$PROJECT_ID" \
    --format="table(metadata.name, region)" --filter="metadata.name~^xray-"
  echo ""
  read -p "Enter service name to DELETE (or press Enter to cancel): " DEL_NAME
  if [ -z "$DEL_NAME" ]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    read -p "Press [Enter] to return..."
    return
  fi
  read -p "${RED}⚠️  ARE YOU SURE? Type YES to confirm: ${NC}" CONF
  if [ "$CONF" = "YES" ]; then
    DEL_REGION=$(gcloud run services describe "$DEL_NAME" --project="$PROJECT_ID" \
      --format='value(region)' 2>/dev/null || echo "us-central1")
    gcloud run services delete "$DEL_NAME" --project="$PROJECT_ID" \
      --region="$DEL_REGION" --quiet
    echo -e "${GREEN}✅ Successfully deleted: $DEL_NAME${NC}"
  else
    echo -e "${YELLOW}Cancelled.${NC}"
  fi
  read -p "Press [Enter] to return..."
}

# =====================================================
# 🗺️ REGION SELECTOR
# =====================================================
select_region() {
  echo -e "\n${CYAN}🌍 SELECT CLOUD RUN REGION${NC}"
  echo "======================================"
  echo "--- NORTH AMERICA ---"
  echo "1) us-central1      (Iowa, US - Lowest cost / Qwiklabs ✅)"
  echo "2) us-east1         (South Carolina, US)"
  echo "3) us-east4         (N.Virginia, US)"
  echo "4) us-west1         (Oregon, US)"
  echo ""
  echo "--- ASIA PACIFIC ---"
  echo "5) asia-east1       (Taiwan 🇹🇼)"
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

  read -p "Select region [1-14, default=1 us-central1 (Qwiklabs safe)]: " R
  R=${R:-1}
  case $R in
    1) REGION="us-central1" ;; 2) REGION="us-east1" ;; 3) REGION="us-east4" ;; 4) REGION="us-west1" ;;
    5) REGION="asia-east1" ;; 6) REGION="asia-southeast1" ;; 7) REGION="asia-southeast2" ;; 8) REGION="asia-south1" ;;
    9) REGION="asia-northeast1" ;; 10) REGION="asia-northeast3" ;; 11) REGION="australia-southeast1" ;;
    12) REGION="europe-west1" ;; 13) REGION="europe-west4" ;; 14) REGION="europe-west9" ;;
    0) read -p "Enter full region code (e.g. asia-east1): " REGION ;;
    *) echo -e "${YELLOW}⚠️ Invalid! Defaulting to us-central1${NC}"; REGION="us-central1" ;;
  esac
  echo -e "${GREEN}✅ Selected Region: $REGION${NC}"
}

# =====================================================
# 🚀 MAIN DEPLOY FUNCTION
# =====================================================
deploy_service() {
  clear
  echo -e "${MAGENTA}
╔══════════════════════════════════════════════╗
║      🚀 KIANA-3.1 ULTIMATE DEPLOYER         ║
║  Custom Firebase SNI | Trojan + VLESS WS/TLS║
╚══════════════════════════════════════════════╝${NC}"

  # --------------------------
  # 1. PREREQUISITES
  # --------------------------
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ ERROR: No GCP project selected!${NC}"
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    read -p "Press [Enter] to return..."
    return
  fi
  echo -e "${CYAN}Active GCP Project: $PROJECT_ID${NC}"

  # Detect Qwiklabs environment automatically
  if [[ "$PROJECT_ID" == qwiklabs-gcp-* ]]; then
    QWIKLABS=1
    echo -e "${YELLOW}ℹ️ Qwiklabs environment detected — applying compatibility fixes${NC}"
  else
    QWIKLABS=0
  fi

  # Enable required APIs
  echo -e "${CYAN}Enabling required GCP APIs...${NC}"
  gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
    artifactregistry.googleapis.com --project="$PROJECT_ID" --quiet >/dev/null 2>&1 || true

  # --------------------------
  # 2. AUTO-GENERATE CREDENTIALS
  # --------------------------
  UUID="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16 | \
    sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/\1-\2-\3-\4-\5/')"
  PASSWORD="$(openssl rand -hex 6)"
  RAND="$(openssl rand -hex 3)"
  SERVICE_NAME="xray-balanced-$RAND"
  BUILD_DIR="$(mktemp -d)"
  trap 'rm -rf "$BUILD_DIR"' EXIT
  cd "$BUILD_DIR" || exit 1
  echo -e "${GREEN}✅ Generated secure random credentials${NC}"

  # --------------------------
  # 3. REGION
  # --------------------------
  select_region

  # --------------------------
  # 4. CPU ARCHITECTURE
  # --------------------------
  echo -e "\n${CYAN}💻 SELECT CPU ARCHITECTURE${NC}"
  echo "1) AMD64 (Gen2 - ⭐ QWIKLABS SAFE, universal)"
  echo "2) ARM64 Graviton (Faster, may fail on Qwiklabs)"
  read -p "Select [1-2, default=1]: " ARCH
  ARCH=${ARCH:-1}
  if [ "$ARCH" = "2" ]; then
    ARCH_FLAG="--architecture arm64"
    XRAY_BIN="Xray-linux-arm64-v8a.zip"
    PLATFORM="linux/arm64"
    echo -e "${YELLOW}⚠️ ARM64 selected — if deploy fails, re-run with AMD64 option 1${NC}"
  else
    ARCH_FLAG=""
    XRAY_BIN="Xray-linux-64.zip"
    PLATFORM="linux/amd64"
    echo -e "${GREEN}✅ AMD64 selected (Qwiklabs compatible)${NC}"
  fi

  # --------------------------
  # 5. BILLING MODE
  # --------------------------
  echo -e "\n${CYAN}💰 SELECT BILLING MODE${NC}"
  echo "1) Request-Based  (Cheaper for light usage)"
  echo "2) Instance-Based (⭐ No throttling, most stable)"
  read -p "Select [1-2, default=2]: " B
  B=${B:-2}
  if [ "$B" = "2" ]; then
    BILLING_FLAGS="--no-cpu-throttling --startup-cpu-boost"
    BMODE="Instance-Based"
  else
    BILLING_FLAGS="--cpu-throttling --startup-cpu-boost"
    BMODE="Request-Based"
  fi
  echo -e "${GREEN}✅ Billing Mode: $BMODE${NC}"

  # --------------------------
  # 6. RESOURCE ALLOCATION (ACCEPTS BOTH `4` AND `4Gi`)
  # --------------------------
  echo -e "\n${CYAN}⚙️ RESOURCE ALLOCATION (AUTO-VALIDATED)${NC}"
  echo "Allowed vCPU options: 0.5 | 1 | 2 | 4"
  while true; do
    read -p "Enter vCPU count [default=2]: " CPU
    CPU=${CPU:-2}
    [[ "$CPU" =~ ^(0.5|1|2|4)$ ]] && break || \
      echo -e "${RED}❌ Invalid! Allowed: 0.5 / 1 / 2 / 4${NC}"
  done

  case $CPU in
    0.5) VALID_MEM=("256Mi" "512Mi" "1Gi") ;;
    1)   VALID_MEM=("512Mi" "1Gi" "2Gi" "4Gi") ;;
    2)   VALID_MEM=("1Gi" "2Gi" "4Gi" "8Gi") ;;
    4)   VALID_MEM=("2Gi" "4Gi" "8Gi" "16Gi") ;;
  esac
  echo -e "Valid memory for ${CPU} vCPU: ${VALID_MEM[*]}"
  echo -e "${YELLOW}💡 TIP: You can type just the number (e.g. 4) OR full suffix (4Gi)${NC}"
  while true; do
    read -p "Enter memory [default=${VALID_MEM[1]}]: " MEM_INPUT
    MEM_INPUT=${MEM_INPUT:-${VALID_MEM[1]}}
    
    # Auto-add Gi/Mi suffix if user typed only a number
    if [[ "$MEM_INPUT" =~ ^[0-9]+$ ]]; then
      if [[ " ${VALID_MEM[*]} " =~ " ${MEM_INPUT}Gi " ]]; then
        MEMORY="${MEM_INPUT}Gi"
      elif [[ " ${VALID_MEM[*]} " =~ " ${MEM_INPUT}Mi " ]]; then
        MEMORY="${MEM_INPUT}Mi"
      else
        MEMORY=""
      fi
    else
      MEMORY="$MEM_INPUT"
    fi

    # Validate
    VALID=0
    for V in "${VALID_MEM[@]}"; do
      [[ "$V" == "$MEMORY" ]] && VALID=1 && break
    done
    [[ $VALID -eq 1 ]] && break || \
      echo -e "${RED}❌ Invalid! Choose from: ${VALID_MEM[*]}${NC}"
  done

  if [[ "$CPU" =~ ^(0.5|1)$ ]]; then
    CONCURRENCY=300
  else
    CONCURRENCY=800
  fi
  echo -e "${GREEN}✅ Resources: ${CPU} vCPU / ${MEMORY} | Concurrency: ${CONCURRENCY}${NC}"

  # --------------------------
  # 7. SCALING
  # --------------------------
  echo -e "\n${CYAN}📈 AUTO-SCALING SETTINGS${NC}"
  while true; do
    read -p "Min instances [0=scale to zero / 1=no cold start, default=0]: " MIN
    MIN=${MIN:-0}
    [[ "$MIN" =~ ^[0-9]+$ ]] && break || echo -e "${RED}Numbers only${NC}"
  done
  while true; do
    read -p "Max instances [1-2, default=1]: " MAX
    MAX=${MAX:-1}
    [[ "$MAX" =~ ^[1-2]$ ]] && break || echo -e "${RED}Only 1 or 2 allowed${NC}"
  done

  # --------------------------
  # 8. PROTOCOL
  # --------------------------
  echo -e "\n${CYAN}🔐 PROTOCOL CONFIGURATION${NC}"
  echo "1) Balanced: Trojan + VLESS WS/TLS"
  echo "2) ⭐ Add VLESS REALITY (Stealthiest, anti-DPI)"
  read -p "Select [1-2, default=1]: " P_CHOICE
  P_CHOICE=${P_CHOICE:-1}
  SHORT_ID=""
  if [ "$P_CHOICE" = "2" ]; then
    SHORT_ID="$(openssl rand -hex 4)"
    echo -e "${GREEN}✅ VLESS REALITY will be added${NC}"
  fi

  read -p "Enable HTTP/2 (faster WebSocket)? [Y/n]: " H2
  H2_FLAG=$([[ ! "${H2:-Y}" =~ ^[Nn]$ ]] && echo "--use-http2" || echo "")

  # ✅ MONTHLY COST SECTION FULLY REMOVED ✅

  # --------------------------
  # PROCEED CONFIRMATION
  # --------------------------
  echo ""
  echo -e "${GREEN}Proceed with deployment? [Y/n]: ${NC}\c"
  read -r GO
  [[ "${GO:-Y}" =~ ^[Nn]$ ]] && { echo "Cancelled by user"; read; return; }

  # =====================================================
  # 📦 GENERATE BUILD FILES
  # =====================================================
  echo -e "\n${CYAN}🔨 Preparing container build files...${NC}"

  cat > config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "policy": {
    "levels": { "0": { "handshake": 2, "connIdle": 86400, "bufferSize": 2097152 } }
  },
  "inbounds": [
    {
      "tag": "trojan-ws", "port": 10001, "listen": "127.0.0.1", "protocol": "trojan",
      "settings": { "clients": [{"password": "$PASSWORD", "level": 0}] },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/tr-ws?ed=2560" },
        "sockopt": { "tcpNoDelay": true, "tcpFastOpen": true }
      }
    },
    {
      "tag": "vless-ws", "port": 10002, "listen": "127.0.0.1", "protocol": "vless",
      "settings": {
        "clients": [{"id": "$UUID", "level": 0}],
        "decryption": "none"
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vl-ws?ed=2560" },
        "sockopt": { "tcpNoDelay": true, "tcpFastOpen": true }
      }
    }
EOF

  if [ "$P_CHOICE" = "2" ]; then
    cat >> config.json <<EOF
    ,{
      "tag": "vless-reality", "port": 10003, "listen": "127.0.0.1", "protocol": "vless",
      "settings": {
        "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision", "level": 0}],
        "decryption": "none"
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls","quic"], "routeOnly": true },
      "streamSettings": {
        "network": "tcp", "security": "reality",
        "realitySettings": {
          "show": false, "xver": 0,
          "dest": "www.google.com:443",
          "serverNames": ["www.google.com", "google.com"],
          "privateKey": "GENERATE_AT_RUNTIME",
          "minClientVer": "", "maxClientVer": "",
          "maxTimeDiff": 60000,
          "shortIds": ["$SHORT_ID"]
        },
        "sockopt": { "tcpNoDelay": true, "tcpFastOpen": true }
      }
    }
EOF
  fi

  cat >> config.json <<'EOF'
  ],
  "outbounds": [
    {"protocol": "freedom", "settings": { "domainStrategy": "UseIPv4v6" }}
  ]
}
EOF

  cat > nginx.conf <<'EOF'
worker_processes auto; worker_rlimit_nofile 65535; worker_priority -10;
events { worker_connections 4096; use epoll; multi_accept on; accept_mutex off; }
http {
  include mime.types; default_type application/octet-stream;
  sendfile on; tcp_nodelay on; tcp_nopush on; keepalive_timeout 86400;
  client_max_body_size 0; proxy_buffering off; proxy_http_version 1.1;
  proxy_read_timeout 86400; proxy_send_timeout 86400;
  map $http_upgrade $connection_upgrade { default upgrade; '' close; }
  server {
    listen 8080 default_server; server_name _;
    location /health { return 200 "OK\n"; add_header Content-Type text/plain; }
    location / { proxy_pass https://www.google.com; proxy_set_header Host www.google.com; proxy_ssl_server_name on; }
    location /tr-ws { proxy_pass http://127.0.0.1:10001; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection $connection_upgrade; }
    location /vl-ws { proxy_pass http://127.0.0.1:10002; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection $connection_upgrade; }
  }
}
EOF

  cat > entrypoint.sh <<'EOF'
#!/bin/sh
if grep -q "GENERATE_AT_RUNTIME" /etc/xray.json; then
  KEYS=$(/usr/local/bin/xray x25519 2>&1)
  PRIV=$(echo "$KEYS" | grep "Private" | awk '{print $3}')
  PUB=$(echo "$KEYS" | grep "Public" | awk '{print $3}')
  sed -i "s|GENERATE_AT_RUNTIME|$PRIV|" /etc/xray.json
  echo "REALITY_PUB=$PUB" > /tmp/reality_pub.txt
fi
/usr/local/bin/xray run -c /etc/xray.json &
sleep 3
exec /usr/local/openresty/bin/openresty -g 'daemon off;'
EOF
  chmod +x entrypoint.sh

  cat > Dockerfile <<EOF
FROM --platform=$PLATFORM alpine:3.24 AS builder
RUN apk add --no-cache curl unzip ca-certificates openssl
WORKDIR /build
RUN curl -fsSL "https://github.com/XTLS/Xray-core/releases/latest/download/$XRAY_BIN" -o xray.zip \
  && unzip -q xray.zip xray \
  && chmod +x xray

FROM --platform=$PLATFORM openresty/openresty:1.25.3.2-0-alpine-fat
RUN addgroup -S xray && adduser -S xray -G xray
COPY --from=builder /build/xray /usr/local/bin/xray
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/xray /entrypoint.sh \
  && chown -R xray:xray /etc/xray.json /usr/local/openresty/nginx/logs/ /tmp
USER xray
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/health || exit 1
ENTRYPOINT ["/entrypoint.sh"]
EOF

  # =====================================================
  # 🏗️ BUILD IMAGE (QWIKLABS SAFE — NO --machine-type)
  # =====================================================
  AR_REGION="us-central1"
  REPO="kiana-xray-repo"
  IMG="$AR_REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$SERVICE_NAME"

  gcloud artifacts repositories create "$REPO" --repository-format=docker \
    --location="$AR_REGION" --project="$PROJECT_ID" --quiet >/dev/null 2>&1 || true
  gcloud auth configure-docker "$AR_REGION-docker.pkg.dev" --quiet >/dev/null 2>&1

  echo -e "\n${CYAN}🏗️ Building container image on Cloud Build (2-5 mins)...${NC}"
  gcloud builds submit --project="$PROJECT_ID" --tag "$IMG" --quiet .

  # =====================================================
  # 🚀 DEPLOY TO CLOUD RUN
  # =====================================================
  echo -e "\n${CYAN}🚀 Deploying to Cloud Run...${NC}"
  # shellcheck disable=SC2086
  gcloud run deploy "$SERVICE_NAME" \
    --image "$IMG" --project="$PROJECT_ID" --platform managed --region="$REGION" \
    --allow-unauthenticated --port 8080 --memory="$MEMORY" --cpu="$CPU" \
    --concurrency="$CONCURRENCY" --timeout 3600 \
    --min-instances="$MIN" --max-instances="$MAX" \
    --execution-environment gen2 --session-affinity \
    --health-check-type=http --health-check-http-endpoint=/health \
    $ARCH_FLAG $BILLING_FLAGS $H2_FLAG --quiet

  # =====================================================
  # ✅ FINAL OUTPUT
  # =====================================================
  SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --project="$PROJECT_ID" \
    --region="$REGION" --format='value(status.url)')
  REAL_DOMAIN="${SERVICE_URL#https://}"

  REALITY_PUB=""
  if [ "$P_CHOICE" = "2" ]; then
    sleep 10
    REALITY_PUB=$(gcloud logging read \
      "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME AND textPayload:REALITY_PUB" \
      --project="$PROJECT_ID" --limit=1 --format='value(textPayload)' 2>/dev/null | \
      sed 's/REALITY_PUB=//' || echo "Check container logs")
  fi

  TR_PATH_ENC="%2Ftr-ws%3Fed%3D2560"
  VL_PATH_ENC="%2Fvl-ws%3Fed%3D2560"

  TROJAN_LINK="trojan://${PASSWORD}@${CUSTOM_SNI_TROJAN}:443?path=${TR_PATH_ENC}&security=tls&type=ws&sni=${CUSTOM_SNI_TROJAN}&host=${REAL_DOMAIN}#KIANA-Trojan-${REGION}"
  VLESS_LINK="vless://${UUID}@${CUSTOM_SNI_VLESS}:443?encryption=none&path=${VL_PATH_ENC}&security=tls&type=ws&sni=${CUSTOM_SNI_VLESS}&host=${REAL_DOMAIN}#KIANA-VLESS-${REGION}"

  clear
  echo -e "${GREEN}
╔══════════════════════════════════════════════════════════╗
║            ✅ DEPLOYMENT SUCCESSFUL! KIANA-3.1          ║
╚══════════════════════════════════════════════════════════╝${NC}"
  echo -e "${CYAN}Service Name   :${NC} $SERVICE_NAME"
  echo -e "${CYAN}Region         :${NC} $REGION"
  echo -e "${CYAN}Architecture   :${NC} $([ "$ARCH" = "2" ] && echo "ARM64 Graviton" || echo "AMD64")"
  echo -e "${CYAN}Specs          :${NC} ${CPU} vCPU / ${MEMORY} | $BMODE"
  echo -e "${CYAN}Scaling        :${NC} Min=$MIN / Max=$MAX"
  echo -e "${CYAN}Service URL    :${NC} $SERVICE_URL"
  echo -e "${CYAN}Health Check   :${NC} $SERVICE_URL/health"
  echo -e "${CYAN}Real Host (WS) :${NC} $REAL_DOMAIN"
  echo ""
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}🔹 TROJAN + WS + TLS | CUSTOM FIREBASE SNI${NC}"
  echo -e "   ${YELLOW}Address     :${NC} $CUSTOM_SNI_TROJAN"
  echo -e "   ${YELLOW}Port        :${NC} 443"
  echo -e "   ${YELLOW}Password    :${NC} $PASSWORD"
  echo -e "   ${YELLOW}Transport   :${NC} WebSocket (WS)"
  echo -e "   ${YELLOW}Path        :${NC} /tr-ws"
  echo -e "   ${YELLOW}Early Data  :${NC} 2560"
  echo -e "   ${YELLOW}TLS         :${NC} ON"
  echo -e "   ${YELLOW}SNI         :${NC} $CUSTOM_SNI_TROJAN"
  echo -e "   ${YELLOW}Host Header :${NC} $REAL_DOMAIN"
  echo ""
  echo -e "${GREEN}🔹 VLESS + WS + TLS | CUSTOM FIREBASE SNI${NC}"
  echo -e "   ${YELLOW}Address     :${NC} $CUSTOM_SNI_VLESS"
  echo -e "   ${YELLOW}Port        :${NC} 443"
  echo -e "   ${YELLOW}UUID        :${NC} $UUID"
  echo -e "   ${YELLOW}Transport   :${NC} WebSocket (WS)"
  echo -e "   ${YELLOW}Path        :${NC} /vl-ws"
  echo -e "   ${YELLOW}Early Data  :${NC} 2560"
  echo -e "   ${YELLOW}TLS         :${NC} ON"
  echo -e "   ${YELLOW}SNI         :${NC} $CUSTOM_SNI_VLESS"
  echo -e "   ${YELLOW}Host Header :${NC} $REAL_DOMAIN"
  if [ "$P_CHOICE" = "2" ]; then
    echo ""
    echo -e "${GREEN}🔹 VLESS REALITY (XTLS Vision)${NC}"
    echo -e "   ${YELLOW}UUID        :${NC} $UUID"
    echo -e "   ${YELLOW}Flow        :${NC} xtls-rprx-vision"
    echo -e "   ${YELLOW}Public Key  :${NC} $REALITY_PUB"
    echo -e "   ${YELLOW}Short ID    :${NC} $SHORT_ID"
    echo -e "   ${YELLOW}Dest/SNI    :${NC} www.google.com"
  fi
  echo ""
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}📋 SHAREABLE LINKS:${NC}"
  echo -e "${YELLOW}$TROJAN_LINK${NC}"
  echo ""
  echo -e "${YELLOW}$VLESS_LINK${NC}"
  echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  read -p "Press [Enter] to return to Main Menu..."
}

# =====================================================
# 🎯 MAIN MENU
# =====================================================
while true; do
  clear
  echo -e "${MAGENTA}
╔══════════════════════════════════════════════╗
║      🚀 KIANA-3.1 ULTIMATE DEPLOYER         ║
║    Full English | Custom Firebase SNI       ║
║    ✅ QWIKLABS FIXED | NO COST DISPLAY      ║
╚══════════════════════════════════════════════╝${NC}"
  echo -e "  ${GREEN}1)${NC} 🚀 Deploy NEW Balanced Xray Service"
  echo -e "  ${GREEN}2)${NC} 📋 List All Deployed Services + URLs"
  echo -e "  ${GREEN}3)${NC} 🗑️ Delete a Deployed Service"
  echo -e "  ${GREEN}4)${NC} ❌ Exit Script"
  echo ""
  read -p "Select option [1-4]: " CHOICE
  case ${CHOICE:-} in
    1) deploy_service ;;
    2) list_services ;;
    3) delete_service ;;
    4) clear; echo -e "${GREEN}👋 Goodbye!${NC}"; exit 0 ;;
    *) echo -e "${RED}❌ Invalid option!${NC}"; sleep 1 ;;
  esac
done
