# Basic CRUD operations and Bearer Authentication using Oracle database
## Reset password

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
- __DELETE__: /api/v1/users/logout: - Logout user
- __POST__: /api/v1/users/forgot-password: - Forgot password


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
     -H 'Authorization: Bearer Wzc5MCwgMzgyLCA4MzAsIDczNSwgMSwgNDc3LCA4MzIsIDY4Nl0=' \
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
- `name` : name of the park
- `latitude`: langitude value
- `latitude`: longitude value

```
[
   {
      "details":{
         "name":"Letenské sady"
      },
      "id":"316C03A7-95F1-89E7-E063-02D7A8C070D3",
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
- `name` : name of the park
- `latitude`: langitude value
- `latitude`: longitude value

```
   {
      "details":{
         "name":"Letenské sady"
      },
      "id":"316C03A7-95F1-89E7-E063-02D7A8C070D3",
      "coordinates":{
         "latitude":50.09597,
         "longitude":4.4202886
      }
   }
```
---
#### Edits park with id
---
To keep the example simple, all values are mandantory. Otherwise, you can create a new model with optional values.

- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `PATCH`

```
$ curl -X "PATCH" "http://localhost:8080/api/v1/parks/3659F869-E235-06DE-E063-0261A8C0817B" \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer Wzc5MCwgMzgyLCA4MzAsIDczNSwgMSwgNDc3LCA4MzIsIDY4Nl0=' \
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
$ curl -X "DELETE" "http://localhost:8080/api/v1/parks/3659F869-E235-06DE-E063-0261A8C0817B" \
     -H 'Authorization: Bearer Wzc5MCwgMzgyLCA4MzAsIDczNSwgMSwgNDc3LCA4MzIsIDY4Nl0='
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
  "email": "first@test.com",
  "nickname": "FirstOne",
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
     -u 'first@test.com:123456'
```

__Return value:__
- `userId`:  user UUID
- `tokenValue`: Bearer token

```
{
  "userId": "366109AD-33D3-3A31-E063-026BA8C04EB0",
  "tokenValue": "WzI3OCwgNTYzLCA0MzgsIDg0NiwgNDAzLCA3OTgsIDY4NiwgNzk0XQ=="
}
 ```

---
#### Logout user
---

- __URL:__ http://localhost:8080/api/v1/users/logout
- __HTTPMethod:__ `DELETE`

```
$ curl -X "DELETE" "http://localhost:8080/api/v1/users/logout" \
     -H 'Authorization: Bearer Wzc5MCwgMzgyLCA4MzAsIDczNSwgMSwgNDc3LCA4MzIsIDY4Nl0='
```

__Return value:__
- `204 No Content`

#### Forgot password
---

- __URL:__ http://localhost:8080/api/v1/users/forgot-password
- __HTTPMethod:__ `POST`

```
$ curl -X "POST" "http://localhost:8080/api/v1/users/forgot-password" \
     -H 'Content-Type: application/json' \
     -d $'{
  "email": "one@example.com"
}'
```

__Return value:__
- `200 Ok`