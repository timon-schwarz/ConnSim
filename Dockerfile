# Use the official Python image from the Docker Hub
FROM python:3.9-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Install the required packages and tools
RUN apt-get update && apt-get install -y \
    iproute2 \
    iputils-ping

# Copy the requirements file
COPY requirements.txt /app/

# Install the required packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code to the container
COPY . /app/

# Expose the port the app runs on
EXPOSE 8080

# Run the application
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:8080", "app:app"]

