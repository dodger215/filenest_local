# FileNest — local file sharing

FileNest uses a Node.js backend that stores files on its local disk and metadata in SQLite. Flutter connects over HTTP or HTTPS. No sign-in, cloud account, or external database is required.

## Start the server

Install Node.js 24 or newer, then:

```sh
cd server
npm ci
npm start
```

The server listens on `0.0.0.0:3001`. Check `http://localhost:3001/health`.
The optional root `.env` configures:

```dotenv
PORT=3001
HOST=0.0.0.0
MAX_UPLOAD_BYTES=104857600
# DATA_DIR=/absolute/path/to/filenest-data
```

The default data directory is `server/data`. SQLite metadata lives in `filenest.sqlite`; file contents live under `uploads/<folder-id>/<category>/<file-id>`. Original filenames, captions, MIME types, categories, sizes, timestamps, and relative storage paths are recorded in SQLite. Uploaded files keep distinct IDs even when names match. Back up the entire data directory with the server stopped, including the database and uploads.

## Build and run Flutter

```sh
flutter pub get
flutter run --dart-define=BACKEND_URL=http://192.168.1.10:3001
flutter build apk --release --dart-define=BACKEND_URL=http://192.168.1.10:3001
```

Replace `192.168.1.10` with the server machine’s LAN IP. Include the port if it is not the HTTP/HTTPS default. Devices must be able to reach this machine and port. On a physical Android phone, `localhost` refers to the phone; use the server’s LAN address. The Android emulator can reach the host at `http://10.0.2.2:3001`. A desktop app on the server machine can use `http://localhost:3001`. Hosted servers can use a URL such as `https://files.example.com/api`.

If the Android build selects an incompatible Java version, use JDK 17 (for example, `flutter config --jdk-dir=/usr/lib/jvm/java-17-openjdk-amd64` on Linux).

`BACKEND_URL` is the only server build parameter. Without it, native builds default to `http://localhost:3001`; web builds use `/api` on the current origin. Android is configured to permit local HTTP connections.

Open **Settings → Backend server** to edit the URL, test connectivity, or restore the build default. Press **Save URL** to persist the choice in the device’s SQLite database. This override survives app restarts and takes precedence over the build parameter. Saving is allowed while a server is offline. Transfers must finish before switching. Each server has its own saved folder list and last-opened folder; appearance and notification preferences are device-wide.

Create a folder to get a six-character code. Other devices select the same server and join with that code. Files, text uploads, search, category/date filters, image previews, downloads, transfer retries, and foreground new-file notifications use the local backend. Share connection details from the folder menu.

There is intentionally no authentication or per-user permissions. Everyone who can reach the backend can use its file API. Folder codes identify folders; they are not access credentials. Email invitations are replaced by sharing the server URL and folder code.

## API

All routes are relative to the configured backend URL:

| Method | Route | Behavior |
| --- | --- | --- |
| GET | `/health` | SQLite health check |
| POST | `/folders` | Create a folder and unique code |
| GET | `/folders/code/:code` | Join by code |
| GET | `/folders/:folderId` | Read folder metadata |
| GET | `/folders/:folderId/files` | List active files |
| POST | `/folders/:folderId/files` | Upload multipart `file` |
| GET | `/files/:id` | Read metadata and storage path |
| GET | `/files/:id/content` | Download file contents |
| DELETE | `/folders/:folderId/files/:id` | Soft-delete a file |

Upload fields: required `file`; optional `name`, `caption`, `category`, and `uploadId`. Categories are `documents`, `images`, `videos`, `audio`, and `other`; omitted categories are inferred from MIME type and filename. `uploadId` is an optional stable 16–80 character alphanumeric, hyphen, or underscore identifier. Retrying the same ID and contents returns the existing record; conflicting reuse returns 409.

```sh
curl -X POST http://localhost:3001/folders
curl -F 'file=@report.pdf' -F 'caption=Monthly report' -F 'category=documents' \
  http://localhost:3001/folders/FOLDER_ID/files
```

The upload response includes `id`, `folderId`, `name`, `caption`, `mimeType`, `category`, `size`, `path`, `downloadPath`, and timestamps. `path` is relative to `DATA_DIR`, not a path on the Android device. Fetch `downloadPath` through the backend to retrieve the file. Soft-deleted files remain on disk but are excluded from listing and download routes.

## Docker

```sh
docker compose up --build -d
```

Web UI: `http://SERVER_IP:5000`. Native app backend: `http://SERVER_IP:3001`. The web container proxies `/api/` to the backend. A persistent `filenest-data` volume stores files and SQLite across container restarts. To set a separate web backend, supply `BACKEND_URL` when building. For HTTPS hosting, serve the API over HTTPS as well. If changing the maximum upload size, also adjust Nginx’s `client_max_body_size`.

## Validation

```sh
cd server
npm test
cd ..
flutter analyze
flutter test
flutter build web --release
```

Backend tests exercise real HTTP multipart transfers, retries, invalid requests, download contents, deletion, and persistence after reopening SQLite. Flutter tests cover URL normalization, API paths, error handling, multipart metadata, local schema migration, and saved-server isolation.

Existing device databases are upgraded in place. Previous remote folder records remain preserved but are not shown for local servers. Existing remote files are not automatically copied to the new server; upload them into a new local folder.
