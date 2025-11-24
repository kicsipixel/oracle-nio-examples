# Basic CRUD operations and JWT Authentication using Oracle database

Example of app using [OracleNIO](https://github.com/lovetodream/oracle-nio/tree/main) to connect to Oracle database. It creates a table, then user can add read entires without credentials but for creating new, update and delete user must send her/his token as authentication.

## Routes are as follows

- __GET__: /health - Checks server health status
- __POST__: /api/v1/parks - Creates a new park
- __GET__: /api/v1/parks- Lists all the parks in the database
- __GET__: /api/v1/parks/:id - Returns a single park with id
- __PATCH__: /api/v1/parks/:id - Edits park with id
- __DELETE__: /api/v1/parks/:id - Deletes park with id
- __POST__: /api/v1/users: - Register user
- __POST__: /api/v1/users/login: - Login user


### 🩺 Health
Simple endpoint to check whether the server is alive, giving back `200 OK`

- __URL:__ http://localhost:8080/health
- __HTTPMethod:__ `GET`

```
$ curl -i http://localhost:8080/health

HTTP/1.1 200 OK
Content-Length: 0
Date: Fri, 28 Mar 2025 20:38:53 GMT
Server: simple_crud
```

### 👋 Hello
Simple endpoint to say "Hello!", giving back `Hello!`

- __URL:__ http://localhost:8080
- __HTTPMethod:__ `GET`

```
$ curl -i http://localhost:8080

HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Content-Length: 6
Date: Fri, 28 Mar 2025 20:38:16 GMT
Server: simple_crud

Hello!
```

### 🌳 Parks
---
#### Creates a new park with a name and coordinates
---

- __URL:__ http://localhost:8080/api/v1/parks
- __HTTPMethod:__ `POST`

```
$ curl -X "POST" "http://localhost:8080/api/v1/parks" \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJraWQiOiJhdXRoLWp3dCIsImFsZyI6IkhTMjU2In0.eyJuYW1lIjoiVGVzdCBVc2VyIDEiLCJzdWIiOiI0NDVBOTA1OS04QjYwLTJEQTAtRTA2My0wMjZCQThDMEMwQzgiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJleHAiOjE3NjQwNDQ1NTEuOTk4NDMzfQ.FX0jH3Pi61yQxXYhVp9YeoXR_4rPt8pbstZx-EO1wuQ' \
     -d $'{
  "details": {
    "name": "Letenské sady"
  },
  "coordinates": {
    "longitude": 4.4202892,
    "latitude": 50.0959721
  }
}'

```

__Return value:__
- `201 Created`

---
#### Lists all the parks in the database
---

- __URL:__ http://localhost:8080/api/v1/parks
- __HTTPMethod:__ `GET`

```
$ curl "http://localhost:8080/api/v1/parks"
```

__Return value:__
An array of
- `id`:  park UUID
- `details` : details of the park
- `latitude`: langitude value
- `latitude`: longitude value
- `userId` : id of the owner

```
[
   {
      "details":{
         "name":"Letenské sady"
      },
      "id":"316C03A7-95F1-89E7-E063-02D7A8C070D3",
      "userId":"445A9059-8B60-2DA0-E063-026BA8C0C0C8",
      "coordinates":{
         "latitude":50.09597,
         "longitude":4.4202886
      }
   }
]
```
---
#### Returns a single park with id
---

- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `GET`

```
$ curl "http://localhost:8080/api/v1/parks/2179C563-F93E-2F37-E063-020011AC0285"
```

__Return value:__
- `id`:  park UUID
- `details` : details of the park
- `latitude`: langitude value
- `latitude`: longitude value
- `userId` : id of the owner

```
[
   {
      "details":{
         "name":"Letenské sady"
      },
      "id":"316C03A7-95F1-89E7-E063-02D7A8C070D3",
      "userId":"445A9059-8B60-2DA0-E063-026BA8C0C0C8",
      "coordinates":{
         "latitude":50.09597,
         "longitude":4.4202886
      }
   }
]
```
---
#### Edits park with id
---
To keep the example simple, all values are mandantory. Otherwise, you can create a new model with optional values.

- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `PATCH`

```
$ curl -X "PATCH" "http://localhost:8080/api/v1/parks/445AA4AF-32EB-2FAA-E063-026BA8C07AB0" \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJraWQiOiJhdXRoLWp3dCIsImFsZyI6IkhTMjU2In0.eyJuYW1lIjoiVGVzdCBVc2VyIDEiLCJzdWIiOiI0NDVBOTA1OS04QjYwLTJEQTAtRTA2My0wMjZCQThDMEMwQzgiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJleHAiOjE3NjQwNDQ1NTEuOTk4NDMzfQ.FX0jH3Pi61yQxXYhVp9YeoXR_4rPt8pbstZx-EO1wuQ' \
     -d $'{
  "details": {
    "name": "Žernosecká - Čumpelíkova"
  },
  "coordinates": {
    "longitude": 4.4202892,
    "latitude": 50.0959721
  }
}'
```

__Return value:__
- `200 OK`

---
#### Deletes park with id
---

- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `DELETE`

```
$ curl -X "DELETE" "http://localhost:8080/api/v1/parks/445AA4AF-32EB-2FAA-E063-026BA8C07AB0" \
     -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJraWQiOiJhdXRoLWp3dCIsImFsZyI6IkhTMjU2In0.eyJuYW1lIjoiVGVzdCBVc2VyIDEiLCJzdWIiOiI0NDVBOTA1OS04QjYwLTJEQTAtRTA2My0wMjZCQThDMEMwQzgiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJleHAiOjE3NjQwNDQ1NTEuOTk4NDMzfQ.FX0jH3Pi61yQxXYhVp9YeoXR_4rPt8pbstZx-EO1wuQ'
```

__Return value:__
- `204 No Content`

---
#### Register user
---

- __URL:__ http://localhost:8080/api/v1/users
- __HTTPMethod:__ `POST`

```
$ curl -X "POST" "http://localhost:8080/api/v1/users" \
     -H 'Content-Type: application/json' \
     -d $'{
  "name": "Test User 1",
  "email": "test@test.com",
  "password": "123456"
}'
```

__Return value:__
- `201 Created`

---
#### Login user
---

- __URL:__ http://localhost:8080/api/v1/users/login
- __HTTPMethod:__ `POST`

```
$ curl -X "POST" "http://localhost:8080/api/v1/users/login" \
     -u 'test@test.com:123456'
```

__Return value:__
- `token`: JW token

```
{
  "token": "eyJ0eXAiOiJKV1QiLCJraWQiOiJhdXRoLWp3dCIsImFsZyI6IkhTMjU2In0.eyJuYW1lIjoiVGVzdCBVc2VyIDEiLCJzdWIiOiI0NDVBOTA1OS04QjYwLTJEQTAtRTA2My0wMjZCQThDMEMwQzgiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJleHAiOjE3NjQwNDQ1NTEuOTk4NDMzfQ.FX0jH3Pi61yQxXYhVp9YeoXR_4rPt8pbstZx-EO1wuQ"
}
 ```

---
