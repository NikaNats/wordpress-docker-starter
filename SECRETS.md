# Docker Secrets Setup

This project now uses Docker Compose secrets for secure credential management instead of environment variables.

## Secret Files

The following secret files are located in the `secrets/` directory:

- `db_root_password.txt` - MySQL root password
- `db_password.txt` - WordPress database user password  
- `wp_admin_password.txt` - WordPress admin user password

## Security Benefits

- Secrets are mounted as files in `/run/secrets/` inside containers
- Better access control via filesystem permissions
- Reduced risk of credential exposure in logs or process lists
- Granular access control per service

## Setup Instructions

1. **Update secret files with your own passwords:**
   ```bash
   echo "your_secure_root_password" > secrets/db_root_password.txt
   echo "your_secure_db_password" > secrets/db_password.txt
   echo "your_secure_admin_password" > secrets/wp_admin_password.txt
   ```

2. **Set proper file permissions (Linux/macOS):**
   ```bash
   chmod 600 secrets/*.txt
   ```

3. **Start the services:**
   ```bash
   docker-compose up -d
   ```

## Important Notes

- The `secrets/` directory is excluded from git via `.gitignore`
- Default passwords are included for development - **CHANGE THEM** for production
- Secrets are automatically mounted to `/run/secrets/<secret_name>` in containers
- Services only access secrets they explicitly require

## Environment Variables Still Used

Non-sensitive configuration remains in `.env`:
- `IP_ADDRESS` - Server IP address
- `PORT` - WordPress port
- `WORDPRESS_DB_NAME` - Database name
- `WORDPRESS_DB_USER` - Database username (non-sensitive)
- `WP_URL` - WordPress URL
- `WP_TITLE` - Site title
- `WP_ADMIN_USER` - Admin username (non-sensitive)
- `WP_ADMIN_EMAIL` - Admin email

## Migration from Environment Variables

This setup replaces these environment variables with secrets:
- `DB_ROOT_PASSWORD` → `secrets/db_root_password.txt`
- `WORDPRESS_DB_PASSWORD` → `secrets/db_password.txt`
- `WP_ADMIN_PASSWORD` → `secrets/wp_admin_password.txt`
