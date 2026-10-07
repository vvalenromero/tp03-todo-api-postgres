#!/usr/bin/env bash
# Evidencia de pruebas de la API TODO (TP3 - Programación Avanzada)
# Ejercita los 5 endpoints (RF-01..RF-06) con casos 200/201/204/400/404
# y deja la salida en entrega/evidencia.txt.
#
# Requisitos: API levantada (`docker compose up --build -d`) y `curl` disponible.
# Variables opcionales: BASE (default http://localhost:3001)
set -u

cd "$(dirname "$0")/.."            # raiz del repositorio
BASE="${BASE:-http://localhost:3001}"
OUT="entrega/evidencia.txt"
mkdir -p "$(dirname "$OUT")"

# code <method> <path> [json] -> devuelve el status HTTP
code() {
  method="$1"; path="$2"; body="${3:-}"
  if [ -n "$body" ]; then
    curl -s -o /dev/null -w '%{http_code}' -X "$method" "$BASE$path" \
      -H 'Content-Type: application/json' -d "$body"
  else
    curl -s -o /dev/null -w '%{http_code}' -X "$method" "$BASE$path"
  fi
}
body() {
  method="$1"; path="$2"; body="${3:-}"
  if [ -n "$body" ]; then
    curl -s -X "$method" "$BASE$path" -H 'Content-Type: application/json' -d "$body"
  else
    curl -s -X "$method" "$BASE$path"
  fi
}
log() { echo "==================================================" >> "$OUT"; echo ">> $1" >> "$OUT"; }

echo "EVIDENCIA DE PRUEBAS - TODO API (TP3 Programación Avanzada)" > "$OUT"
echo "Generado: $(date)" >> "$OUT"
echo "Base URL: $BASE" >> "$OUT"

log "RF-01 / RF-06 - GET /tasks (lista + filtro por status)"
echo "[GET /tasks] -> $(code GET /tasks)" >> "$OUT"
body GET /tasks >> "$OUT"; echo >> "$OUT"
echo "[GET /tasks?status=pending] -> $(curl -s -o /dev/null -w '%{http_code}' "$BASE/tasks?status=pending")" >> "$OUT"
curl -s "$BASE/tasks?status=pending" >> "$OUT"; echo >> "$OUT"

# Primer id existente, sin depender de python.
ID=$(body GET /tasks | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
log "RF-02 - GET /tasks/:id (existente)"
echo "ID usado: $ID" >> "$OUT"
echo "[GET /tasks/$ID] -> $(code GET "/tasks/$ID")" >> "$OUT"
body GET "/tasks/$ID" >> "$OUT"; echo >> "$OUT"

log "RF-02 - GET /tasks/:id (NO existente) -> esperado 404"
echo "[GET /tasks/9999] -> $(code GET /tasks/9999)" >> "$OUT"
body GET /tasks/9999 >> "$OUT"; echo >> "$OUT"

log "RF-03 - POST /tasks (crear)"
NEW='{"title":"Tarea de prueba TP3","description":"Creada por script de evidencia","status":"pending"}'
echo "[POST /tasks] -> $(code POST /tasks "$NEW")" >> "$OUT"
body POST /tasks "$NEW" >> "$OUT"; echo >> "$OUT"

log "RF-03 - POST /tasks (sin title) -> esperado 400"
echo "[POST /tasks {}] -> $(code POST /tasks '{}')" >> "$OUT"

log "RF-04 - PUT /tasks/:id (actualiza solo status, conserva el resto)"
echo "[PUT /tasks/$ID] -> $(code PUT "/tasks/$ID" '{"status":"completed"}')" >> "$OUT"
body PUT "/tasks/$ID" '{"status":"completed"}' >> "$OUT"; echo >> "$OUT"

log "RF-04 - Verificacion: updated_at cambio, title/description se conservaron"
body GET "/tasks/$ID" >> "$OUT"; echo >> "$OUT"

log "RF-04 - PUT /tasks/:id (NO existente) -> esperado 404"
echo "[PUT /tasks/9999] -> $(code PUT /tasks/9999 '{"title":"x"}')" >> "$OUT"
body PUT /tasks/9999 '{"title":"x"}' >> "$OUT"; echo >> "$OUT"

log "RF-05 - DELETE /tasks/:id (eliminar) -> esperado 204"
echo "[DELETE /tasks/$ID] -> $(code DELETE "/tasks/$ID")" >> "$OUT"

log "RF-05 - DELETE /tasks/:id (NO existente) -> esperado 404"
echo "[DELETE /tasks/9999] -> $(code DELETE /tasks/9999)" >> "$OUT"
body DELETE /tasks/9999 >> "$OUT"; echo >> "$OUT"

echo "FIN DE PRUEBAS" >> "$OUT"
echo "Evidencia guardada en $OUT"
