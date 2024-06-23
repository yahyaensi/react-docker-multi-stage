# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

# Want to help us make this template better? Share your feedback here: https://forms.gle/ybq9Krt8jtBL3iCk7

ARG NODE_VERSION=20.13.1
ARG NGINX_VERSION=3.19

################################################################################
# Use node image for base image for all stages.
FROM node:${NODE_VERSION}-alpine AS base

# Set working directory for all build stages.
WORKDIR /usr/src/app



################################################################################
# Create a stage for installing dependecies for dev environment.
FROM base AS deps-for-dev

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Leverage bind mounts to package.json and package-lock.json to avoid having to copy them
# into this layer.
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json,rw \
    --mount=type=cache,target=/root/.npm \
    npm install


################################################################################
# Create a stage for installing dependecies for production environment.
FROM base AS deps-for-prod

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Leverage bind mounts to package.json and package-lock.json to avoid having to copy them
# into this layer.
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev


    
################################################################################
# Create a stage to run application in dev environment.
FROM deps-for-dev AS dev-environment

# Copy the source files into the image src, public, package.json and package-lock.json
COPY . .

ENTRYPOINT ["npm", "start" ]



################################################################################
# Create a stage for building the application.
FROM deps-for-prod AS build

# Copy the source files into the image.
COPY src src
COPY public public

# RUN pwd (to see pwd result use : docker build -t react-docker-prod:1.0 . --no-cache --progress=plain)
# RUN ls -l (to see ls result use : docker build -t react-docker-prod:1.0 . --no-cache --progress=plain)

# Run the build script.
RUN --mount=type=bind,source=package.json,target=package.json \
    npm run build



################################################################################
# prod-environment
# Pulls the official nginx image
FROM nginx:stable-alpine${NGINX_VERSION} AS prod-environment

# Use production node environment by default.
ENV NODE_ENV=production

# Run the application as a non-root user.
# USER nginx

# Copy nginx.conf into the image.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built application from the build stage into the image.
COPY --from=build /usr/src/app/build /usr/share/nginx/html 
