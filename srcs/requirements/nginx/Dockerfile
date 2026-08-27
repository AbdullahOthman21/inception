FROM alpine:3.23.5

RUN apk update && apk add --no-cache nginx openssl

RUN mkdir -p /etc/nginx/ssl \
    && openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=JO/ST=Irbid/L=Irbid/O=42/CN=abdothma.42.fr"

COPY ./conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
