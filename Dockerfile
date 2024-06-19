# Use the official Python image from the Docker Hub
FROM python:3.9-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Install the required packages and tools
RUN apt-get update && apt-get install -y \
    iproute2 \
    iputils-ping

# Set the working directory
WORKDIR /app

# Copy the application code to the container
COPY ./app /app/

# Install the required packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy the startup script into the container
COPY entrypoint.sh /usr/local/bin/entrypoint

# Make the script executable
RUN chmod +x /usr/local/bin/setup-routing.sh

# Expose the port the app runs on
EXPOSE 8080

# Set the script to run on container start
ENTRYPOINT ["/usr/local/bin/entrypoint"]