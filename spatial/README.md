# Location Analysis using Oracle database - API

Example shows one of the Spatial features of Oracle database. It lists resources(parks) based on the distance from your location.

## Preparation
Create a `.env` file:
```bash
# Local Database configuration
DATABASE_HOST=127.0.0.1
DATABASE_SERVICE_NAME=freepdb1
DATABASE_USERNAME=park_user
DATABASE_PASSWORD=s3cr3tPassw0rd
# Remote Database configuration
# (description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.eu-frankfurt-1.oraclecloud.com))(connect_data=(service_name=gdb965aee735fa8_szabolcstothdb_low.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))
REMOTE_DATABASE_HOST=adb.eu-frankfurt-1.oraclecloud.com
REMOTE_DATABASE_PORT=1522
REMOTE_DATABASE_SERVICE_NAME=gdb965aee735fa8_szabolcstothdb_low.adb.oraclecloud.com
REMOTE_DATABASE_USERNAME=ADMIN
REMOTE_DATABASE_PASSWORD=TopS3cr3TT
# Wallet folder should be in /Sources/App/Credentials unzipped
REMOTE_DATABASE_WALLET_PASSWORD=ForgotIt2x
```
To make it easier, you can seed the database with some data from a `.json` file. 
Simply run the application for the first time only with:
```shell
swift run App --seed
```

The database uses [`SDO_GEOMTERY`](https://docs.oracle.com/en/database/oracle/oracle-database/23/spatl/sdo_geometry-object-type.html) object type to to store coordinates. 

## Routes are as follows

- __GET__: / - Hello
- __GET__: /health - Checks server health status
- __POST__: /api/v1/parks - Creates a new park
- __GET__: /api/v1/parks- Lists all the parks in the database
- __GET__: /api/v1/parks/:id - Show a single park with id
- __POST__: /api/v1/parks/filter - Returns the list of parks which are within the distance

### 👋 Hello
Simple endpoint to check whether the server is alive, giving back `200 OK`

- __URL:__ http://localhost:8080/
- __HTTPMethod:__ `GET`

```shell
curl -i http://localhost:8080/
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Content-Length: 6
Date: Sun, 30 Mar 2025 12:54:36 GMT
Server: spatial

Hello!
```

### 🩺 Health
Simple endpoint to check whether the server is alive, giving back `200 OK`

- __URL:__ http://localhost:8080/health
- __HTTPMethod:__ `GET`

```shell
curl -i http://localhost:8080/health
HTTP/1.1 200 OK
Content-Length: 0
Date: Thu, 12 Sep 2024 12:22:32 GMT
Server: spatial
```

### 🗺️ Spatial API
---
#### Creates a new park with a name and coordinates
---
- __URL:__ http://localhost:8080/api/v1/parks
- __HTTPMethod:__ `POST`

```shell
# Creates a new park with a name and coordinates
$ curl -X "POST" "http://localhost:8080/api/v1/parks" \
     -H 'Content-Type: application/json' \
     -d $'{
  "details": {
    "address": "Koňská stezka, 17000 Praha, Česko",
    "name": "Stromovka"
  },
  "coordinates": {
    "longitude": 14.413999,
    "latitude": 50.105846
  }
}'
```

__Return value:__
- `201 CREATED`
---
#### Lists all the parks in the database
---
- __URL:__ http://localhost:8080/api/v1/parks
- __HTTPMethod:__ `GET`

```shell
curl "http://localhost:8080/api/v1/parks"
```

__Return value:__
An array of
- `id`:  park UUID
- `coordinates` 
    - `latitude`: langitude value
    - `latitude`: longitude value
- `details`
    - `name` : name of the park
    - `address`: street, city, zip, country of the park
```shell
[
  {
    "id": "5CCDD206-9ED7-4ADC-9BB5-01BFD72FD359",
    "coordinates": {
      "latitude": 50.088898,
      "longitude": 14.408997
    },
    "details": {
      "address": "U Lužického semináře 110/40, 11000 Praha, Česko",
      "name": "Vojanovy sady"
    }
  },
  {
    "id": "3714D30C-E1B1-4019-9FFE-0F226749A8F4",
    "details": {
      "name": "Kampa",
      "address": "U Sovových mlýnů 501/7, 11000 Praha, Česko"
    },
    "coordinates": {
      "latitude": 50.085438,
      "longitude": 14.408009
    }
  }
]
```
---
#### Returns a single park with id
---
- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `GET`

```shell
curl "http://localhost:8080/api/v1/parks/2179C563-F93E-2F37-E063-020011AC0285"
```

__Return value:__
- `id`:  park UUID
- `coordinates` 
    - `latitude`: langitude value
    - `latitude`: longitude value
- `details`
    - `name` : name of the park
    - `address`: street, city, zip, country of the park

```shell
{
  "id": "59DAAB3F-862B-4C02-9CA6-B003B298F35A",
  "address": "Koňská stezka, 17000 Praha, Česko",
  "coordinates": {
    "latitude": 50.105849,
    "longitude": 14.413999
  },
  "name": "Stromovka"
}
```
---
#### Returns the list of  parks within the given distance
---
- __URL:__ http://localhost:8080/api/v1/parks?latlong=50.08,14.41&distance=1&unit=km"
- __HTTPMethod:__ `GET`

```
curl "http://localhost:8080/api/v1/parks?latlong=50.08,14.41&distance=1&unit=km"
```

__Return value:__
An array of
- `id`:  park UUID
- `coordinates` 
    - `latitude`: langitude value
    - `latitude`: longitude value
- `details`
    - `name` : name of the park
    - `address`: street, city, zip, country of the park
```shell
[
  {
    "id": "5CCDD206-9ED7-4ADC-9BB5-01BFD72FD359",
    "coordinates": {
      "latitude": 50.088898,
      "longitude": 14.408997
    },
    "details": {
      "address": "U Lužického semináře 110/40, 11000 Praha, Česko",
      "name": "Vojanovy sady"
    }
  },
  {
    "id": "3714D30C-E1B1-4019-9FFE-0F226749A8F4",
    "details": {
      "name": "Kampa",
      "address": "U Sovových mlýnů 501/7, 11000 Praha, Česko"
    },
    "coordinates": {
      "latitude": 50.085438,
      "longitude": 14.408009
    }
  }
]
```
