# Multi-stage build for the application
# Stage 1: Build stage
FROM <base-image>:<version> AS builder

WORKDIR /app

# Install any build dependencies
RUN <install-build-dependencies>

# Copy dependency files first (for layer caching)
COPY <dependency-files> ./

# Install dependencies
RUN <install-dependencies-command>

# Copy source code
COPY . .

# Build the CLI binary
RUN <build-cli-command>

# Build the API server binary
RUN <build-server-command>

# Stage 2: Runtime stage
FROM alpine:3.22 AS run

WORKDIR /app

# Copy built binaries from builder stage
COPY --from=builder /app/cli .
COPY --from=builder /app/server .
COPY --from=builder /app/start.sh .

# Copy tasks folder
COPY --from=builder /app/tasks ./tasks

# Install cron daemon and make startup script executable
RUN chmod +x start.sh && \
    apk add --no-cache cronie

# Set up crontab directory
RUN touch /etc/cron.d/root && \
    chmod 644 /etc/cron.d/root

# Environment variables
ENV CRONTAB_FILE=/etc/cron.d/root
ENV PORT=3000
ENV TASKS_DIR=/app/tasks

# Expose the API port
EXPOSE 3000

# Use the startup script as entrypoint
ENTRYPOINT ["./start.sh"]
