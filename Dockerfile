# Stage 1: Build Flutter Web application
FROM debian:bookworm-slim AS build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Prevent tar ownership errors in rootless/container environments
ENV TAR_OPTIONS="--no-same-owner --no-same-permissions"

# Install official Flutter SDK (stable channel)
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /sdks/flutter
ENV PATH="/sdks/flutter/bin:${PATH}"

# Enable web support and disable analytics
RUN flutter config --no-analytics && flutter config --enable-web

WORKDIR /app

# Copy dependency configs and resolve pub dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy all source files
COPY . .

ARG BACKEND_URL
RUN flutter build web --release --dart-define=BACKEND_URL=${BACKEND_URL}

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
