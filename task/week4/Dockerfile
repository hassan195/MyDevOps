FROM alpine:3.20 AS validator

WORKDIR /validator
COPY index.html .

RUN apk add --no-cache tidyhtml=5.8.0-r3 \
    && tidy -q -e index.html

FROM nginx:1.26.2-alpine AS runtime

RUN apk add --no-cache curl=8.14.1-r2

COPY --from=validator /validator/index.html /usr/share/nginx/html/index.html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --chmod=755 entrypoint.sh /entrypoint.sh

RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown nginx:nginx /var/run/nginx.pid

USER 101

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
   CMD ["sh", "-c", "curl -f --max-time 3 http://localhost:8080 || exit 1"]

ENTRYPOINT ["/entrypoint.sh"]