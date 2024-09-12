# Location Analysis using Oracle database

Example shows one of the Spatial features of Oracle database. It lists resources(parks) questions based on the distance from your location.

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
Date: Wed, 11 Sep 2024 09:49:48 GMT
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
- `address`: street, city, zip of the park
- `latitude`: langitude value
- `latitude`: longitude value

```
[
  {

  }
]
```

#### Returns the list of  parks within the given distance

- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `GET`

```
curl "http://localhost:8080/api/v1/parks/distance?km=1"
```

__Return value:__
An array of
- `id`:  park UUID
- `name` : name of the park
- `address`: street, city, zip of the park
- `latitude`: langitude value
- `latitude`: longitude value

```
[
  {

  }
]
```