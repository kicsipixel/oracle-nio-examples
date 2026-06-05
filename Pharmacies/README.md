# Unlocking the new features of Oracle Database 23ai with Swift on Server
## Build your next application using open source technologies on a rock solid foundation
![](pharmacies.png)
Source code for [the article](https://medium.com/@kicsipixel/unlocking-the-new-features-of-oracle-database-23ai-with-swift-on-server-19cc5d078c05).

## Routes are as follows

- __GET__: / - Hello
- __GET__: /health - Checks server health status
- __POST__: /api/v1/pharmacies - Creates a new pharmacy
- __GET__: /api/v1/pharmacies - Lists all the pharmacies in the database
- __GET__: /api/v1/pharmacies/:id - Shows a single pharmacy with id
- __PUT__: /api/v1/pharmacies/:id - Updates a pharmacy with id
- __DELETE__: /api/v1/pharmacies/:id - Deletes a pharmacy with id

### 👋 Hello
Simple endpoint to say "Hello!", giving back `Hello!`

- __URL:__ http://localhost:8080/
- __HTTPMethod:__ `GET`

```shell
curl -i http://localhost:8080/
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Content-Length: 6
Date: Sun, 30 Mar 2025 12:54:36 GMT
Server: pharmacies

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
Server: pharmacies
```

### 🗺️ Spatial API

#### Creates a new pharmacy
- __URL:__ http://localhost:8080/api/v1/pharmacies
- __HTTPMethod:__ `POST`

#### Lists all pharmacies (supports proximity filtering)

- __URL:__ http://localhost:8080/api/v1/pharmacies
- __HTTPMethod:__ `GET`

Use the optional query parameters to filter by distance:
- `latlong`: latitude and longitude separated by comma, e.g. `50.14,14.57`
- `distance`: numeric distance value
- `unit`: `km` or `mile`

```shell
curl "http://localhost:8080/api/v1/pharmacies?latlong=50.08,14.41&distance=1&unit=km"
```

#### Shows a single pharmacy with id
- __URL:__ http://localhost:8080/api/v1/pharmacies/:id
- __HTTPMethod:__ `GET`

#### Updates a pharmacy with id
- __URL:__ http://localhost:8080/api/v1/pharmacies/:id
- __HTTPMethod:__ `PUT`

#### Deletes a pharmacy with id
- __URL:__ http://localhost:8080/api/v1/pharmacies/:id
- __HTTPMethod:__ `DELETE`
