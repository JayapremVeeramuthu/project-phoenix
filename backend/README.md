# Project Phoenix Enterprise Backend

This is the production-ready NestJS (LTS) clean architecture backend for Project Phoenix.

---

## 1. Technologies Stack
- **Framework**: NestJS (TypeScript)
- **Database ORM**: Prisma (PostgreSQL database driver)
- **Caching Layer**: Valkey (Redis-compatible cluster key-value store)
- **Event Bus / Message Queue**: RabbitMQ (amqp)
- **Object Media Store**: MinIO (S3 compatible S3 buckets storage)
- **Search System**: Meilisearch

---

## 2. Infrastructure Setup (Docker Compose)
To spin up dependencies locally, run:
```bash
docker-compose up -d
```
This spins up:
- **PostgreSQL**: Port `5432`
- **Valkey**: Port `6379`
- **RabbitMQ**: Port `5672` (Console: `15672`)
- **MinIO**: Port `9000` (Console: `9001`)
- **Meilisearch**: Port `7700`

---

## 3. Getting Started & Installation
1. Install package modules:
   ```bash
   npm install
   ```
2. Set up environment file:
   ```bash
   cp .env.template .env
   ```
3. Run database migrations:
   ```bash
   npx prisma migrate dev
   ```
4. Run in hot-reload development mode:
   ```bash
   npm run start:dev
   ```

---

## 4. API Endpoints Versioning & Swagger Docs
- API Base URL: `http://localhost:3000/api/v1`
- Swagger Documentation Console: `http://localhost:3000/swagger`
