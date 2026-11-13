FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Asia/Shanghai

WORKDIR /app

COPY pyproject.toml README.md requirements.lock ./
COPY src ./src
RUN --mount=type=secret,id=proxy_ca \
    if [ -f /run/secrets/proxy_ca ]; then export PIP_CERT=/run/secrets/proxy_ca; fi \
    && pip install --upgrade pip \
    && pip install -r requirements.lock \
    && pip install --no-deps .

RUN useradd --create-home --uid 10001 radar \
    && mkdir -p /app/data /app/logs \
    && chown -R radar:radar /app

USER radar

EXPOSE 8000

CMD ["uvicorn", "radar.main:app", "--host", "0.0.0.0", "--port", "8000"]
