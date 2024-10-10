# Example to use Swift OpenAPI Generator with OracleNIO and ADB in OCI

This example demonstrates how to use [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator) using [OracleNIO](https://github.com/lovetodream/oracle-nio) with Oracle Database 23ai as an Autonomous Database in Oracle Cloud Infrastructure (OCI).

Special thanks to:
- Babeth Velghe for her [Stop Worrying About Routes With OpenAPI Generator](https://www.youtube.com/watch?v=n1PRYVveLd0) presentation and
- [Joannis](https://github.com/Joannis) for his [Using OpenAPI Generator with Hummingbird](https://swiftonserver.com/using-openapi-with-hummingbird/) article.

## Preparation
### Step 1.
Download wallet for mTLS connection, and copy the `Connection string`.
![](https://github.com/kicsipixel/oracle-nio-examples/blob/main/json/ADB.png)

### Step 2.
Create a .env file and add the credentials:
```
DATABASE_HOST=adb.eu-frankfurt-1.oraclecloud.com
DATABASE_PORT=1522
DATABASE_SERVICE_NAME=gdb965aee735fa8_szabolcstothdb_low.adb.oraclecloud.com
DATABASE_USERNAME=ADMIN
DATABASE_PASSWORD=
# Wallet folder should be in /Sources/App/Resources foler unzipped
DATABASE_WALLET_PASSWORD=
```
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
Date: Thu, 10 Oct 2024 11:29:36 GMT
```

### 🌳 Parks
#### Creates a new park with a name and coordinates

- __URL:__ http://localhost:8080/api/v1/parks
- __HTTPMethod:__ `POST`

```
curl -X "POST" "http://localhost:8080/api/v1/parks" \
     -H 'Content-Type: application/json' \
     -d $'{
  "name": "Stromovka",
  "coordinates": {
    "longitude": 14.413999,
    "latitude": 50.105849
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
- `coordinates`:
    - `latitude`: langitude value
    - `latitude`: longitude value

```
[
  {
    "coordinates" : {
      "latitude" : 14.413999,
      "longitude" : 50.105849
    },
    "id" : "241E2367-2A4B-7FB2-E063-485D000A8B34",
    "name" : "Stromovka"
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
- `coordinates`:
    - `latitude`: langitude value
    - `latitude`: longitude value

```
{
  "coordinates" : {
    "latitude" : 14.413999,
    "longitude" : 50.105849
  },
  "id" : "241E2367-2A4B-7FB2-E063-485D000A8B34",
  "name" : "Stromovka"
}
```

#### Edits park with id
To keep the example simple, all values are mandantory. Otherwise, you can create a new model with optional values.

- __URL:__ http://localhost:8080/api/v1/parks/:id
- __HTTPMethod:__ `PUT`

```
curl -X "PUT" "http://localhost:8080/api/v1/parks/2408B278-1518-DB79-E063-485D000A4B80" \
     -H 'Content-Type: application/json' \
     -d $'{
  "name": "Stromovka",
  "coordinates": {
    "longitude": 14.413999,
    "latitude": 50.105849
  }
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