# Use an official Python runtime as a parent image
FROM python:3.6-slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt

# Make port 50001 available to the world outside this container
EXPOSE 50001

# Let the GOOGLE_PLACE_API_KEY environment variable be passed at runtime
ARG API_KEY

ENV GOOGLE_PLACES_API_KEY=$API_KEY

# Run app.py when the container launches
CMD ["python", "restaurant_info_server.py"]
