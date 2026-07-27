#!/bin/bash
set -euo pipefail

# =====================================================
# 🚀 KIANA-3.1 ULTIMATE | GCP CLOUD RUN DEPLOYER
# ✅ QWIKLABS 100% COMPATIBLE — ALL ERRORS FIXED
# ✅ NO COST DISPLAY | NO HEALTH FLAGS | CORRECT CPU BOOST
# =====================================================
CUSTOM_SNI_VLESS="firebaseremoteconfigrealtime.googleapis.com"
CUSTOM_SNI_TROJAN="firebase-settings.crashlytics.com"

GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'
CYAN='\033[1;36m'; MAGENTA='\033[1;35m'; NC='\033[0m'

list_services() {
  clear
  echo -e "\n${CYAN}📋 DEPLOYED SERVICES${NC}"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  gcloud run services list \
    --format="table(metadata.name, status.url, region)" \
    --filter="metadata.name~^xray-" --project="$PROJECT_ID" || \
  gcloud run services list --format="table(metadata.name, status.url, region)" --project="$PROJECT_ID"
  read -p "Press [Enter] to return..."
}

delete_service() {
  clear
  echo -e "\n${CYAN}🗑️ DELETE SERVICE${NC}"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  gcloud run services list --project="$PROJECT_ID" --format="table(metadata.name, region)" --filter="metadata.name~^xray-"
  read -p "Name to delete (Enter=cancel): " DEL_NAME
  [ -z "$DEL_NAME" ] && { echo "Cancelled"; read; return; }
  read -p "${RED}Type YES to confirm: ${NC}" CONF
  if [ "$CONF" = "YES" ]; then
    R=$(gcloud run services describe "$DEL_NAME" --project="$PROJECT_ID" --format='value(region)' 2>/dev/null || echo us-central1)
    gcloud run services delete "$DEL_NAME" --project="$PROJECT_ID" --region="$R" --quiet
    echo -e "${GREEN}✅ Deleted${NC}"
  fi
  read -p "Press [Enter]..."
}

select_region() {
  echo -e "\n${CYAN}🌍 REGION${NC}"
  echo "1) us-central1 (Qwiklabs ✅)  5) asia-east1   9) asia-northeast1  13) europe-west4"
  echo "2) us-east1                   6) asia-southeast1  10) asia-northeast3 14) europe-west9"
  echo "3) us-east4                   7) asia-southeast2  11) australia-southeast1"
  echo "4) us-west1                   8) asia-south1      12) europe-west1"
  read -p "Select [1-14, default=1]: " R; R=${R:-1}
  case $R in
    1) REGION=us-central1 ;; 2) REGION=us-east1 ;; 3) REGION=us-east4 ;; 4) REGION=us-west1 ;;
    5) REGION=asia-east1 ;; 6) REGION=asia-southeast1 ;; 7) REGION=asia-southeast2 ;; 8) REGION=asia-south1 ;;
    9) REGION=asia-northeast1 ;; 10) REGION=asia-northeast3 ;; 11) REGION=australia-southeast1 ;;
    12) REGION=europe-west1 ;; 13) REGION=europe-west4 ;; 14) REGION=europe-west9 ;;
    *) REGION=us-central1 ;;
  esac
  echo -e "${GREEN}✅ $REGION${NC}"
}

deploy_service() {
  clear
  echo -e "${MAGENTA}🚀 KIANA-3.1 DEPLOYER${NC}"
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
  [ -z "$PROJECT_ID" ] && { echo -e "${RED}Set project first${NC}"; read; return; }
  echo -e "${CYAN}Project: $PROJECT_ID${NC}"
  [[ "$PROJECT_ID" == qwiklabs-gcp-* ]] && echo -e "${YELLOW}ℹ️ Qwiklabs mode${NC}"

  gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project="$PROJECT_ID" --quiet >/dev/null 2>&1 || true

  UUID="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16 | sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/\1-\2-\3-\4-\5/')"
  PASSWORD="$(openssl rand -hex 6)"
  RAND="$(openssl rand -hex 3)"
  SERVICE_NAME="xray-balanced-$RAND"
  BUILD_DIR="$(mktemp -d)"; trap 'rm -rf "$BUILD_DIR"' EXIT; cd "$BUILD_DIR" || exit 1
  echo -e "${GREEN}✅ Credentials generated${NC}"

  select_region

  echo -e "\n${CYAN}💻 ARCH (1=AMD64 ✅, 2=ARM64)${NC}"
  read -p "[1-2, default=1]: " ARCH; ARCH=${ARCH:-1}
  if [ "$ARCH" = "2" ]; then
    ARCH_FLAG="--architecture arm64"; XRAY_BIN="Xray-linux-arm64-v8a.zip"; PLATFORM="linux/arm64"
  else
    ARCH_FLAG=""; XRAY_BIN="Xray-linux-64.zip"; PLATFORM="linux/amd64"
  fi

  echo -e "\n${CYAN}💰 BILLING (1=Request, 2=Instance ✅)${NC}"
  read -p "[1-2, default=2]: " B; B=${B:-2}
  # ✅ FIX: --cpu-boost (NOT --startup-cpu-boost)
  [ "$B" = "2" ] && BILLING_FLAGS="--no-cpu-throttling --cpu-boost" BMODE="Instance" || BILLING_FLAGS="--cpu-throttling --cpu-boost" BMODE="Request"
  echo -e "${GREEN}✅ $BMODE${NC}"

  echo -e "\n${CYAN}⚙️ vCPU (0.5/1/2/4, default=2)${NC}"
  while true; do read -p ": " CPU; CPU=${CPU:-2}; [[ "$CPU" =~ ^(0.5|1|2|4)$ ]] && break; done
  case $CPU in
    0.5) VM=("256Mi" "512Mi" "1Gi") ;;
    1)   VM=("512Mi" "1Gi" "2Gi" "4Gi") ;;
    2)   VM=("1Gi" "2Gi" "4Gi" "8Gi") ;;
    4)   VM=("2Gi" "4Gi" "8Gi" "16Gi") ;;
  esac
  echo -e "Valid: ${VM[*]} (type number OR ${VM[1]})"
  while true; do
    read -p "Memory [default=${VM[1]}]: " MI; MI=${MI:-${VM[1]}}
    [[ "$MI" =~ ^[0-9]+$ ]] && { [[ " ${VM[*]} " =~ " ${MI}Gi " ]] && MEMORY="${MI}Gi" || MEMORY=""; } || MEMORY="$MI"
    V=0; for X in "${VM[@]}"; do [[ "$X" == "$MEMORY" ]] && V=1 && break; done
    [[ $V -eq 1 ]] && break || echo -e "${RED}❌ Invalid${NC}"
  done
  [[ "$CPU" =~ ^(0.5|1)$ ]] && CON=300 || CON=800
  echo -e "${GREEN}✅ ${CPU} / ${MEMORY} | ${CON}${NC}"

  read -p "Min instances [0]: " MIN; MIN=${MIN:-0}
  read -p "Max instances [1]: " MAX; MAX=${MAX:-1}

  echo -e "\n${CYAN}🔐 PROTOCOL (1=WS/TLS, 2=+REALITY)${NC}"
  read -p "[1-2, default=1]: " PC; PC=${PC:-1}; SID=""
  [ "$PC" = "2" ] && SID="$(openssl rand -hex 4)" && echo -e "${GREEN}✅ REALITY${NC}"

  read -p "HTTP/2? [Y/n]: " H2
  H2_FLAG=$([[ ! "${H2:-Y}" =~ ^[Nn]$ ]] && echo --use-http2 || echo "")

  echo ""; echo -e "${GREEN}Proceed? [Y/n]: ${NC}\c"; read -r GO
  [[ "${GO:-Y}" =~ ^[Nn]$ ]] && { echo Cancelled; read; return; }

  echo -e "\n${CYAN}🔨 Build files...${NC}"
  cat > config.json <<EOF
{"log":{"loglevel":"warning"},"inbounds":[
{"tag":"tr","port":10001,"listen":"127.0.0.1","protocol":"trojan","settings":{"clients":[{"password":"$PASSWORD","level":0}]},"sniffing":{"enabled":true,"destOverride":["http","tls","quic"]},"streamSettings":{"network":"ws","wsSettings":{"path":"/tr-ws?ed=2560"}}},
{"tag":"vl","port":10002,"listen":"127.0.0.1","protocol":"vless","settings":{"clients":[{"id":"$UUID","level":0}],"decryption":"none"},"sniffing":{"enabled":true,"destOverride":["http","tls","quic"]},"streamSettings":{"network":"ws","wsSettings":{"path":"/vl-ws?ed=2560"}}}
EOF
  [ "$PC" = "2" ] && cat >> config.json <<EOF
,{"tag":"r","port":10003,"listen":"127.0.0.1","protocol":"vless","settings":{"clients":[{"id":"$UUID","flow":"xtls-rprx-vision","level":0}],"decryption":"none"},"streamSettings":{"network":"tcp","security":"reality","realitySettings":{"dest":"www.google.com:443","serverNames":["www.google.com","google.com"],"privateKey":"GENERATE_AT_RUNTIME","shortIds":["$SID"]}}}
EOF
  cat >> config.json <<< '],"outbounds":[{"protocol":"freedom"}]}'

  cat > nginx.conf <<'EOF'
worker_processes auto; events{worker_connections 4096;}
http{include mime.types; sendfile on; tcp_nodelay on; keepalive_timeout 86400; client_max_body_size 0; proxy_buffering off; proxy_http_version 1.1;
map $http_upgrade $c{default upgrade; '' close;}
server{listen 8080;
location /health{return 200 "OK\n";}
location /{proxy_pass https://www.google.com; proxy_set_header Host www.google.com;}
location /tr-ws{proxy_pass http://127.0.0.1:10001; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection $c;}
location /vl-ws{proxy_pass http://127.0.0.1:10002; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection $c;}
}}
EOF

  cat > entrypoint.sh <<'EOF'
#!/bin/sh
grep -q GENERATE_AT_RUNTIME /etc/xray.json && {
  K=$(/usr/local/bin/xray x25519 2>&1)
  sed -i "s|GENERATE_AT_RUNTIME|$(echo "$K"|grep Private|awk '{print $3}')|" /etc/xray.json
  echo "PUB=$(echo "$K"|grep Public|awk '{print $3}')" > /tmp/pub.txt
}
/usr/local/bin/xray run -c /etc/xray.json & sleep 3
exec /usr/local/openresty/bin/openresty -g 'daemon off;'
EOF
  chmod +x entrypoint.sh

  cat > Dockerfile <<EOF
FROM --platform=$PLATFORM alpine:3.24 AS b
RUN apk add --no-cache curl unzip ca-certificates
WORKDIR /build
RUN curl -fsSL https://github.com/XTLS/Xray-core/releases/latest/download/$XRAY_BIN -o x.zip && unzip -q x.zip xray && chmod +x xray
FROM --platform=$PLATFORM openresty/openresty:1.25.3.2-0-alpine-fat
RUN addgroup -S x && adduser -S x -G x
COPY --from=b /build/xray /usr/local/bin/xray
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/xray /entrypoint.sh && chown -R x:x /etc/xray.json /usr/local/openresty/nginx/logs /tmp
USER x
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
EOF

  AR=us-central1; REPO=kiana-xray-repo
  IMG="$AR-docker.pkg.dev/$PROJECT_ID/$REPO/$SERVICE_NAME"
  gcloud artifacts repositories create "$REPO" --repository-format=docker --location="$AR" --project="$PROJECT_ID" --quiet >/dev/null 2>&1 || true
  gcloud auth configure-docker "$AR-docker.pkg.dev" --quiet >/dev/null 2>&1
  echo -e "\n${CYAN}🏗️ Building (2-5m)...${NC}"
  gcloud builds submit --project="$PROJECT_ID" --tag "$IMG" --quiet .

  # =====================================================
  # ✅ FINAL QWIKLABS FIX: ZERO HEALTH-CHECK FLAGS
  # =====================================================
  echo -e "\n${CYAN}🚀 Deploying...${NC}"
  # shellcheck disable=SC2086
  gcloud run deploy "$SERVICE_NAME" \
    --image "$IMG" --project "$PROJECT_ID" --platform managed --region "$REGION" \
    --allow-unauthenticated --port 8080 --memory "$MEMORY" --cpu "$CPU" \
    --concurrency "$CON" --timeout 3600 \
    --min-instances "$MIN" --max-instances "$MAX" \
    --execution-environment gen2 --session-affinity \
    $ARCH_FLAG $BILLING_FLAGS $H2_FLAG --quiet

  URL=$(gcloud run services describe "$SERVICE_NAME" --project "$PROJECT_ID" --region "$REGION" --format='value(status.url)')
  HOST="${URL#https://}"
  TPE="%2Ftr-ws%3Fed%3D2560"; VPE="%2Fvl-ws%3Fed%3D2560"
  TL="trojan://${PASSWORD}@${CUSTOM_SNI_TROJAN}:443?path=${TPE}&security=tls&type=ws&sni=${CUSTOM_SNI_TROJAN}&host=${HOST}#KIANA-Trojan-${REGION}"
  VL="vless://${UUID}@${CUSTOM_SNI_VLESS}:443?encryption=none&path=${VPE}&security=tls&type=ws&sni=${CUSTOM_SNI_VLESS}&host=${HOST}#KIANA-VLESS-${REGION}"
  clear
  echo -e "${GREEN}✅ DEPLOYED!${NC}"
  echo -e "${CYAN}URL :${NC} $URL"
  echo -e "${CYAN}HOST:${NC} $HOST"
  echo ""
  echo -e "${YELLOW}$TL${NC}"
  echo ""
  echo -e "${YELLOW}$VL${NC}"
  read -p "Enter..."
}

while true; do
  clear
  echo -e "${MAGENTA}🚀 KIANA-3.1 | QWIKLABS FIXED${NC}"
  echo "1) 🚀 Deploy  2) 📋 List  3) 🗑️ Delete  4) ❌ Exit"
  read -p ": " C
  case ${C:-} in
    1) deploy_service ;; 2) list_services ;; 3) delete_service ;;
    4) clear; echo Bye; exit 0 ;; *) echo -e "${RED}❌ Invalid${NC}"; sleep 1 ;;
  esac
done
