FROM python:3.11-slim

WORKDIR /app

COPY sim /app/sim
COPY tests /app/tests
COPY README.md /app/README.md

ENV PYTHONPATH=/app/sim

EXPOSE 8000

CMD ["python", "-m", "proteinloop_sim", "serve", "--host", "0.0.0.0", "--port", "8000"]

