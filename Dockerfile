FROM openresty/openresty:alpine

# Install dependencies
RUN apk add --no-cache ca-certificates wget tini openssl

# Generate SSL cert (matches nginx.conf path)
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/key.pem \
    -out /etc/nginx/ssl/cert.pem \
    -subj "/C=PH/ST=Western Visayas/L=Iloilo City/O=Virgozki/CN=*"

# Download Xray
RUN wget -q https://github.com/XTLS/Xray-core/releases/download/v24.12.31/Xray-linux-64.zip -O /tmp/xray.zip && \
    unzip -q /tmp/xray.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray /usr/local/bin/xdg && \
    rm -rf /tmp/xray.zip

# Copy config files
COPY config.json /etc/xray/config.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY index.html /usr/local/openresty/nginx/html/index.html

# Expose port
EXPOSE 8080

# Start services
ENTRYPOINT ["/sbin/tini", "--"]
CMD sh -c "xray run -c /etc/xray/config.json >/dev/null 2>&1 & exec openresty -g 'daemon off;'"
