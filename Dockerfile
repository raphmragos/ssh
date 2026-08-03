FROM openresty/openresty:alpine

# ✅ LAHAT NG KAILANGAN
RUN apk add --no-cache ca-certificates wget unzip tini openssl

# ✅ SIGURADONG GUMAGAWA NG SSL CERT SA TAMANG LOKASYON
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/key.pem \
    -out /etc/nginx/ssl/cert.pem \
    -subj "/C=PH/ST=Iloilo/L=Iloilo City/O=VIRGOZKI/CN=*"

# ✅ XRAY DOWNLOAD — TAMA ANG LINK
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
ENV PORT=8080
EXPOSE 8080/tcp

ENTRYPOINT ["/sbin/tini", "--"]
# ✅ PINAKA-SIGURADONG PAGPAPATAKBO:
# 1. Patakbuhin ang Xray — kahit magka-error, hindi titigil ang container
# 2. Siguradong tatakbo ang OpenResty bilang pangunahing proseso
CMD sh -c "xray run -c /etc/xray.json || true & \
           exec openresty -g 'daemon off;'"
