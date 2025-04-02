# Unlocking the new features of Oracle Database 23ai with Swift on Server
## Build your next application using open source technologies on a rock solid foundation
![](pharmacies.png)
Source code to for [the article](https://medium.com/@kicsipixel/unlocking-the-new-features-of-oracle-database-23ai-with-swift-on-server-19cc5d078c05).

## Routes are as follows

- __GET__: / - Hello
- __GET__: /health - Checks server health status
- __POST__: /api/v1/pharmacies - Creates a new pharmacies
- __GET__: /api/v1/pharmacies- Lists all the pharmacies in the database
- __GET__: /api/v1/pharmacies/:id - Show a single phamracy with id

### 👋 Hello
Simple endpoint to check whether the server is alive, giving back `200 OK`

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
