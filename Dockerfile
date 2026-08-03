FROM openresty/openresty:alpine

# ✅ DAGDAG ANG openssl PARA MAKAGUMAGAWA NG CERT
RUN apk add --no-cache ca-certificates wget unzip tini openssl

# ✅ GUMAGAWA NG SSL CERT — SIGURADONG NASA TAMANG LOKASYON
RUN mkdir -p /usr/local/openresty/nginx/conf/ssl && \
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /usr/local/openresty/nginx/conf/ssl/key.pem \
    -out /usr/local/openresty/nginx/conf/ssl/cert.pem \
    -subj "/C=PH/ST=Iloilo/L=Iloilo City/O=VIRGOZKI/CN=*"

# ✅ XRAY DOWNLOAD — WALANG BINAGO
RUN wget --timeout=120 -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip && \
    unzip -q /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/ && \
    mkdir -p /usr/local/share/xray/ && \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray /tmp/xray.zip

COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY index.html /usr/local/openresty/nginx/html/index.html

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
# ✅ LOCK SA 8080 — TUGMA SA CLOUD RUN AT DEPLOY SCRIPT
ENV PORT=8080
EXPOSE ${PORT}/tcp

ENTRYPOINT ["/sbin/tini", "--"]
# ✅ TINANGGAL ANG MALING sed — HINDI NA KAILANGAN DAHIL LOCK NA SA 8080
CMD sh -c "xray run -c /etc/xray.json >/dev/null 2>&1 & \
           exec openresty -g 'daemon off;'"
