# WordPress Docker Starter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue.svg)](https://www.docker.com/)
[![WordPress](https://img.shields.io/badge/WordPress-6.8.1-blue.svg)](https://wordpress.org/)
[![PHP](https://img.shields.io/badge/PHP-8.3-purple.svg)](https://php.net/)
[![MySQL](https://img.shields.io/badge/MySQL-8.4.5-orange.svg)](https://mysql.com/)

A production-ready WordPress development environment using Docker Compose with automated setup, security hardening, and development tools.

## Features

- 🚀 **One-command setup** - Automated WordPress installation
- 🐳 **Multi-service stack** - WordPress, MySQL, phpMyAdmin, WP-CLI
- 🔒 **Security-first** - Environment variables, SSL support, hardening scripts
- 🛠️ **Developer tools** - WP-CLI integration, phpMyAdmin, custom PHP config
- 📦 **Data persistence** - Docker volumes for database and WordPress files
- 🔄 **Backup utilities** - Database export/import scripts

## Quick Start

```bash
# Clone and setup
git clone https://github.com/nika2811/wordpress-docker-starter.git
cd wordpress-docker-starter
cp .env.example .env

# Start services
docker compose up -d

# Access your site
# WordPress: http://localhost:3030
# phpMyAdmin: http://localhost:9001
```

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 2GB RAM minimum

## Configuration

### Environment Variables

Create `.env` from `.env.example` and configure:

```bash
PORT=3030                          # WordPress port
IP_ADDRESS=127.0.0.1              # Bind address
WORDPRESS_DB_NAME=wordpress        # Database name
WORDPRESS_DB_USER=wp_user          # Database user
# Set secure passwords for production
```

### PHP Settings

Custom PHP configuration in `config/wp_php.ini`:

```ini
upload_max_filesize = 64M
post_max_size = 64M
memory_limit = 256M
```

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| WordPress | wordpress:6.8.1-php8.3-apache | 3030 | Main WordPress site |
| MySQL | mysql:8.4.5 | - | Database server |
| phpMyAdmin | phpmyadmin:5.2.2-apache | 9001 | Database management |
| WP-CLI | wordpress:cli-2.12.0-php8.3 | - | WordPress CLI tools |

## Usage

```bash
# Start all services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Run WP-CLI commands
docker compose run --rm wpcli wp plugin list

# Database backup
./export.sh

# Database restore
./import.sh backup.sql
```

## Production Deployment

### SSL Setup (Windows)
```powershell
.\scripts\generate-ssl-windows.ps1
.\scripts\deploy-production.ps1 -Domain 'yourdomain.com' -Email 'admin@yourdomain.com'
```

### SSL Setup (Linux/Mac)
```bash
./scripts/generate-ssl.sh
docker-compose -f docker-compose.prod.yml up -d
```

## Security

⚠️ **Before production:**
1. Change all default passwords in `.env`
2. Use strong passwords (12+ characters)
3. Configure firewall rules
4. Enable HTTPS with SSL certificates
5. Run security hardening script

```powershell
# Windows
.\scripts\security-hardening.ps1

# Linux/Mac
./scripts/security-hardening.sh
```

## File Structure

```
wordpress-docker-starter/
├── .env                    # Environment configuration
├── docker-compose.yml     # Main Docker Compose file
├── docker-compose.prod.yml # Production configuration
├── export.sh / import.sh  # Database utilities
├── config/
│   └── wp_php.ini         # PHP configuration
├── scripts/               # Deployment & utility scripts
├── secrets/               # Auto-generated passwords
└── wp-content/           # WordPress content
```

## Troubleshooting

**Port conflicts:**
```bash
# Check what's using the port
netstat -tulpn | grep :3030
# Change PORT in .env file
```

**Permission issues:**
```bash
docker compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content
```

**Database connection failed:**
```bash
docker compose logs db
docker compose restart db
```

## Support

- [Issues](https://github.com/nika2811/wordpress-docker-starter/issues)
- [Discussions](https://github.com/nika2811/wordpress-docker-starter/discussions)

## License

MIT License - see [LICENSE](LICENSE) file for details.
