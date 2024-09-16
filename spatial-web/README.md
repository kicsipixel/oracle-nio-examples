# Location Analysis using Oracle database - Web app

Example shows one of the Spatial features of Oracle database. It lists resources(parks) based on the distance from your location.

<div style="display: flex; justify-content: space-between;">
  <img src="spatial-web-1.png" alt="Spatial Web 1" style="width: 48%;">
  <img src="spatial-web-2.png" alt="Spatial Web 2" style="width: 48%;">
</div>

## Preparation
To make it easier, you can seed the database with some data from a `.json` file. 
For database credentials, make a`.env` file:
```
DATABASE_HOST=127.0.0.1
DATABASE_PORT=1522
SID=
DATABASE_USERNAME=
DATABASE_PASSWORD=
```
Simply run the application for the first time only with:
```
swift run App --seed
```

The database uses [`SDO_GEOMTERY`](https://docs.oracle.com/en/database/oracle/oracle-database/23/spatl/sdo_geometry-object-type.html) object type to to store coordinates. 

## Route is the following

- __GET__: /health - Checks server health status


### 🩺 Health
Simple endpoint to check whether the server is alive, giving back `200 OK`

- __URL:__ http://localhost:8080/health
- __HTTPMethod:__ `GET`

```
curl -i http://localhost:8080/health
HTTP/1.1 200 OK
Content-Length: 0
Date: Thu, 12 Sep 2024 12:22:32 GMT
Server: spatial-web
```

### 🗺️ Spatial Web

- __URL:__ http://localhost:8080/

