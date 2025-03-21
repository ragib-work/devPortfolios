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

# Create the project directory
RUN mkdir -p /code

# Set working directory
WORKDIR /code

# Copy all necessary files and folders individually (since no `src/` folder)
COPY requirements.txt /tmp/requirements.txt
COPY . /code  # Copies all files and folders at the root level

# Install Python dependencies
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Set Django environment variables
ARG DJANGO_SECRET_KEY
ENV DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}

ARG DJANGO_DEBUG=0
ENV DJANGO_DEBUG=${DJANGO_DEBUG}

# Run collectstatic at build time (optional for Railway)
RUN python manage.py collectstatic --noinput

# Set the Django project name (change if necessary)
ARG PROJ_NAME="your_project_name"

# Create the startup script
RUN printf "#!/bin/bash\n" > ./start.sh && \
    printf "RUN_PORT=\"\${PORT:-8000}\"\n\n" >> ./start.sh && \
    printf "python manage.py migrate --no-input\n" >> ./start.sh && \
    printf "gunicorn ${PROJ_NAME}.wsgi:application --bind \"0.0.0.0:\$RUN_PORT\"\n" >> ./start.sh

# Make the script executable
RUN chmod +x start.sh

# Run the Django project when the container starts
CMD ./start.sh
