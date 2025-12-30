## Inception

This document is a System Administration related exercise.

## Requirements

- Docker
- Docker Compose

## Getting Started

1. Copy the `.env.example` file to `.env`

```bash
cp .env.example .env
```

2. Build the containers

```bash
docker-compose build
```

3. Start the containers

```bash
docker-compose up -d
```

4. Access the WordPress admin panel

```bash
https://${DOMAIN_NAME}
```

## Cleanup

```bash
docker-compose down
```
