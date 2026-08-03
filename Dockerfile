FROM openresty/openresty:alpine

# ✅ INAYOS: Inalis ang hindi umiiral na "nginx-mod-http-v2" — BUILT-IN NA ITO SA OPENRESTY!
RUN apk add --no-cache ca-certificates wget unzip tini

# ✅ XRAY DOWNLOAD – TAMA ANG LINK AT WALANG BINAGO
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
# ✅ SIGURADUHIN ANG PORT NA KAILANGAN NG CLOUD RUN
ENV PORT=8080
EXPOSE ${PORT}/tcp

ENTRYPOINT ["/sbin/tini", "--"]
# ✅ PINAKATAMA NA PARAAN:
# 1. Palitan ang port sa nginx.conf base sa ibinigay ng Cloud Run
# 2. Patakbuhin ang Xray sa background nang ligtas
# 3. Patakbuhin ang OpenResty bilang pangunahing proseso (hindi mag-e-exit)
CMD sh -c "sed -i 's/listen 8080 ssl http2 reuseport;/listen '$PORT' ssl http2 reuseport;/g' /usr/local/openresty/nginx/conf/nginx.conf && \
           sed -i 's/listen \[::\]:8080 ssl http2 reuseport;/listen \[::\]:'$PORT' ssl http2 reuseport;/g' /usr/local/openresty/nginx/conf/nginx.conf && \
           xray run -c /etc/xray.json & \
           exec openresty -g 'daemon off;'"
