FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY inventory-api.py .

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=5 \
   CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3000/health', timeout=3)" || exit 1

CMD ["python", "inventory-api.py"]