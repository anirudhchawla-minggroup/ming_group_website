#!/bin/bash
# entrypoint.sh

# Check the base image and install PostgreSQL client (psql) accordingly
echo "Installing PostgreSQL client (psql)..."

# For Debian-based images (like Ubuntu or Debian)
if [ -f /etc/debian_version ]; then
    apt-get update && apt-get install -y postgresql-client
# For Alpine-based images (like Alpine Linux)
elif [ -f /etc/alpine-release ]; then
    apk add --no-cache postgresql-client
else
    echo "Unsupported base image. Please ensure PostgreSQL client is installed."
    exit 1
fi

# Start PostgreSQL server (if not already started)
echo "Starting PostgreSQL server..."
pg_ctl -D /var/lib/postgresql/data -l logfile start

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
python - <<END
import psycopg2
import time

while True:
    try:
        print("Attempting to connect to PostgreSQL...")
        conn = psycopg2.connect(
            dbname='dashboard_management', 
            user='ming_group', 
            password='1234', 
            host='db', 
            port='5432'
        )
        conn.close()
        print("PostgreSQL is ready!")
        break
    except psycopg2.OperationalError as e:
        print(f"PostgreSQL is not ready yet: {e}")
        time.sleep(2)
END

# Copy the init.sql file to PostgreSQL container and run it
echo "Running init.sql to populate the database..."
psql -h db -U ming_group -d dashboard_management -f /docker-entrypoint-initdb.d/init.sql || echo "SQL file execution skipped (file may already exist)."

# Collect static files
echo "Collecting static files..."
python3 manage.py collectstatic --noinput

# Run migrations
echo "Running migrations..."
python3 manage.py migrate

# Create a Django superuser if environment variables are set
if [[ -n "$DJANGO_SUPERUSER_USERNAME" && -n "$DJANGO_SUPERUSER_EMAIL" && -n "$DJANGO_SUPERUSER_PASSWORD" ]]; then
  echo "Creating superuser..."
  python3 manage.py createsuperuser --noinput \
    --username "$DJANGO_SUPERUSER_USERNAME" \
    --email "$DJANGO_SUPERUSER_EMAIL" || echo "Superuser creation skipped (user might already exist)."
else
  echo "Superuser environment variables not set. Skipping superuser creation."
fi

# Start the application with Gunicorn
echo "Starting Gunicorn..."
exec gunicorn --bind localhost:8001 dashboardManagement.wsgi:application
