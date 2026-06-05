# Location Analysis using Oracle database - Web app

Example shows one of the Spatial features of Oracle database. It lists resources (parks) based on the distance from your location.

__Note:__
Apple has updated the requirements for using MapKit JS, which may affect map rendering.

<div style="display: flex; justify-content: space-between;">
  <img src="spatial-web-1.png" alt="Spatial Web 1" style="width: 48%;">
  <img src="spatial-web-2.png" alt="Spatial Web 2" style="width: 48%;">
</div>

To make it easier, you can seed the database with some data from a `.json` file. 
Simply run the application for the first time only with:
```shell
swift run App --seed
```
The database uses [`SDO_GEOMETRY`](https://docs.oracle.com/en/database/oracle/oracle-database/23/spatl/sdo_geometry-object-type.html) object type to store coordinates. 

## Routes are as follows

- __GET__: /health - Checks server health status
- __GET__: / - Renders the map with all parks listed
- __POST__: / - Filters parks by distance from a selected location and re-renders the map


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

The index page renders an interactive map (powered by [MapKit JS](https://developer.apple.com/maps/web/)) showing all parks. Submitting the form with a location and distance filters the list using Oracle's `SDO_WITHIN_DISTANCE` spatial query and re-renders the map.
