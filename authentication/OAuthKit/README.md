# Basic CRUD operations and OAuthKit using Oracle database

The example demonstrate "Sign in with Google" using [OAuthKit](https://github.com/thoven87/oauth-kit/tree/main). The app  connects to Oracle database. It creates a table, then user can add read entires without credentials but for creating new, update and delete a balid session must exists.

## Routes

- **GET** `/` – Index page  
- **GET** `/parks/:id` – Show details of a single park  
- **GET** `/login` – Login page (renders a link to Google OAuth)  
- **GET** `/oauth/google` – Initiates Google OAuth login  
- **GET** `/oauth/google/callback` – Handles Google OAuth callback  
- **GET** `/logout` – Logs out the current user  
- **GET** `/parks/create` – Show form to create a new park  
- **POST** `/parks/create` – Submit form to create a new park  
- **GET** `/parks/:id/edit` – Show form to edit an existing park  
- **POST** `/parks/:id/edit` – Submit form to edit an existing park  
- **GET** `/parks/:id/delete` – Delete a park by ID  

---

### Index
Lists all parks in the database.

- **URL:** `http://localhost:8080/`  
- **HTTP Method:** `GET`

### Show Park
Retrieves details of a single park by ID.

- **URL:** `http://localhost:8080/parks/:id`
- **HTTP Method:** `GET`

### Login Page
Renders a login page with a link to Google OAuth.

- **URL:** `http://localhost:8080/login`
- **HTTP Method:** `GET`


### Initiate Google OAuth Login
Initiates the Google OAuth login process.

- **URL:** `http://localhost:8080/oauth/google`
- **HTTP Method:** `GET`



### Google OAuth Callback
Handles the callback from Google OAuth after successful authentication.

- **URL:** `http://localhost:8080/oauth/google/callback`
- **HTTP Method:** `GET`


### Logout
Logs out the current user.

- **URL:** `http://localhost:8080/logout`
- **HTTP Method:** `GET`


### Create Park
Shows a form to create a new park.

- **URL:** `http://localhost:8080/parks/create`
- **HTTP Method:** `GET`


### Submit New Park
Submits a form to create a new park.

- **URL:** `http://localhost:8080/parks/create`
- **HTTP Method:** `POST`


### Edit Park
Shows a form to edit an existing park.

- **URL:**`http://localhost:8080/parks/:id/edit`
- **HTTP Method:** `GET`


### Submit Edited Park
Submits a form to edit an existing park.

- **URL:** `http://localhost:8080/parks/:id/edit`
- **HTTP Method:** `POST`


### Delete Park
Deletes a park by ID.

- **URL:** `http://localhost:8080/parks/:id/delete`
- **HTTP Method:** `GET`

