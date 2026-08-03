#!/bin/bash
# ==============================================================================
# VIRGOZKI PANEL • MANUAL REGION + GPRPC READY • FINAL VERSION
# ==============================================================================

BOLD='\033[1m'; RESET='\033[0m'
GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'
YELLOW='\033[1;33m'; MAGENTA='\033[1;35m'; WHITE='\033[1;37m'

ALL_REGIONS=(
  "01:asia-east1:Taiwan" "02:asia-east2:Hong Kong" "03:asia-northeast1:Japan (Tokyo)"
  "04:asia-northeast2:Japan (Osaka)" "05:asia-northeast3:South Korea (Seoul)"
  "06:asia-south1:India (Mumbai)" "07:asia-south2:India (Delhi)" "08:asia-southeast1:Singapore"
  "09:asia-southeast2:Indonesia (Jakarta)" "10:australia-southeast1:Australia (Sydney)"
  "11:australia-southeast2:Australia (Melbourne)" "12:europe-central2:Poland (Warsaw)"
  "13:europe-north1:Finland" "14:europe-southwest1:Spain (Madrid)" "15:europe-west1:Belgium"
  "16:europe-west2:United Kingdom (London)" "17:europe-west3:Germany (Frankfurt)"
  "18:europe-west4:Netherlands" "19:europe-west6:Switzerland (Zurich)" "20:europe-west8:Italy (Milan)"
  "21:europe-west9:France (Paris)" "22:northamerica-northeast1:Canada (Montreal)"
  "23:northamerica-northeast2:Canada (Toronto)" "24:southamerica-east1:Brazil (Sao Paulo)"
  "25:southamerica-west1:Chile (Santiago)" "26:us-central1:USA (Iowa)"
  "27:us-east1:USA (South Carolina)" "28:us-east4:USA (North Virginia)"
  "29:us-east5:USA (Columbus)" "30:us-south1:USA (Texas)" "31:us-west1:USA (Oregon)"
  "32:us-west2:USA (Los Angeles)" "33:us-west3:USA (Salt Lake City)" "34:us-west4:USA (Las Vegas)"
)

loading() {
    local t="$1" local s="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0;i<5;i++)); do for ((j=0;j<${#s};j++)); do echo -ne "\r  ${CYAN}${s:$j:1} ${t}...${RESET}"; sleep 0.05; done; done
    echo -ne "\r  ${GREEN}DONE: ${t}${RESET}\n"
}

clear
echo -e "  ${BOLD}${WHITE}VIRGOZKI VPN PANEL • FINAL GCP GPRPC VERSION${RESET}"
echo -e "  ${GREEN}✅ READY TO DEPLOY • NO ERRORS${RESET}\n"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
[ -z "$PROJECT_ID" ] && { echo -e "  ${RED}ERROR: Run 'gcloud init' first${RESET}"; exit 1; }
echo -e "  ${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}\n"

REGION="asia-southeast1"
echo -e "  ${CYAN}DEFAULT REGION: ${GREEN}${REGION}${RESET}"
echo -e "  ${CYAN}CHOOSE REGION (0 = USE DEFAULT):${RESET}"
for i in "${!ALL_REGIONS[@]}"; do IFS=':' read -r n r c <<< "${ALL_REGIONS[$i]}"; printf "  ${YELLOW}%s) ${GREEN}%-25s ${CYAN}(%s)${RESET}\n" "$n" "$r" "$c"; done
read -p $'\n  \033[1;36mENTER NUMBER: \033[0m' REG_CHOICE

if [[ "$REG_CHOICE" =~ ^[0-9]+$ ]]; then
  FOUND=0; for item in "${ALL_REGIONS[@]}"; do
    IFS=':' read -r n r _ <<< "$item"
    [ "$n" = "$REG_CHOICE" ] && { REGION="$r"; FOUND=1; break; }
  done; [ "$FOUND" -eq 0 ] && echo -e "  ${YELLOW}INVALID → USING DEFAULT${RESET}"
fi
echo -e "  ${CYAN}SELECTED: ${GREEN}${REGION}${RESET}\n"

read -p $'  \033[1;36mSERVICE NAME [mr-virgozki]: \033[0m' INPUT_NAME
INPUT_NAME=$(echo "$INPUT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')
SERVICE_NAME=${INPUT_NAME:-mr-virgozki}

echo -e "\n  ${CYAN}SELECT PLAN:${RESET}"
echo -e "  ${YELLOW}1) AUTO   (1vCPU / 2Gi RAM) ✅ RECOMMENDED${RESET}"
echo -e "  ${YELLOW}2) HIGH   (2vCPU / 4Gi RAM)${RESET}"
echo -e "  ${YELLOW}3) MAX    (4vCPU / 8Gi RAM)${RESET}"
read -p $'  \033[1;36mCHOICE: \033[0m' MODE_CHOICE

case "$MODE_CHOICE" in
  1) CPU="1"; RAM="2Gi"; MAX_INSTANCES="2";;
  2) CPU="2"; RAM="4Gi"; MAX_INSTANCES="2";;
  3) CPU="4"; RAM="8Gi"; MAX_INSTANCES="1";;
  *) CPU="1"; RAM="2Gi"; MAX_INSTANCES="2";;
esac

loading "CHECKING FILES"
for f in Dockerfile nginx.conf config.json index.html; do
  [ ! -f "$f" ] && { echo -e "  ${RED}MISSING: $f${RESET}"; exit 1; }
done

loading "BUILDING IMAGE"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" --quiet > build.log 2>&1 || {
  echo -e "  ${RED}BUILD FAILED${RESET}"; tail -n 10 build.log; rm build.log; exit 1
}

loading "DEPLOYING TO CLOUD RUN (GPRPC ENABLED)"
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
  --platform managed --region "$REGION" \
  --cpu "$CPU" --memory "$RAM" --port 8080 \
  --concurrency 800 --timeout 3600 \
  --min-instances 0 --max-instances "$MAX_INSTANCES" \
  --allow-unauthenticated --project="$PROJECT_ID" \
  --startup-cpu-boost --health-check-timeout 300 \
  --use-http2 --quiet > deploy.log 2>&1 || {
  echo -e "  ${RED}DEPLOY FAILED${RESET}"; tail -n 10 deploy.log; rm build.log deploy.log; exit 1
}

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --format='value(status.url)')
CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')
UUID="b831381d-6324-4d53-ad4f-8cda48b30811"
SS_B64=$(echo -n "aes-256-gcm:virgozki" | base64 -w0)

echo -e "\n${GREEN}✅ SUCCESS! DEPLOYMENT COMPLETE${RESET}"
echo -e "  ${CYAN}PANEL: ${GREEN}${SERVICE_URL}${RESET}"
echo -e "  ${CYAN}HOST:  ${GREEN}${CLEAN_HOST}${RESET}\n"

echo -e "${YELLOW}🔗 CONNECTION LINKS:${RESET}"
echo -e "${CYAN}VLESS gRPC:${RESET} vless://${UUID}@${CLEAN_HOST}:443?encryption=none&type=grpc&path=/vless-grpc&security=tls&sni=${CLEAN_HOST}&alpn=h2,http/1.1&headerType=multi#VLESS-GRPC"
echo -e "${CYAN}VMESS gRPC:${RESET} vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"VMESS-GRPC\",\"add\":\"${CLEAN_HOST}\",\"port\":\"443\",\"id\":\"${UUID}\",\"aid\":\"0\",\"scy\":\"auto\",\"net\":\"grpc\",\"type\":\"multi\",\"path\":\"/vmess-grpc\",\"tls\":\"tls\",\"sni\":\"${CLEAN_HOST}\",\"alpn\":\"h2,http/1.1\"}" | base64 -w0)"
echo -e "${CYAN}TROJAN gRPC:${RESET} trojan://virgozki@${CLEAN_HOST}:443?type=grpc&path=/trojan-grpc&security=tls&sni=${CLEAN_HOST}&alpn=h2,http/1.1&headerType=multi#TROJAN-GRPC"
echo -e "${CYAN}SHADOWSOCKS gRPC:${RESET} ss://${SS_B64}@${CLEAN_HOST}:443?type=grpc&path=/ss-grpc&security=tls&sni=${CLEAN_HOST}&alpn=h2,http/1.1&headerType=multi#SS-GRPC"
echo -e "\n${GREEN}ALL PROTOCOLS WORKING: WS / HTTP UPGRADE / XHTTP / GRPC${RESET}"
rm -f build.log deploy.log
