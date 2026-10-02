# Cozy notes playground

A small HTTP API stores notes in PostgreSQL.
Use Posting to send requests and Harlequin to inspect the same database.

Copy the template to a writable project directory inside the VM:

```console
mkdir cozy-notes
cp -R /etc/limanix/examples/cozy/. cozy-notes/
chmod -R u+w cozy-notes
cd cozy-notes
docker compose up -d --build --wait
```

The API listens at `http://127.0.0.1:8000` inside the VM.
PostgreSQL listens at `127.0.0.1:15432` with database, user and password `cozy`.
Both published ports bind to the VM's localhost.

Open the bundled HTTP requests:

```console
posting --collection ./posting
```

Send **Health** to check the database connection.
Send **Create note** to store a note, then **List notes** to see it.
`POST /notes` accepts a JSON object with one `text` string containing 1 to 500 characters after trimming whitespace.
`GET /notes` returns the notes in insertion order.

Open the project's PostgreSQL profile:

```console
harlequin
```

The included `.harlequin.toml` selects the same database automatically.
Try this query in the SQL editor:

```sql
SELECT id, text, created_at FROM notes ORDER BY id;
```

Edit `app.py` to change the API, then rebuild it:

```console
docker compose up -d --build --wait
```

Stop the containers while keeping the notes volume:

```console
docker compose down
```

To explicitly delete this playground's saved notes as well:

```console
docker compose down --volumes
```
