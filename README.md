# zertifikatze-sidecar-container

This is a simple container image for downloading certificates from Zertifikatze.

## Environment Variables

| Variable              | Description                                     | Default         |
| --------------------- | ----------------------------------------------- | --------------- |
| `API_URL`             | Zertifikatze API *Required*                     | None            |
| `CERT_NAME`           | Certificate name *Required*                     | None            |
| `CERT_API_KEY`        | Certificate API Key *Required*                  | None            |
| `CERT_TYPE`           | `pem` and `pfx` are supported                   | `pem`           |
| `CERT_DIRECTORY`      | Certificate storage location                    | `/certs`        |
| `LOAD_SCHEDULE`       | Cron Schedule for certificate loading           | `0 3 * * *`     | 
| `POST_UPDATE_CMD`     | Run this after the certificate was updated      | None            |

## Usage

After a successfull run this script will place the downloaded certificate into the `CERT_DIRECTORY`, which should
be a mounted to a docker volume.

Dpeending on the `CERT_TYPE` some files will be placed into this directory:
- `cert.pfx` (`CERT_TYPE` == `pfx`)
- `cert.json`, `cert.pem`, `fullchain.pem` and `key.pem` (`CERT_TYPE` == `pem`)
- `current-version`
