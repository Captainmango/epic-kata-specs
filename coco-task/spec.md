# coco-task Specification

coco-task is a cron expression parser and task scheduler with HTTP API and CLI interfaces.

## System Behaviors

### Core Capabilities

1. **Cron Parsing** - Parse and validate 5-field cron expressions
2. **Task Scheduling** - Schedule tasks to run at specified intervals
3. **Task Management** - List, add, and remove scheduled tasks
4. **Task Execution** - Execute scheduled commands at appropriate times

## Cron Expression Format

### Field Structure

Standard 5-field cron expressions:

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

### Supported Operators

| Operator | Symbol | Description | Example |
|----------|--------|-------------|---------|
| Wildcard | `*` | Matches all values in range | `*` in minute = all 60 minutes |
| Single Value | (number) | Specific number | `30` = only minute 30 |
| Range | `-` | Inclusive range | `1-5` = 1, 2, 3, 4, 5 |
| List | `,` | Comma-separated values | `1,15,30` = minutes 1, 15, and 30 |
| Step/Divisor | `/` | Step values from wildcard | `*/15` = every 15 minutes (0, 15, 30, 45) |

### Parser Input/Output

**Input Formats:**
- String: `"*/15 * * * *"`
- String Array: `["*", "*", "*", "*", "*"]`

**Output Requirements:**

1. **Possible Values Mode** - Expands expression to show all matching values:
   ```
   Minute     | 0, 15, 30, 45
   Hour       | 0, 1, 2, 3, ... 23
   Day        | 1, 2, 3, ... 31
   Month      | 1, 2, 3, ... 12
   Weekday    | 1, 2, 3, 4, 5, 6, 7
   ```

2. **Raw Expression Mode** - Returns original expression

### Parser Error Handling

Must validate and return errors for:
- Too few expression parts (less than 5)
- Too many expression parts (more than 5)
- Double spaces in expression
- Invalid characters in expression
- Empty input
- Values out of bounds for each field
- Invalid operator combinations

## Data Contracts

### Task Definition

```json
{
  "id": "start-game",
  "name": "Start Game",
  "description": "Sends a start game message"
}
```

### Scheduled Task

```json
{
  "id": "uuid-here",
  "command": "start-game room123",
  "cron": "* * * * *"
}
```

### Schedule Request

```json
{
  "task_id": "start-game",
  "scheduled_time": "*/5 * * * *",
  "args": {
    "room_id": "room123"
  }
}
```

### Standard Response Format

```json
{
  "type": "response_type",
  "data": { },
  "error": "",
  "meta": {}
}
```

## API Behaviors

### HTTP Endpoints

| Method | Endpoint | Behavior |
|--------|----------|----------|
| GET | `/api/v1/livez` | Health check |
| GET | `/api/v1/tasks` | List available tasks |
| GET | `/api/v1/tasks/scheduled` | List scheduled tasks |
| POST | `/api/v1/tasks` | Schedule a new task |
| DELETE | `/api/v1/tasks/{id}` | Remove a scheduled task |

#### Health Check

**Success Response:**
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

#### List Available Tasks

Returns all tasks/commands that can be scheduled.

**Success Response:**
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

#### List Scheduled Tasks

Returns all currently scheduled tasks.

**Success Response:**
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

#### Schedule Task

**Request Body:**
```json
{
  "task_id": "start-game",
  "scheduled_time": "*/5 * * * *",
  "args": {
    "room_id": "room123"
  }
}
```

**Validation Requirements:**
- `task_id` must reference an existing/available task
- `scheduled_time` must be valid cron expression
- `args` must be valid for specified task

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

#### Remove Task

**Success Response:** 204 No Content (empty body)

**Error Response (400 Bad Request):** Invalid UUID format

## Task Storage Behaviors

### Crontab Storage Format

Tasks are stored in a crontab file:

```
<cron_expression> <user> <command> 2>&1 | tee -a <log_path> # <uuid>
```

Example:
```
* * * * * root /app/cli start-game 1 2>&1 | tee -a /tmp/log # 00000000-0000-0000-0000-000000000001
*/5 * * * * root /app/cli start-game room123 2>&1 | tee -a /tmp/log # 550e8400-e29b-41d4-a716-446655440000
```

### Storage Operations

- **Write**: Append new entries to crontab file
- **Read**: Parse all entries from crontab file
- **Find by ID**: Locate specific entry by UUID
- **Delete**: Remove entry by UUID and rewrite file

### Storage Requirements

- Each scheduled task has unique UUID
- Crontab file location is configurable
- File permissions must allow read/write
- Format compatible with standard cron daemon

## Task Execution Behaviors

### Execution Model

1. Cron daemon monitors crontab file
2. At scheduled times, daemon triggers task execution
3. Task executor runs specified command with arguments
4. Output is logged to configured log path

### Command Resolution

- Commands reference task definitions
- Arguments are passed to command in order
- Commands exit with appropriate status codes

## HTTP Status Codes

| Status | Scenario |
|--------|----------|
| 200 | Successful GET request |
| 202 | Task scheduled successfully |
| 204 | Task removed successfully |
| 400 | Invalid JSON in request body |
| 422 | Validation error (invalid cron, unknown task) |
| 500 | Internal server error |

## CLI Behaviors (Optional)

### Supported Commands

| Command | Arguments | Behavior |
|---------|-----------|----------|
| `schedule-task` | `<cron_expr> <command>` | Schedule task via CLI |
| `start-game` | `<room_id>` | Execute start game task |
| `list-tasks` | | List scheduled tasks |
| `remove-task` | `<task_id>` | Remove scheduled task |

### CLI Schedule Task Behavior

1. Parse and validate cron expression
2. Validate command exists
3. Write to crontab file with generated UUID

Example: `cli schedule-task "*/15 * * * *" "start-game 123"`

## Deployment Requirements

### Container Requirements

- HTTP API exposed on configurable port (default: 3000)
- Cron daemon running for task scheduling
- Crontab directory at configurable location
- Writable crontab file location
- CLI binary accessible for task execution

### Environment Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `HTTP_PORT` | HTTP API port | 3000 |
| `CRONTAB_FILE` | Crontab file path | /etc/cron.d/root |

### Multi-Stage Build Requirements

- Builder stage compiles application binaries
- Runtime stage is minimal with only runtime dependencies
- Cron daemon installed in runtime
- Both CLI and server binaries included

## Test Suite Checklist

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

### Deployment Tests
- [ ] Container builds successfully
- [ ] Cron daemon starts and runs
- [ ] CLI binary is executable
- [ ] Server binary is executable
- [ ] Crontab directory is writable
- [ ] Port 3000 is exposed and accessible
- [ ] Environment variables properly passed

## Design Principles

1. **Separation of Concerns** - Parser, storage, and HTTP layers are independent
2. **Error Propagation** - Clear error types translatable to HTTP status codes
3. **Input Validation** - Validate at edges (HTTP handlers) and business logic
4. **Testability** - Use dependency injection and interfaces for testable code
5. **Idempotency** - DELETE operations should be idempotent

## Implementation Order

1. **Cron Parser** - Self-contained component with clear inputs/outputs
2. **Task Storage** - File-based operations for task persistence
3. **HTTP API** - Health check, then list, schedule, and remove endpoints
4. **Task Scheduler Integration** - Connect to cron daemon
5. **CLI Interface** - Optional but useful for direct usage

## Example Cron Expressions

| Expression | Description |
|------------|-------------|
| `* * * * *` | Every minute |
| `*/15 * * * *` | Every 15 minutes |
| `0 0 * * *` | Daily at midnight |
| `0 12 * * 1` | Weekly on Monday at noon |
| `*/5 */6 */7 */8 1-5` | Complex expression with all operators |
| `1,15,30,45 0,12 1,15 * 1-5` | List values across all fields |
