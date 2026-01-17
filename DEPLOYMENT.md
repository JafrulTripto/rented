# Deployment Guide for Rented Backend

This guide explains how to deploy the backend services to your personal server using Docker Compose.

## Prerequisites

On your server, ensure you have the following installed:
- **Git**: To clone the repository.
- **Docker**: To run containers.
- **Docker Compose**: To orchestrate the services.

## 1. Clone the Repository

SSH into your server and clone the project:

```bash
git clone https://github.com/JafrulTripto/rented.git
cd rented
```

## 2. Configure Environment Variables

Create a `.env` file in the root directory (`rented/.env`) with your production secrets.

**IMPORTANT**: Do NOT commit this file to Git.

```bash
nano .env
```

Paste the following content and replace the values with your own secure passwords:

```env
# Database Configuration
POSTGRES_USER=rented_admin
POSTGRES_PASSWORD=secure_password_hear
POSTGRES_DB=rented_prod

# App Configuration
JWT_SECRET=super_secret_jwt_key_change_this_to_something_random
ENV=production
```

## 3. Run the Backend

Start the services in detached mode (background):

```bash
docker-compose up -d --build
```

- `--build`: Forces a rebuild of the Go binary to ensure you run the latest code.
- `-d`: Detaches the terminal so it keeps running after you exit.

## 4. Verification

Check if the containers are running:

```bash
docker-compose ps
```

You should see `rented-backend-1` and `rented-postgres-1` (or similar names) with status `Up`.

Test the health endpoint (assuming port 8080 is open):

```bash
curl http://localhost:8080/health
```

## 5. Updating the App

To deploy a new version:

```bash
# 1. Pull changes
git pull origin main

# 2. Rebuild and restart
docker-compose up -d --build
```

## 6. Cleanup (Optional)

To stop and remove containers (data in postgres volume will persist):

```bash
docker-compose down
```

To wipe everything (INCLUDING DATABASE DATA):

```bash
docker-compose down -v
```
