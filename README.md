# api.xoren.io

Backend api for xoren.io


## Stack (PHART)

- **[Laravel](https://laravel.com)**
- **[Swoole](https://swoole.com)**
- **[Redis](https://redis.io)**
- **[Soketi](https://soketi.app)**
- **[MySQL](https://mysql.com)**
- **[NGINX](https://nginx.com)**

## Setup

### Local development

From the root of the project please copy the .env.example to .env

Please follow these commands

```bash
 $ docker-compose -f docker-compose.local.yml build
 $ docker-compose -f docker-compose.local.yml run --rm laravel composer install && php artisan migrate:fresh --seed
 $ docker-compose -f docker-compose.local.yml up -d
```

## Testing

For testing please use PHPUnit via artisan

```bash
 $ docker-compose -f docker-compose.local.yml run --rm laravel php artisan test
```

## Specific Testing

For testing specific test

```bash
 $ docker-compose -f docker-compose.local.yml run --rm laravel php artisan test --filter <class> <path>
```