FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    CLIPBOARD_HOST=0.0.0.0 \
    CLIPBOARD_PORT=27150 \
    CLIPBOARD_DATA_DIR=/data

WORKDIR /app
COPY server.py index.html style.css app.js favicon.svg ./
RUN mkdir -p /data && \
    groupadd --system --gid 10001 clipboard && \
    useradd --system --uid 10001 --gid clipboard --no-create-home clipboard && \
    chown clipboard:clipboard /data

USER clipboard
EXPOSE 27150
CMD ["python", "server.py"]
