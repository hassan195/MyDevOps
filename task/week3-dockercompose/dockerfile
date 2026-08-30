FROM alpine:3.20 AS validator

WORKDIR /validator 
COPY index.html .

RUN apk add --no-cache tidyhtml && tidy -q -e index.html 


FROM nginx:1.26.2-alpine  AS runtime
RUN apk add --no-cache curl
COPY --from=validator /validator/index.html /usr/share/nginx/html/index.html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
   CMD curl -f --max-time 3 http://localhost || exit 1

ENTRYPOINT ["/entrypoint.sh"]