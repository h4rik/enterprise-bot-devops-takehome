FROM python:3.13.2-slim-bookworm AS builder

WORKDIR /build
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.13.2-slim-bookworm AS runtime

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY app.py .

RUN useradd --uid 10001 --create-home appuser
USER 10001:10001

EXPOSE 5000
CMD ["python", "app.py"]
