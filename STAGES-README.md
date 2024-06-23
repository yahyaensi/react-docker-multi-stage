\*) Build PROD (without specifying target stage, all stages are executed)

    docker build -t react-app:latest . --no-cache

    docker run -it --rm -p 80:80 --name react-app react-app:latest

\*) Build DEV (by specifying dev-environment target stage, Docker will not execute prod-build stage)

    docker build --target dev-environment -t react-app:latest . --no-cache

    docker run -it --rm -p 3000:3000 --name react-app react-app:latest
