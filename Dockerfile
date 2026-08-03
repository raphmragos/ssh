FROM openresty/openresty:alpine

# ✅ DINAGDAG ANG NGINX HTTP/2 DEPENDENCY + MGA KAILANGAN
RUN apk add --no-cache ca-certificates wget unzip tini nginx-mod-http-v2

# ✅ XRAY DOWNLOAD – WALANG PINAGBAGO, GINAMIT ANG TAMANG LINK
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

# ✅ IPINAKITA ANG PORT 8080 (KASAMA ANG HTTP/2/GPRPC)
EXPOSE 8080/tcp

ENTRYPOINT ["/sbin/tini", "--"]
# ✅ SIGURADONG UMAANDAL ANG PAREHONG XRAY AT OPENRESTY
CMD sh -c "xray run -c /etc/xray.json & exec openresty -g 'daemon off;'"

