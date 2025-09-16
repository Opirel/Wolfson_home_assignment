# Wolfson Home Assignment

# before we start, i want to share base assumptions and premises:

# 1. i assume that you have docker installed and running

# 2. i assume that you have basic knowledge of docker and docker-compose

# 3. i assume that you have a code editor installed (like VSCode)

# 4. for the sake of simplicity, i assumed there are no surgeries in this department, treatment plans are straightforward, blood work and analysis is not taken and the focus is on patient management and basic medical records. if this were a real-world application, the schema would be more complex and would require additional tables and relationships.



This project provides a ready-to-use PostgreSQL database and pgAdmin setup using Docker Compose. It includes all schema and data needed for the `WomensDeptDB` database.

---

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop) installed and running
- [Git](https://git-scm.com/downloads) (optional, for cloning the repo)

---

## Getting Started

1. **Clone the repository:**
    ```powershell
    git clone https://github.com/Opirel/Wolfson_home_assignment.git
    ```

2. **Configure environment variables:**
    - create `.env` file from  and copy into it the contents of `.env.example` and fill in the required values, or  change  the file name to `.env`    file:
      ```
      POSTGRES_USER=
      POSTGRES_PASSWORD=
      POSTGRES_DB=
      PGADMIN_DEFAULT_EMAIL=
      PGADMIN_DEFAULT_PASSWORD=
      ```

3. **Start the services:**
    ```powershell
    docker compose up
    ```
    - PostgreSQL will be available on port **15432**
    - pgAdmin will be available at [http://localhost:15433](http://localhost:15433)

---

## Accessing pgAdmin

- Open [http://localhost:15433](http://localhost:15433) in your browser.
- Login with the email and password from your `.env` file.
- Register a new server with:
  - **Host:** `database` or `WomensDeptCont`
  - **Port:** `5432`
  - **Username:** `postgres`
  - **Password:** as in your `.env` file
  - **Database:** `WomensDeptDB`

---

## Restoring the Database

After running `docker compose up`, follow these steps to restore the database roles and data:

1. **Copy the SQL files into your running PostgreSQL container:**
    ```powershell
    docker cp globals.sql WomensDeptCont:/globals.sql
    docker cp mydb.dump WomensDeptCont:/mydb.dump
    ```
    Replace `WomensDeptCont` with your actual container name if different. You can find it by running:
    ```powershell
    docker ps
    ```

2. **Restore the roles and data using `psql`:**
    ```powershell
    docker exec -it WomensDeptCont psql -U postgres -d WomensDeptDB -f /globals.sql
    docker exec -it WomensDeptCont psql -U postgres -d WomensDeptDB -f /mydb.dump
    ```

**Notes:**
- Make sure `globals.sql` and `mydb.dump` are in the same directory where you run these commands.
- The database name is `WomensDeptDB`. 
- You need to have Docker installed and running.

---

## Troubleshooting

- **Check container logs:**
    ```powershell
    docker logs WomensDeptCont
    ```
- **If you get a port conflict:**  
  Change the ports in `docker-compose.yml` and restart the containers.
- **If initialization scripts don’t run:**  
  Make sure the `db-data` volume is empty before first startup.

---

## Project Structure

```
WomensDeptAssignment/
├── conf/
│   ├── pg_hba.conf
│   └── postgresql.conf
├── db-data/              # (gitignored) Database persistent storage
├── pgadmin-data/         # (gitignored) pgAdmin persistent storage
├── globals.sql           # Roles and global objects dump
├── mydb.dump             # Database schema and data dump (plain SQL)
├── init.sql              # (optional) Initialization SQL script
├── docker-compose.yml
├── .env
└── README.md
```

---

## License

This project is for educational use.
"# Wolfson_home_assignment" 
