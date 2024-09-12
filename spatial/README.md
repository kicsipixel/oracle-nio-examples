# Location Analysis using Oracle database

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
- __GET__: /api/v1/parks- Lists all the parks in the database
- __GET__: /api/v1/parks/distance?mile=1 - Returns the list of parks which are within the distance

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

### 🗺️ Spatial
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
  },
  {
    "latitude": 50.080292,
    "longitude": 14.441514,
    "name": "Riegrovy sady",
    "address": "Riegrovy sady 28, 12000 Praha, Česko",
    "id": "E74DC91A-4B55-40FD-86DE-C7C1A96C1CDB"
  }
]
```

#### Returns the list of  parks within the given distance

- __URL:__ http://localhost:8080/api/v1/parks/distance?km=1
- __HTTPMethod:__ `GET`

```
curl "http://localhost:8080/api/v1/parks/distance?km=1"
```

__Return value:__
An array of
- `id`:  park UUID
- `name` : name of the park
- `address`: street, city, zip, country of the park
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

#### TODO
- [ ] Visual representation - in prgrogress with MapKit JS
- [ ] Enable to users to give their location instead of fixed one 
