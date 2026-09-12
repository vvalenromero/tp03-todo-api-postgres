#!/usr/bin/env bash
# Prueba de persistencia de la Seccion 10.4 del PRD.
# Demuestra que los datos viven en el VOLUMEN de Postgres y no en el contenedor
# de la API: restart api -> se conservan; down -v -> se pierden.
#
# Requisitos: `docker compose up --build -d` ejecutado y curl disponible.
set -u

cd "$(dirname "$0")/.."            # raiz del repositorio
BASE="${BASE:-http://localhost:3001}"
COMPOSE="docker compose"
P="entrega/persistencia.txt"
mkdir -p "$(dirname "$P")"

echo "PRUEBA DE PERSISTENCIA (Sección 10.4 del PRD)" > "$P"
echo "Generado: $(date)" >> "$P"

echo ">> 1) POST /tasks (crear tarea de prueba de persistencia)" >> "$P"
RESP=$(curl -s -X POST "$BASE/tasks" -H 'Content-Type: application/json' \
  -d '{"title":"Tarea persistencia TP3","status":"pending"}')
echo "$RESP" >> "$P"
PID=$(echo "$RESP" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
echo "ID creado: $PID" >> "$P"

echo ">> 2) docker compose restart api  (reinicio SOLO del contenedor de la API)" >> "$P"
$COMPOSE restart api >> "$P" 2>&1
sleep 6

echo ">> 3) GET /tasks/$PID despues del restart (debe SEGUIR existiendo -> 200)" >> "$P"
echo "[GET /tasks/$PID] -> $(curl -s -o /dev/null -w '%{http_code}' "$BASE/tasks/$PID")" >> "$P"

echo ">> 4) docker compose down -v (elimina contenedores Y el volumen todo_pgdata)" >> "$P"
$COMPOSE down -v >> "$P" 2>&1

echo ">> 5) docker compose up --build -d (volver a levantar desde cero, base vacia)" >> "$P"
$COMPOSE up --build -d >> "$P" 2>&1
sleep 20

echo ">> 6) GET /tasks/$PID despues de down -v + up (debe dar 404, datos PERDIDOS)" >> "$P"
echo "[GET /tasks/$PID] -> $(curl -s -o /dev/null -w '%{http_code}' "$BASE/tasks/$PID")" >> "$P"

echo "FIN PRUEBA PERSISTENCIA" >> "$P"
echo "Evidencia guardada en $P"
