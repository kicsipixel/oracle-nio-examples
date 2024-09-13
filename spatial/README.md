# Location Analysis using Oracle database - API

Example shows one of the Spatial features of Oracle database. It lists resources(parks) based on the distance from your location.

## Preparation
To make it easier, you can seed the database with some data from a `.json` file. 
Simply run the application for the first time only with:
```
swift run App --seed
```

The database uses [`SDO_GEOMTERY`](https://docs.oracle.com/en/database/oracle/oracle-database/23/spatl/sdo_geometry-object-type.html) object type to to store coordinates. 

## Routes are as follows

- __GET__: /health - Checks server health status
- __POST__: /api/v1/parks - Creates a new park
- __GET__: /api/v1/parks- Lists all the parks in the database
- __GET__: /api/v1/parks/:id - Show a single park with id
- __POST__: /api/v1/parks/filter - Returns the list of parks which are within the distance

### 🩺 Health
Simple endpoint to check whether the server is alive, giving back `200 OK`

- __URL:__ http://localhost:8080/health
- __HTTPMethod:__ `GET`

```
curl -i http://localhost:8080/health
HTTP/1.1 200 OK
Content-Length: 0
Date: Thu, 12 Sep 2024 12:22:32 GMT
Server: spatial
```

### 🗺️ Spatial API
#### Creates a new park with a name and coordinates

- __URL:__ http://localhost:8080/api/v1/parks
- __HTTPMethod:__ `POST`

```
curl -X "POST" "http://localhost:8080/api/v1/parks" \
     -H 'Content-Type: application/json' \
     -d $'{
  "name": "Letenské sady",
  "address": "Letenské sady 1574, 17000 Praha, Česko",
  "coordinates": {
    "latitude": 50.0959721
    "longitude": 14.4202892
  }
}'
```

__Return value:__
- `201 CREATED`
#### Lists all the parks in the database

- __URL:__ http://localhost:8080/api/v1/parks
- __HTTPMethod:__ `GET`

```
curl "http://localhost:8080/api/v1/parks"
```

__Return value:__
An array of
- `id`:  park UUID
- `name` : name of the park
- `address`: street, city, zip, country of the park
- `coordinates` 
    - `latitude`: langitude value
    - `latitude`: longitude value
```

[
  {
    "address": "Koňská stezka, 17000 Praha, Česko",
    "name": "Stromovka",
    "id": "59DAAB3F-862B-4C02-9CA6-B003B298F35A",
    "coordinates": {
      "latitude": 50.105849,
      "longitude": 14.413999
    }
  },
  {
    "coordinates": {
      "latitude": 50.0959721,
      "longitude": 14.4202892
    },
    "name": "Letenské sady",
    "id": "CC9B4FCE-3630-4AAE-9CC6-C8DEBD0CED82",
    "address": "Letenské sady 1574, 17000 Praha, Česko"
  },
  {
    "address": "Riegrovy sady 28, 12000 Praha, Česko",
    "id": "E74DC91A-4B55-40FD-86DE-C7C1A96C1CDB",
    "name": "Riegrovy sady",
    "coordinates": {
      "latitude": 50.080292,
      "longitude": 14.441514
    }
  }
]
```

#### Returns a single park with id

- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `GET`

```
curl "http://localhost:8080/api/v1/parks/2179C563-F93E-2F37-E063-020011AC0285"
```

__Return value:__
- `id`:  park UUID
- `name` : name of the park
- `address`: street, city, zip, country of the park
- `coordinates` 
    - `latitude`: langitude value
    - `latitude`: longitude value

```
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

#### Returns the list of  parks within the given distance

- __URL:__ http://localhost:8080/api/v1/parks/filter
- __HTTPMethod:__ `POST`

```
curl -X "POST" "http://localhost:8080/api/v1/parks/filter" \
     -H 'Content-Type: application/json' \
     -d $'{
            "userPosition": {
              "longitude": 14.411944,
              "latitude": 50.086389
            },
            "distance": 0.27,
            "unit": "mile"
      }'
```

__Return value:__
An array of
- `id`:  park UUID
- `name` : name of the park
- `address`: street, city, zip, country of the park
- `coordinates` 
    - `latitude`: langitude value
    - `latitude`: longitude value
```
[
  {
    "id": "59DAAB3F-862B-4C02-9CA6-B003B298F35A",
    "longitude": 14.413999,
    "latitude": 50.105849,
    "name": "Stromovka",
    "address": "Koňská stezka, 17000 Praha, Česko"
  },
  {
    "name": "Letenské sady",
    "longitude": 14.4202892,
    "id": "CC9B4FCE-3630-4AAE-9CC6-C8DEBD0CED82",
    "address": "Letenské sady 1574, 17000 Praha, Česko",
    "latitude": 50.0959721
  }
]
```
