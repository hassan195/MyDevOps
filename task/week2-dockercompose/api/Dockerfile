FROM python:3.12-alpine

WORKDIR /api

COPY api.py .

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
   CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3000/api', timeout=3)" || exit 1

CMD ["python", "api.py"]
