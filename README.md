### Wolfson Home Assignment

### Before we start, here are some basic assumptions, premises and general notes:

#### 1. I assume that you have Docker installed and running.

#### 2. I assume that you have basic knowledge of Docker and Docker Compose.

#### 3. I assume that you have a code editor installed (such as VSCode).

#### 4. I assume that you are using windows os and using postgresql locally.

#### 5. For the sake of simplicity, I assume treatment plans are straightforward, blood work and analysis are not included, and the focus is on patient management and basic medical records. If this were a real-world application, the schema would be more complex and would require additional tables and relationships.

#### 6. for the sake of simplicity, I assume that there are no surgeries in this department. but kept surgeries as a specoiality for some doctors and pre-op and post-op care for a bit of realism.

#### 7. to demonstrate backup and restore, I have used plain sql dump for the database. in real world, custom format is preffered.

#### 8. when running queries, use full path "womens_dept.table_name" or set search_path to womens_dept.


What this project demonstrates (capabilities):
- Initialization via initdb/ SQL files:
  - 01_schema_roles.sql, 02_users_and_grants.sql, 03_core_tables.sql, 04_seed.sql
  - Each file runs in its own psql session on first startup when the data volume is empty.
- Idempotent seeds and migrations:
  - ON CONFLICT upserts, ADD COLUMN IF NOT EXISTS, and DO $$ blocks to run conditional DDL safely.
- Schema management:
  - All objects live in the womens_dept schema; scripts use schema-qualified names or set role defaults.
- Role/search_path handling:
  - Demonstrates setting persistent search_path via ALTER ROLE for hospital_admin when needed.
- Backup & restore:
  - globals.sql (pg_dumpall --globals-only) to capture roles and password hashes.
  - womensdept.dump (pg_dump -Fc) for database schema + data.
  - Commands shown below for creation and restore.
- Recovery without reinit:
  - How to re-run seed scripts against a live DB without removing the data volume.

Important commands (PowerShell)



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
  - Create a `.env` file and copy the contents of `.env.example` into it. Fill in the required values, or rename the file to `.env`:
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
- Log in with the email and password from your `.env` file.
- Register a new server with:
  - **Host:** `database` or `WomensDeptCont`
  - **Port:** `5432`
  - **Username:** `postgres`
  - **Password:** as in your `.env` file
  - **Database:** `WomensDeptDB`


- if using pgadmin locally, use `localhost` and port `15432` instead.
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
  Make sure the `db-data` volume is empty before the first startup.

---

## Project Structure

```
WomensDeptAssignment/
├── conf/                            # Postgres configuration files mounted into container
│   ├── pg_hba.conf
│   └── postgresql.conf
├── initdb/                          # Init scripts run on first container startup (lexical order)
│   ├── 00_search_path.sql
│   ├── 01_schema_roles.sql
│   ├── 02_users_and_grants.sql
│   ├── 03_core_tables.sql
│   ├── 04_audit.sql
│   └── 05_seed.sql
├── commun_searches.sql              # Copy-paste verification queries for testers
├── docker-compose.yml
├── .env                             # Environment variables (gitignored)
├── globals.sql                      # pg_dumpall --globals-only (roles)
├── mydb.dump                        # pg_dump (schema + data) or plain SQL dump
├── db-data/                         # (gitignored) Docker volume mount target (local backup placeholder)
├── pgadmin-data/                    # (gitignored) pgAdmin persistent storage (local placeholder)
└── README.md


```

Notes:
- initdb/ scripts are executed only on first init when the Postgres data directory is empty.
- Make sure .env is populated before docker compose up.
- Adjust file names above if you rename or move files in the repo.

---

## ⚠️ Security Notice

For ease of use, this setup exposes the PostgreSQL database port to the host machine. **This is intended for local development and testing only.**

**Do not use this configuration as-is in production.**

- Always use strong, unique passwords for all database users.
- If deploying in a less trusted environment, restrict access to the database port using a firewall or by changing the port mapping in `docker-compose.yml`.
- Review and tighten the `conf/pg_hba.conf` file to allow only trusted users and authentication methods.
- Never commit real secrets or credentials to the repository.
- For production, further hardening and security measures are required.

---

## License

This project is for educational use.

