# Example to use JSON natively with JSON data type

This example demonstrates how to natively write, read, and query JSON data using Oracle Database 23ai.

The sample data (included in the repo) :
```json
{
  "results": [
    {
      "name": {
        "title": "Ms",
        "first": "Lilian",
        "last": "Kindler"
      },
      "email": "lilian.kindler@example.com",
      "nat": "DE",
      "hobbies": ["karate", "running", "movies"]
    },
    {
      "name": {
        "title": "Mr",
        "first": "Thoralf",
        "last": "Strecker"
      },
      "email": "thoralf.strecker@example.com",
      "nat": "DE",
      "hobbies": ["reading"]
    },
    ...
  ]
}
```
## Preparation

To make it easier, you can seed the database with some data from a `.json` file. 
Simply run the application for the first time only with:
```
swift run App --seed
```

Oracle Database [supports JSON natively](https://docs.oracle.com/en/database/oracle/oracle-database/21/adjsn/json-in-oracle-database.html#GUID-A8A58B49-13A5-4F42-8EA0-508951DAE0BB) with relational database features, including transactions, indexing, declarative querying, and views. Unlike relational data, JSON data can be stored in the database, indexed, and queried without any need for a schema that defines the data.

Data stored in database:
![](json.png)

## Routes are as follows

- __GET__: / - Return with simple "Hello!"
- __GET__: /health - Checks server health status
- __GET__: /api/v1/people - Lists all the people in the database
- __GET__: /api/v1/people/:id - Shows a single person with id
- __POST__: /api/v1/people/- Creates new person in the database
- __PUT__: /api/v1/people/:id - Edits the person in the database with given id
- __POST__: /api/v1/people/:id - Deletes the person from database with given id

### 👋 Hello
Simple endpoint returns with "Hello!".

- __URL:__ http://localhost:8080
- __HTTPMethod:__ `GET`

```
$ curl -i http://localhost:8080
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Content-Length: 6
Date: Sat, 05 Apr 2025 18:42:14 GMT
Server: json

Hello!
```

### 🩺 Health
Simple endpoint to check whether the server is alive, giving back `200 OK`.

- __URL:__ http://localhost:8080/health
- __HTTPMethod:__ `GET`

```
$ curl -i http://localhost:8080/health
HTTP/1.1 200 OK
Content-Length: 0
Date: Sat, 05 Apr 2025 18:44:27 GMT
Server: json
```

### {  } JSON API
#### Lists all the people in the database

- __URL:__ http://localhost:8080/api/v1/people
- __HTTPMethod:__ `GET`

```
$ curl "http://localhost:8080/api/v1/people"
```

__Return value:__
An array of
- `id`:  person UUID
- `details`: 
  - `nat`: nationality
  - `email`: email address
  - `hobbies`: array of hobbies
  - `name` 
    - `title`: title
    - `first`: first name
    - `last`: last name

```json
[
  {
    "id": "32AACC67-B1F5-4DE6-84E0-C7A9285BE618",
    "details": {
      "nationality": "DE",
      "hobbies": [
        "reading"
      ],
      "name": {
        "last": "Strecker",
        "first": "Thoralf",
        "title": "Mr"
      },
      "email": "thoralf.strecker@example.com"
    }
  },
  {
    "id": "A7A452B6-90B1-415D-A1D5-468EC4E85C19",
    "details": {
      "name": {
        "last": "Ferguson",
        "title": "Miss",
        "first": "Yvonne"
      },
      "hobbies": [
        "swimming",
        "hiking"
      ],
      "nationality": "US",
      "email": "yvonne.ferguson@example.com"
    }
  },
  ...
]
```

#### Shows a single person with id

- __URL:__ http://localhost:8080/api/v1/people/:id
- __HTTPMethod:__ `GET`

```
$ curl "http://localhost:8080/api/v1/people/6C22EEE1-B2B3-42AA-B404-CF64C1595612"
```

__Return value:__
- `id`:  person UUID
- `details`:
  - `nat`: nationality
  - `email`: email address
  - `hobbies`: array of hobbies
  - `name` 
      - `title`: title
      - `first`: first name
      - `last`: last name

```json
{
  "id": "A7A452B6-90B1-415D-A1D5-468EC4E85C19",
  "details": {
    "name": {
      "last": "Ferguson",
      "title": "Miss",
      "first": "Yvonne"
    },
    "hobbies": [
      "swimming",
      "hiking"
    ],
    "nationality": "US",
    "email": "yvonne.ferguson@example.com"
  }
}
```

#### Returns the list of people which comply to the filter

- __URL:__ http://localhost:8080/api/v1/people/filter
- __HTTPMethod:__ `GET`

```
$ curl "http://localhost:8080/api/v1/people?nat=DE&hobbies=reading"
```
This will generate the following PL/SQL query:
```sql
SELECT
    id,
    people_list
FROM
    people
WHERE
    JSON_EXISTS ( people_list, '$.hobbies[*]?(@ == "reading")' )
    AND JSON_VALUE(people_list, '$.nat') = 'NL';
```

__Return value:__
An array of
- `id`:  person UUID
- `details`:
  - `nat`: nationality
  - `email`: email address
  - `hobbies`: array of hobbies
  - `name` 
      - `title`: title
      - `first`: first name
      - `last`: last name

```json
[
  {
    "id": "9F9DF92B-9C61-490E-8FB3-2ADCE3132DD1",
    "details": {
      "nationality": "NL",
      "hobbies": [
        "movies",
        "reading",
        "swimming",
        "hiking",
        "cooking"
      ],
      "email": "bea.deboom@example.com",
      "name": {
        "last": "De Boom",
        "first": "Bea",
        "title": "Ms"
      }
    }
  },
  {
    "id": "9D1CA4CF-8B48-40BB-A494-1B15E801B92C",
    "details": {
      "name": {
        "first": "Raynor",
        "title": "Mr",
        "last": "Felter"
      },
      "email": "raynor.felter@example.com",
      "nationality": "NL",
      "hobbies": [
        "reading",
        "swimming",
        "hiking",
        "cooking",
        "gardening"
      ]
    }
  },
  {
    "id": "3C1AFFC1-7A5B-477B-90CD-8F3BD62E6D1F",
    "details": {
      "hobbies": [
        "reading",
        "swimming",
        "hiking",
        "cooking",
        "gardening"
      ],
      "name": {
        "first": "Eke",
        "last": "Van der Gaast",
        "title": "Ms"
      },
      "email": "eke.vandergaast@example.com",
      "nationality": "NL"
    }
  }
]
```

#### Creates a single person with id

- __URL:__ http://localhost:8080/api/v1/people/
- __HTTPMethod:__ `POST`

```
$ curl -X "POST" "http://localhost:8080/api/v1/people" \
     -H 'Content-Type: application/json' \
     -d $'{
  "details": {
    "email": "lilian.kindler@example.com",
    "hobbies": [
      "karate",
      "running",
      "movies"
    ],
    "nationality": "DE",
    "name": {
      "first": "Lilian",
      "title": "Ms",
      "last": "Kindler"
    }
  }
}'
```

__Return value:__

`201 Created`

#### Edits the person with id

- __URL:__ http://localhost:8080/api/v1/people/:id
- __HTTPMethod:__ `PUT`

```
$ curl -X "PUT" "http://localhost:8080/api/v1/people/BFDA1A91-1681-4703-8DC3-E22876EF346A" \
     -H 'Content-Type: application/json' \
     -d $'{
  "details": {
    "email": "lilian.kindler@example.com",
    "hobbies": [
      "karate",
      "running",
      "movies"
    ],
    "nationality": "NL",
    "name": {
      "first": "Lilian",
      "title": "Ms",
      "last": "Kindler"
    }
  }
}'
```

__Return value:__

`200 OK`

#### Deletes the person with id

- __URL:__ http://localhost:8080/api/v1/people/:id
- __HTTPMethod:__ `DELETE`

```
$ curl -X "DELETE" "http://localhost:8080/api/v1/people/BFDA1A91-1681-4703-8DC3-E22876EF346A"
```

__Return value:__

`204 No content`