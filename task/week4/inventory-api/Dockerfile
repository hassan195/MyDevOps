FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc=4:14.2.0-1 \
    libpq-dev=17.11-0+deb13u1\
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY inventory-api.py .


RUN useradd --create-home --uid 1001 appuser
USER 1001

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=5 \
   CMD ["sh", "-c", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:3000/health', timeout=3)\" || exit 1 "]

CMD ["python", "inventory-api.py"]