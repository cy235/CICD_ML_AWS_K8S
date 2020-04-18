#!/usr/bin/env bash

# Complete the following steps to get Docker running locally

# Step 1:
# Build image and add a descriptive tag
docker build --tag cy235-prediction .

# Step 2: 
# List docker images
docker image ls

# Step 3: 
# Run flask app
docker run --rm -it --name cy235-prediction -p 8000:80 cy235-prediction
