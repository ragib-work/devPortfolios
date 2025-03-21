# Set Python version as a build-time argument (default to 3.12)
ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}

# Create a virtual environment
RUN python -m venv /opt/venv

# Set the virtual environment as the current location
ENV PATH=/opt/venv/bin:$PATH

# Upgrade pip
RUN pip install --upgrade pip

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev libjpeg-dev libcairo2 gcc \
    && rm -rf /var/lib/apt/lists/*

# Set working directory to the root of the project
WORKDIR /app

# Copy all project files and folders (since there is no `src/` or `code/` directory)
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set Django environment variables
ARG DJANGO_SECRET_KEY
ENV DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}

ARG DJANGO_DEBUG=0
ENV DJANGO_DEBUG=${DJANGO_DEBUG}

# Collect static files
RUN python manage.py collectstatic --noinput

# Set the Django project name (update this if needed)
ARG PROJ_NAME="devsearch"

# Create the startup script
RUN echo "#!/bin/bash" > ./start.sh && \
    echo "RUN_PORT=\"\${PORT:-8000}\"" >> ./start.sh && \
    echo "python manage.py migrate --no-input" >> ./start.sh && \
    echo "gunicorn ${PROJ_NAME}.wsgi:application --bind \"0.0.0.0:\$RUN_PORT\"" >> ./start.sh

# Make the script executable
RUN chmod +x start.sh

# Run the Django project when the container starts
CMD ./start.sh
