# WordPress Docker Starter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue.svg)](https://www.docker.com/)
[![WordPress](https://img.shields.io/badge/WordPress-6.8.1-blue.svg)](https://wordpress.org/)
[![PHP](https://img.shields.io/badge/PHP-8.3-purple.svg)](https://php.net/)
[![MySQL](https://img.shields.io/badge/MySQL-8.4.5-orange.svg)](https://mysql.com/)

A production-ready WordPress development environment using Docker Compose with automated setup, database management tools, and development utilities.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Services](#services)
- [Database Management](#database-management)
- [Development Tools](#development-tools)
- [File Structure](#file-structure)
- [License](#license)

## Features

✨ **Key Features:**

- 🚀 **One-command setup** - Automated WordPress installation and configuration
- 🐳 **Multi-service architecture** - WordPress, MySQL, phpMyAdmin, WP-CLI, and SFTPGo
- 🔒 **Security-first approach** - Environment-based configuration with secure defaults
- 🛠️ **Development tools** - WP-CLI integration and phpMyAdmin for database management
- 📁 **Enterprise file transfer** - SFTPGo with SFTP, WebDAV, and web admin interface
- 📦 **Data persistence** - Persistent volumes for database and WordPress files
- 🔄 **Import/Export utilities** - Built-in scripts for database backup and restore
- 🎯 **Production-ready** - Health checks, restart policies, and proper networking
- 📝 **Customizable PHP settings** - Easy PHP configuration overrides

## Quick Start

```bash
# Clone the repository
git clone https://github.com/nika2811/wordpress-docker-starter.git
cd wordpress-docker-starter

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your preferred settings

# Start the entire stack
docker compose up -d

# Access your WordPress site
open http://127.0.0.1
```

Your WordPress site will be available at `http://127.0.0.1` and phpMyAdmin at `http://127.0.0.1:8080`.

## Prerequisites

- **Docker** 20.10+ ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose** 2.0+ ([Install Docker Compose](https://docs.docker.com/compose/install/))
- **Minimum 2GB RAM** and **5GB disk space**

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 2GB | 4GB+ |
| Storage | 5GB | 10GB+ |
| CPU | 2 cores | 4+ cores |

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/nika2811/wordpress-docker-starter.git
cd wordpress-docker-starter
```

### 2. Environment Configuration

```bash
# Copy the environment template
cp .env.example .env

# Edit the configuration file
nano .env  # or use your preferred editor
```

### 3. Launch the Stack

```bash
# Start all services in detached mode
docker compose up -d

# View logs (optional)
docker compose logs -f
```

### 4. Verify Installation

```bash
# Check service status
docker compose ps

# Test WordPress accessibility
curl -I http://127.0.0.1
```

## Configuration

### Environment Variables

The `.env` file contains all configurable options:

```bash
# Network Configuration
IP_ADDRESS=127.0.0.1          # Bind IP address
PORT=80                       # WordPress port

# Database Credentials
DB_ROOT_PASSWORD=your_secure_root_password_here
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wp_user
WORDPRESS_DB_PASSWORD=your_secure_user_password_here

# WordPress Installation
WP_URL=http://127.0.0.1
WP_TITLE="My Awesome Site"
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=your_secure_admin_password_here
WP_ADMIN_EMAIL=admin@example.com
```

### Important Security Notes

⚠️ **Before production deployment:**

1. **Change all default passwords** in the `.env` file
2. **Use strong passwords** (12+ characters with mixed case, numbers, symbols)
3. **Set unique database credentials**
4. **Configure proper firewall rules**
5. **Use HTTPS** with SSL certificates

### PHP Configuration

Custom PHP settings can be added to `config/wp_php.ini`:

```ini
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
memory_limit = 256M
```

## Usage

### Basic Operations

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart services
docker compose restart

# View service logs
docker compose logs [service_name]

# Update to latest images
docker compose pull && docker compose up -d
```

### WordPress Management

```bash
# Access WordPress admin
open http://127.0.0.1/wp-admin

# Default credentials (change these!)
Username: admin
Password: your_secure_admin_password_here
```

## Services

### WordPress (`wordpress`)
- **Image:** `wordpress:6.8.1-php8.3-apache`
- **Port:** `80` (configurable via `PORT` env var)
- **Features:** Latest WordPress with PHP 8.3 and Apache

### MySQL Database (`db`)
- **Image:** `mysql:8.4.5`
- **Features:** UTF8MB4 support, health checks, persistent storage
- **Volume:** `db_data` for data persistence

### phpMyAdmin (`phpmyadmin`)
- **Image:** `phpmyadmin:5.2.2-apache`
- **Port:** `8080`
- **Features:** Web-based MySQL administration

### WP-CLI (`wpcli`)
- **Image:** `wordpress:cli-2.12.0-php8.3`
- **Usage:** Command-line WordPress management
- **Features:** Full WP-CLI functionality

### WordPress Setup (`wp-setup`)
- **Purpose:** One-time WordPress installation
- **Features:** Automated core installation and configuration

### SFTPGo (`sftpgo`)
- **Image:** `drakkan/sftpgo:v2.6.2`
- **Ports:** `2022` (SFTP), `8090` (Admin UI), `10080` (WebDAV)
- **Features:** Enterprise file transfer server with multiple protocols
- **Protocols:** SFTP, SCP, FTP/S, WebDAV
- **Security:** Advanced user management, virtual folders, audit logging

#### SFTPGo Access Details
- **SFTP Server:** `sftp://127.0.0.1:2022`
- **Admin Web UI:** `http://127.0.0.1:8090`
- **WebDAV Server:** `http://127.0.0.1:10080`
- **Default Admin:** `admin` / (configured via environment variables)

#### SFTPGo Management

**Initialize SFTPGo (First-time setup):**
```bash
# Linux/macOS
./docker/sftpgo/manage-sftpgo.sh init

# Windows PowerShell
.\docker\sftpgo\manage-sftpgo.ps1 init
```

**User Management:**
```bash
# Create a new SFTP user
./docker/sftpgo/manage-sftpgo.sh create-user developer mypassword123

# List all users
./docker/sftpgo/manage-sftpgo.sh list-users

# Delete a user
./docker/sftpgo/manage-sftpgo.sh delete-user developer

# Check service status
./docker/sftpgo/manage-sftpgo.sh status
```

**Configuration Backup:**
```bash
# Create backup
./docker/sftpgo/manage-sftpgo.sh backup sftpgo-backup.json

# Restore backup
./docker/sftpgo/manage-sftpgo.sh restore sftpgo-backup.json
```

#### SFTPGo Features
- ✅ **Multi-protocol support:** SFTP, SCP, FTP/S, WebDAV
- ✅ **Web Admin Interface:** User-friendly management UI
- ✅ **Virtual Folders:** Flexible file system mapping
- ✅ **Advanced Security:** Rate limiting, IP filtering, MFA support
- ✅ **Audit Logging:** Comprehensive activity tracking
- ✅ **REST API:** Programmatic management
- ✅ **High Performance:** Built for enterprise workloads

## Database Management

### Using phpMyAdmin

Access the web interface at `http://127.0.0.1:8080`:

- **Server:** `db`
- **Username:** `root`
- **Password:** Value from `DB_ROOT_PASSWORD`

### Using WP-CLI

```bash
# Run WP-CLI commands
docker compose run --rm wpcli wp --info

# Install plugins
docker compose run --rm wpcli wp plugin install akismet --activate

# Export database
docker compose run --rm wpcli wp db export /var/www/html/backup.sql

# List users
docker compose run --rm wpcli wp user list
```

### Database Export/Import

The project includes utility scripts for database management:

```bash
# Export database
./export.sh

# Import database
./import.sh path/to/backup.sql
```

## Development Tools

### File Synchronization

- WordPress core files: Managed by Docker volumes
- Custom content: Mount `./wp-content` for theme and plugin development
- Configuration: `./config/wp_php.ini` for PHP settings

### Debugging

```bash
# Enable WordPress debugging (add to wp-config.php)
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);

# View debug logs
docker compose exec wordpress tail -f /var/www/html/wp-content/debug.log
```

### Performance Monitoring

```bash
# Monitor resource usage
docker compose exec wordpress top

# Check disk usage
docker compose exec wordpress df -h
```

## File Structure

```
wordpress-docker-starter/
├── .env                        # Environment configuration
├── .env.example               # Environment template
├── docker-compose.yml         # Main Docker Compose configuration
├── export.sh                  # Database export utility
├── import.sh                  # Database import utility
├── LICENSE                    # MIT License
├── README.md                  # This file
├── config/
│   └── wp_php.ini            # Custom PHP configuration
├── docker/
│   ├── setup/
│   │   └── install-wp.sh     # WordPress installation script
│   └── wpcli/
│       └── entrypoint.sh     # WP-CLI entrypoint script
└── wp-content/               # WordPress content (auto-created)
    ├── themes/               # Custom themes
    ├── plugins/              # Custom plugins
    └── uploads/              # Media uploads
```



## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**⭐ Star this repo** if you find it helpful!
