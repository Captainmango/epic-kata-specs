# coco-task Specification

## Overview

coco-task is a cron expression parser and task scheduler with HTTP API and CLI interfaces. It allows users to parse cron expressions, schedule tasks, and integrate with message queues for task execution.

## Architecture Overview

The system consists of four main components:

1. **Cron Parser** - Parses and validates 5-field cron expressions
2. **Containerization** - Docker packaging for deployment
3. **Task Scheduler** - Manages scheduled tasks via a crontab file
4. **Web Application** - HTTP API for task management

## Phase 1: Cron Parser

Implement the cron expression parser first. This is the foundation of the system.

### 1.1 Supported Cron Expression Format

The parser must handle standard 5-field cron expressions:

```
minute hour day-of-month month day-of-week
```

**Field Bounds:**

| Field | Lower | Upper | Notes |
|-------|-------|-------|-------|
| Minute | 0 | 59 | |
| Hour | 0 | 23 | |
| Day of Month | 1 | 31 | Cannot be 0 |
| Month | 1 | 12 | Cannot be 0 |
| Day of Week | 1 | 7 | Cannot be 0 |

### 1.2 Supported Operators

The parser must support these operators:

| Operator | Symbol | Description | Example |
|----------|--------|-------------|---------|
| Wildcard | `*` | Matches all values in range | `*` in minute = all 60 minutes |
| Single Value | (number) | Specific number | `30` = only minute 30 |
| Range | `-` | Inclusive range | `1-5` = 1, 2, 3, 4, 5 |
| List | `,` | Comma-separated values | `1,15,30` = minutes 1, 15, and 30 |
| Step/Divisor | `/` | Step values from wildcard | `*/15` = every 15 minutes (0, 15, 30, 45) |

### 1.3 Parser Input/Output

**Input Formats:**
- String: `"*/15 * * * *"`
- String Array: `["*", "*", "*", "*", "*"]`

**Output Requirements:**

The parser should be able to output in two modes:

1. **Possible Values Mode** - Expands the expression to show all matching values:
   ```
   Minute     | 0, 15, 30, 45
   Hour       | 0, 1, 2, 3, ... 23
   Day        | 1, 2, 3, ... 31
   Month      | 1, 2, 3, ... 12
   Weekday    | 1, 2, 3, 4, 5, 6, 7
   ```

2. **Raw Expression Mode** - Returns the original expression:
   ```
   */15 * * * *
   ```

### 1.4 Error Handling

The parser must validate and return appropriate errors for:

- Too few expression parts (less than 5)
- Too many expression parts (more than 5)
- Double spaces in expression
- Invalid characters in expression
- Empty input
- Values out of bounds for each field
- Invalid operator combinations

### 1.5 Parser Test Requirements

Implement tests covering:

**Basic Fragment Tests:**
- Wildcard parsing for each field type
- Range parsing (e.g., `1-5`)
- List parsing (e.g., `1,15,30`)
- Divisor parsing (e.g., `*/15`)
- Single value parsing

**Full Expression Tests:**
- `*/15 0 1,15 * 1-5`
- `0 0 * * *`
- `*/5 */6 */7 */8 1-5`
- Complex mixed expressions

**Error Case Tests:**
- Invalid number of parts
- Double spaces
- Invalid characters
- Empty input
- Out of bounds values

**Edge Cases:**
- Zero values where allowed
- Large lists
- Divisor by one
- Full range values

## Phase 2: Docker Containerization

Create a Docker setup to package the application for deployment. This phase should be completed before building the web application to ensure a consistent deployment environment.

### 2.1 Dockerfile Requirements

Create a `Dockerfile` with the following characteristics:

**Multi-Stage Build:**
- **Builder Stage**: Compiles the application binaries
- **Runtime Stage**: Minimal image with only the built binaries and runtime dependencies

**Key Requirements:**
- Use a minimal base image for the runtime stage (e.g., `alpine:3.22`)
- Install `cronie` (cron daemon) in the runtime stage
- Set up crontab directory at `/etc/cron.d/root`
- Build both CLI and server binaries
- Copy binaries and startup script to `/app` directory
- Expose port 3000 for the API
- Set `CRONTAB_FILE` environment variable

**Dockerfile Structure:**
```dockerfile
# Stage 1: Builder
FROM <base-image>:<version> AS builder
WORKDIR /app
# Install build dependencies
# Copy dependency files
# Install dependencies
# Copy source code
# Build CLI binary
# Build server binary

# Stage 2: Runtime
FROM alpine:3.22 AS run
WORKDIR /app
# Copy binaries from builder
# Copy startup script
# Install cronie
# Set up crontab directory
# Set environment variables
# Expose port
# Set entrypoint
```

### 2.2 Startup Script (start.sh)

Create a `start.sh` script that:
- Starts the cron daemon (`crond`) in the background
- Verifies crond is running
- Supports running additional commands via arguments
- Provides logging with timestamps

Example script structure:
```bash
#!/bin/sh
set -euo

# Logging helper
log() {
    level="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*"
}

# Verify crond is running
check_crond_up() {
    # Check if crond process exists
    # Log status
}

# Start cron daemon
log INFO "starting crond in the background"
crond -f -p -m off &
check_crond_up

# Execute any passed arguments
if [ "$#" -gt 0 ]; then
    exec "$@"
fi
```

### 2.3 Docker Compose (Optional)

Create a `docker-compose.yml` for local development:

**Services:**
- **app**: Your application service
  - Build from Dockerfile
  - Port mapping (3000:3000)
  - Volume for crontab persistence
  - Environment variables

- **rabbitmq** (optional): Message queue for task execution
  - Image: `rabbitmq:3-management`
  - Ports: 5672 (AMQP), 15672 (Management UI)
  - Environment variables for credentials

### 2.4 Build Requirements

The Docker build must:
- Successfully compile both CLI and server binaries
- Create a minimal runtime image (< 50MB ideally)
- Include all necessary runtime dependencies
- Set proper file permissions on the startup script
- Configure the crontab directory with correct permissions (644)

### 2.5 Testing the Docker Setup

Verify the container:
- [ ] Builds without errors
- [ ] Starts successfully with cron daemon running
- [ ] Can execute CLI commands
- [ ] Server binary is executable
- [ ] Crontab file location is writable
- [ ] Port 3000 is exposed and accessible

### 2.6 Running the Container

**Basic run:**
```bash
docker run -p 3000:3000 coco-task
```

**With custom crontab location:**
```bash
docker run -p 3000:3000 -e CRONTAB_FILE=/custom/path coco-task
```

**Execute CLI command:**
```bash
docker run coco-task ./cli --help
```

## Phase 3: Web Application

After completing the Docker setup, implement the web application with HTTP API endpoints.

### 3.1 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/livez` | Health check endpoint |
| GET | `/api/v1/tasks` | List all available tasks (commands) |
| GET | `/api/v1/tasks/scheduled` | List all scheduled tasks |
| POST | `/api/v1/tasks` | Schedule a new task |
| DELETE | `/api/v1/tasks/{id}` | Remove a scheduled task by ID |

### 3.2 Request/Response Formats

#### Health Check (GET /api/v1/livez)

**Response:**
```json
{
  "type": "health_check",
  "data": {
    "status": "OK"
  },
  "error": "",
  "meta": {}
}
```

#### List Available Tasks (GET /api/v1/tasks)

Returns all tasks/commands that can be scheduled.

**Response:**
```json
{
  "type": "available_tasks",
  "data": [
    {
      "id": "start-game",
      "name": "Start Game",
      "description": "Sends a start game message"
    }
  ],
  "error": "",
  "meta": {}
}
```

#### List Scheduled Tasks (GET /api/v1/tasks/scheduled)

Returns all currently scheduled tasks from the crontab.

**Response:**
```json
{
  "type": "scheduled_task",
  "data": [
    {
      "id": "uuid-here",
      "command": "start-game room123",
      "cron": "* * * * *"
    }
  ],
  "error": "",
  "meta": {}
}
```

#### Schedule Task (POST /api/v1/tasks/)

**Request:**
```json
{
  "task_id": "start-game",
  "scheduled_time": "*/5 * * * *",
  "args": {
    "room_id": "room123"
  }
}
```

**Success Response (202 Accepted):**
```json
{
  "type": "scheduled_task",
  "data": {
    "id": "generated-uuid",
    "command": "start-game room123",
    "cron": "*/5 * * * *"
  },
  "error": "",
  "meta": {}
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "type": "scheduled_task",
  "data": null,
  "error": "invalid cron expression: <details>",
  "meta": {}
}
```

#### Remove Task (DELETE /api/v1/tasks/{id})

**Success Response (204 No Content):** Empty body

### 3.3 Task Storage (Crontab)

Tasks are stored in a crontab file with the following format:

```
<cron_expression> <user> <command> 2>&1 | tee -a <log_path> # <uuid>
```

Example:
```
* * * * * root /app/cli start-game 1 2>&1 | tee -a /tmp/log # 00000000-0000-0000-0000-000000000001
*/5 * * * * root /app/cli start-game room123 2>&1 | tee -a /tmp/log # 550e8400-e29b-41d4-a716-446655440000
```

**Storage Operations:**
- **Write**: Append new entries to the crontab file
- **Read**: Parse all entries from the crontab file
- **Find by ID**: Locate a specific entry by its UUID
- **Delete**: Remove an entry by UUID and rewrite the file

### 3.4 Validation Requirements

**Schedule Task Validation:**
- `task_id` must reference an existing/available task
- `scheduled_time` must be a valid cron expression (use the parser from Phase 1)
- `args` must be valid for the specified task

### 3.5 Error Handling

The API must return appropriate HTTP status codes:

| Status | Scenario |
|--------|----------|
| 200 | Successful GET request |
| 202 | Task scheduled successfully |
| 204 | Task removed successfully |
| 400 | Invalid JSON in request body |
| 422 | Validation error (invalid cron, unknown task) |
| 500 | Internal server error |

### 3.6 Web Application Test Requirements

Implement tests covering:

**Health Check Handler:**
- Returns status "OK"

**Get Scheduled Tasks Handler:**
- Returns list of scheduled tasks
- Handles errors gracefully
- Returns empty array when no tasks scheduled

**Get Available Tasks Handler:**
- Returns list of available commands
- Handles empty command registry

**Schedule Task Handler:**
- Successfully schedules a task with valid input
- Returns 400 for invalid JSON
- Returns 422 for unknown task_id
- Returns 422 for invalid cron expression
- Returns 500 for write failures
- Rejects unknown fields in request body
- Handles empty request body

**Remove Task Handler:**
- Successfully removes task with valid ID
- Returns 400 for invalid UUID format

**Integration Tests:**
- Full request/response cycle for each endpoint
- Database/file system state verification

## Phase 4: CLI Interface (Optional Extension)

After completing the web application, you may implement a CLI interface.

### 4.1 CLI Commands

| Command | Arguments | Description |
|---------|-----------|-------------|
| `schedule-task` | `<cron_expr> <command>` | Schedule a task via CLI |
| `start-game` | `<room_id>` | Execute start game task |
| `list-tasks` | | List scheduled tasks |
| `remove-task` | `<task_id>` | Remove a scheduled task |

### 4.2 CLI Schedule Task

Example usage:
```bash
cli schedule-task "*/15 * * * *" "start-game 123"
```

This should:
1. Parse and validate the cron expression
2. Validate the command exists
3. Write to the crontab file with a generated UUID

## Test Suite Checklist

Use this checklist to verify your implementation:

### Parser Tests
- [ ] Wildcard parsing for all 5 fields
- [ ] Range parsing (ordered and unordered)
- [ ] List parsing (2+ items, unordered, duplicates)
- [ ] Divisor parsing (*/n for various n)
- [ ] Single value parsing
- [ ] Full expression parsing
- [ ] Error: Too few parts
- [ ] Error: Too many parts
- [ ] Error: Double spaces
- [ ] Error: Invalid characters
- [ ] Error: Empty input
- [ ] Error: Out of bounds values
- [ ] Edge case: Zero values
- [ ] Edge case: Large lists
- [ ] Edge case: Divisor by one
- [ ] Edge case: Full range

### API Handler Tests
- [ ] Health check returns OK
- [ ] Get scheduled tasks - success
- [ ] Get scheduled tasks - error handling
- [ ] Get scheduled tasks - empty array
- [ ] Get available tasks - with tasks
- [ ] Get available tasks - empty
- [ ] Schedule task - success
- [ ] Schedule task - invalid JSON
- [ ] Schedule task - command not found
- [ ] Schedule task - invalid cron
- [ ] Schedule task - write failure
- [ ] Schedule task - unknown fields
- [ ] Schedule task - empty body
- [ ] Remove task - success
- [ ] Remove task - invalid ID

### Crontab Manager Tests
- [ ] Write entry to crontab file
- [ ] Read all entries from crontab file
- [ ] Find entry by ID
- [ ] Delete entry by ID

### E2E Tests
- [ ] Health check endpoint
- [ ] Get scheduled tasks (empty)
- [ ] Schedule task
- [ ] Delete task
- [ ] Invalid cron error
- [ ] Invalid task_id error

### Docker Tests
- [ ] Docker image builds successfully
- [ ] Container starts with cron daemon running
- [ ] CLI binary is executable in container
- [ ] Server binary is executable in container
- [ ] Crontab directory is writable
- [ ] Port 3000 is exposed and accessible
- [ ] Environment variables are properly passed
- [ ] Startup script executes without errors

## Implementation Guidelines

### Order of Implementation

1. **Start with the parser** - This is a self-contained component with clear inputs/outputs
2. **Create Docker setup** - Package the application for consistent deployment
3. **Implement crontab storage** - File-based operations for task persistence
4. **Build HTTP handlers** - Start with health check, then list, schedule, and remove endpoints
5. **Add CLI interface** - Optional but useful for testing and direct usage

### Design Principles

1. **Separation of Concerns** - Keep parser, storage, and HTTP layers separate
2. **Error Propagation** - Define clear error types that can be translated to HTTP status codes
3. **Input Validation** - Validate at the edges (HTTP handlers) and business logic layer
4. **Testability** - Use dependency injection and interfaces for testable code
5. **Idempotency** - DELETE operations should be idempotent (no error if already deleted)

### Data Flow

```
HTTP Request
    ↓
Handler (validation, JSON parsing)
    ↓
Resource/Service Layer (business logic)
    ↓
Crontab Manager (persistence)
    ↓
File System (crontab file)
```

### Suggested Project Structure

```
coco-task/
├── parser/           # Cron expression parser
│   ├── parser.*
│   ├── operators.*
│   └── errors.*
├── storage/          # Crontab file operations
│   ├── manager.*
│   └── entry.*
├── api/              # HTTP API
│   ├── handlers.*
│   ├── routes.*
│   └── dto.*
├── cli/              # CLI commands (optional)
│   └── commands.*
└── tests/            # Test suites
    ├── parser/
    ├── api/
    └── e2e/
```

## Example Cron Expressions for Testing

| Expression | Description |
|------------|-------------|
| `* * * * *` | Every minute |
| `*/15 * * * *` | Every 15 minutes |
| `0 0 * * *` | Daily at midnight |
| `0 12 * * 1` | Weekly on Monday at noon |
| `*/5 */6 */7 */8 1-5` | Complex expression with all operators |
| `1,15,30,45 0,12 1,15 * 1-5` | List values across all fields |
