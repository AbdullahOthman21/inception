FROM alpine:3.23

RUN apk add nginx openssl

RUN mkdir -p /etc/nginx/ssl \
    && openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=JO/ST=Irbid/L=Irbid/O=42/CN=abdothma.42.fr"

RUN sed -i 's/TLSv1.1 //' /etc/nginx/nginx.conf

COPY config /etc/nginx/http.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
