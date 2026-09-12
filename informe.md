# Informe de persistencia — TP3: TODO API con PostgreSQL y Docker

**Alumno:** Valentín Romero
**Asignatura:** Programación Avanzada — 2026
**Práctica:** 02 — TODO API con persistencia en PostgreSQL usando Docker

## 1. Entorno utilizado
- Node.js 20 (imagen `node:20-alpine` en el contenedor `api`)
- PostgreSQL 16 (imagen `postgres:16-alpine` en el contenedor `db`)
- Docker + Docker Compose orquestando ambos servicios
- Driver `node-postgres` (`pg`) con consultas parametrizadas (`$1`, `$2`, ...)

## 2. Arquitectura
La solución se compone de dos contenedores unidos por una red interna de Compose:
`api` (Node + Express, publica en `localhost:3001`) y `db` (PostgreSQL 16, puerto
`5432`). La API se conecta a la base usando el **nombre del servicio** (`db`) como
host, nunca `localhost`, porque dentro de la red de Compose `localhost` apunta al
propio contenedor. Los datos de Postgres se guardan en un **volumen Docker nombrado**
(`todo_pgdata`) que persiste en el host.

## 3. Resultado de la prueba de persistencia (Sección 10.4)
1. Se creó una tarea de prueba con `POST /tasks` → se obtuvo `id = 5`.
2. Se reinició **solo** el contenedor de la API con `docker compose restart api`.
   Al consultar `GET /tasks/5` se obtuvo **200 OK**: la tarea seguía existiendo.
3. Se ejecutó `docker compose down -v` (elimina contenedores **y** el volumen de
   datos) y luego `docker compose up --build -d` para levantar todo de nuevo.
4. Al consultar `GET /tasks/5` tras reconstruir el entorno se obtuvo **404 Not Found**:
   la tarea ya no existía.

## 4. ¿Por qué ocurre esto?
El volumen `todo_pgdata` es el único sitio donde PostgreSQL guarda físicamente los
datos (`/var/lib/postgresql/data`). Mientras el volumen existe, los datos sobreviven a
cualquier reinicio de contenedores, incluido `docker compose restart api`. El comando
`docker compose down -v` elimina explícitamente ese volumen; al volver a levantar el
proyecto, Postgres parte de cero y vuelve a correr `init.sql` (que solo inserta las dos
tareas de ejemplo), por lo que las tareas creadas por el usuario desaparecen.

## 5. Cumplimiento de la Definition of Done
- `docker compose up --build` levanta ambos servicios sin errores en una máquina limpia.
- Los cinco endpoints responden con los códigos correctos, incluyendo los casos 404.
- Todas las consultas SQL usan parámetros (`$1`, `$2`, ...) — sin concatenación de strings.
- Los datos persisten frente a `docker compose restart api` y se pierden solo con
  `docker compose down -v`.
- El campo `updated_at` se actualiza en cada `PUT` (mediante `NOW()` en la sentencia `UPDATE`,
  usando `COALESCE` para no pisar los campos que no vienen en el body).
