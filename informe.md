# Informe de persistencia — TP3 (Práctica 02): TODO API con PostgreSQL y Docker

**Alumno:** Valentín Romero · **Materia:** Programación Avanzada 2026

## Qué pasó en la prueba de la Sección 10.4

1. `POST /tasks` creó una tarea de prueba y devolvió **`id = 5`** (`201`).
2. `docker compose restart api` (reinicio **solo** del contenedor de la API):
   `GET /tasks/5` devolvió **200 OK** → **la tarea siguió existiendo**.
3. `docker compose down -v` + `docker compose up --build -d` (entorno reconstruido
   desde cero): `GET /tasks/5` devolvió **404 Not Found** → **los datos se perdieron**.

## Por qué

El único lugar donde PostgreSQL guarda físicamente los datos es el **volumen nombrado
`todo_pgdata`**, montado en `/var/lib/postgresql/data` del contenedor `db`. Un volumen
vive en el host, no dentro de la imagen, por eso sobrevive a cualquier reinicio de
contenedores: al hacer `restart api` cambia el proceso Node (con su conexión y su pool de
`pg` recién creados), pero la base nunca se toca y la consulta vuelve a encontrar la fila.

`down -v` es distinto: elimina explícitamente ese volumen, así que la base queda vacía.
Al reconstruir, Postgres arranca desde cero y `init.sql` se ejecuta otra vez (inserta solo
las dos tareas de ejemplo), por lo que la tarea creada por el usuario ya no está.

Contraste con la Práctica 01: ahí los datos eran un array en memoria del proceso Node, así
que **cualquier** restart los perdía. Ahora el ciclo de vida de los datos quedó desacoplado
del ciclo de vida de la API: solo se pierden si se borra el volumen.

*Trazas completas: `entrega/persistencia.txt`; scripts para reproducirlas: `scripts/`.*
