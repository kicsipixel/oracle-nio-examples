# Basic CRUD operations using Oracle database

Example of app using [OracleNIO](https://github.com/lovetodream/oracle-nio/tree/main) to connect to Oracle database. It creates a table, then user can add new entries, read, update or delete them as well.

## Routes are as follows

- __GET__: /health - Checks server health status
- __POST__: /api/v1/parks - Creates a new park
- __GET__: /api/v1/parks- Lists all the parks in the database
- __GET__: /api/v1/parks/:id - Returns a single park with id
- __PATCH__: /api/v1/parks/:id - Edits park with id
- __DELETE__: /api/v1/parks/:id - Deletes park with id

### 🩺 Health
Simple endpoint to check whether the server is alive, giving back `200 OK`

- __URL:__ http://localhost:8080/health
- __HTTPMethod:__ `GET`

```
curl -i http://localhost:8080/health
HTTP/1.1 200 OK
Content-Length: 0
Date: Fri, 6 Sep 2024 19:49:48 GMT
Server: simple-crud
```

### 🌳 Parks
#### Creates a new park with a name and coordinates

- __URL:__ http://localhost:8080/api/v1/parks
- __HTTPMethod:__ `POST`

```
curl -X "POST" "http://localhost:8080/api/v1/parks" \
     -H 'Content-Type: application/json' \
     -d $'{
  "name": "Letenské sady",
  "latitude": 50.0959721
  "longitude": 14.4202892
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
- `latitude`: langitude value
- `latitude`: longitude value

```
[
  {
    "id": "2179C563-F93E-2F37-E063-020011AC0285",
    "name": "Letenské sady",
    "latitude": 50.09597,
    "longitude": 14.4202886
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
- `latitude`: langitude value
- `latitude`: longitude value

```
{
   "id": "2179C563-F93E-2F37-E063-020011AC0285",
   "name": "Letenské sady",
   "latitude": 50.09597,
   "longitude": 14.4202886
}
```

#### Edits park with id
To keep the example simple, all values are mandantory. Otherwise, you can create a new model with optional values.

- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `PATCH`

```
curl -X "PATCH" "http://localhost:8080/api/v1/parks/2179C563-F93E-2F37-E063-020011AC0285" \
     -H 'Content-Type: application/json' \
     -d $'{
  "name": "Žernosecká - Čumpelíkova",
  "longitude": 14.46098423,
  "latitude": 50.132259369
}'
```

__Return value:__
- `200 OK`

#### Deletes park with id

- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `DELETE`

```
curl -X "DELETE" "http://localhost:8080/api/v1/parks/2179C563-F93E-2F37-E063-020011AC0285"
```

__Return value:__
- `200 OK`