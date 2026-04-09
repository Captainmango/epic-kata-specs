# blogga Specification

blogga is a blogging platform API that manages posts and comments with a focus on content management.

## System Behaviors

### Core Capabilities

1. **Post Management** - Create, read, update, and delete blog posts
2. **Comment Management** - Create, read, and delete comments on posts
3. **Nested Resource Access** - Access comments through their parent posts
4. **Data Validation** - Ensure required fields are present and valid

## Data Contracts

### Post Object

```json
{
  "id": 1,
  "title": "My Awesome Post",
  "body": "This is the content of my blog post.",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

Fields:
- `id`: Unique identifier for the post (integer or string)
- `title`: Post title (string, max length 75 characters)
- `body`: Post content (text)
- `createdAt`: ISO 8601 timestamp of creation
- `updatedAt`: ISO 8601 timestamp of last modification

### Comment Object

```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "content": "Great post! Thanks for sharing.",
  "createdAt": "2024-01-15T11:00:00.000Z",
  "updatedAt": "2024-01-15T11:00:00.000Z"
}
```

Fields:
- `id`: Unique identifier for the comment (integer or string)
- `name`: Commenter's name (string)
- `email`: Commenter's email address (string)
- `content`: Comment content (text)
- `createdAt`: ISO 8601 timestamp of creation
- `updatedAt`: ISO 8601 timestamp of last modification

### Error Response

```json
{
  "message": "Human-readable error message"
}
```

## API Behaviors

### HTTP Endpoints

| Method | Endpoint | Behavior |
|--------|----------|----------|
| GET | `/` | Health check / API index |
| GET | `/posts` | List all posts |
| GET | `/posts/{post_id}` | Retrieve a single post |
| POST | `/posts` | Create a new post |
| PATCH | `/posts/{post_id}` | Update a post |
| DELETE | `/posts/{post_id}` | Delete a post |
| GET | `/comments` | List all comments |
| GET | `/comments/{comment_id}` | Retrieve a single comment |
| DELETE | `/comments/{comment_id}` | Delete a comment |
| POST | `/posts/{post_id}/comments` | Create a comment for a post |
| PATCH | `/posts/{post_id}/comments/{comment_id}` | Update a post's comment |

#### Health Check / Index

**Behavior:**
- Returns a welcome message indicating the API is running

**Success Response (200 OK):**
```json
{
  "message": "Welcome to the Blogga API"
}
```

#### List Posts

**Behavior:**
- Returns an array of all posts
- Posts should include all fields except nested comments (optional)

**Success Response (200 OK):**
```json
[
  {
    "id": 1,
    "title": "First Post",
    "body": "Content here",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "updatedAt": "2024-01-15T10:30:00.000Z"
  },
  {
    "id": 2,
    "title": "Second Post",
    "body": "More content",
    "createdAt": "2024-01-15T11:00:00.000Z",
    "updatedAt": "2024-01-15T11:00:00.000Z"
  }
]
```

#### Get Post

**Behavior:**
- Returns a single post by ID
- Returns 404 if post does not exist

**Success Response (200 OK):**
```json
{
  "id": 1,
  "title": "My Post",
  "body": "Post content here",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "message": "Post not found"
}
```

#### Create Post

**Request Body:**
```json
{
  "title": "My New Post",
  "body": "This is the content of my new blog post."
}
```

Required fields:
- `title`: Post title
- `body`: Post content

**Behavior:**
- Creates a new post with the provided data
- Assigns a unique ID
- Sets createdAt and updatedAt timestamps

**Success Response (201 Created):**
```json
{
  "id": 1,
  "title": "My New Post",
  "body": "This is the content of my new blog post.",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

#### Update Post

**Request Body:**
```json
{
  "title": "Updated Title",
  "body": "Updated content"
}
```

Request fields (at least one required):
- `title`: New post title (optional)
- `body`: New post content (optional)

**Behavior:**
- Updates the specified post with provided fields
- Only updates fields that are provided
- Updates the updatedAt timestamp
- Returns 404 if post does not exist

**Success Response (200 OK):**
```json
{
  "id": 1,
  "title": "Updated Title",
  "body": "Updated content",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T12:00:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "message": "Post not found"
}
```

#### Delete Post

**Behavior:**
- Deletes the specified post
- Returns 204 No Content on success
- Returns 404 if post does not exist
- Associated comments may be deleted or orphaned based on implementation

**Success Response:** 204 No Content (empty body)

**Error Response (404 Not Found):**
```json
{
  "message": "Post not found"
}
```

#### List Comments

**Behavior:**
- Returns an array of all comments
- Comments should include all fields

**Success Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "content": "Great post!",
    "createdAt": "2024-01-15T11:00:00.000Z",
    "updatedAt": "2024-01-15T11:00:00.000Z"
  }
]
```

#### Get Comment

**Behavior:**
- Returns a single comment by ID
- Returns 404 if comment does not exist

**Success Response (200 OK):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "content": "Great post!",
  "createdAt": "2024-01-15T11:00:00.000Z",
  "updatedAt": "2024-01-15T11:00:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "message": "Comment not found"
}
```

#### Delete Comment

**Behavior:**
- Deletes the specified comment
- Returns 204 No Content on success
- Returns 404 if comment does not exist

**Success Response:** 204 No Content (empty body)

**Error Response (404 Not Found):**
```json
{
  "message": "Comment not found"
}
```

#### Create Comment (Nested)

**Request Body:**
```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "content": "Thanks for this informative post!"
}
```

Required fields:
- `name`: Commenter's name
- `email`: Commenter's email address
- `content`: Comment content

**Behavior:**
- Creates a new comment associated with the specified post
- Returns 404 if the post does not exist
- Assigns a unique ID
- Sets createdAt and updatedAt timestamps

**Success Response (201 Created):**
```json
{
  "id": 1,
  "name": "Jane Smith",
  "email": "jane@example.com",
  "content": "Thanks for this informative post!",
  "createdAt": "2024-01-15T11:00:00.000Z",
  "updatedAt": "2024-01-15T11:00:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "message": "Post not found"
}
```

#### Update Comment (Nested)

**Request Body:**
```json
{
  "name": "Updated Name",
  "email": "updated@example.com",
  "content": "Updated comment content"
}
```

Request fields (at least one required):
- `name`: New commenter name (optional)
- `email`: New email address (optional)
- `content`: New comment content (optional)

**Behavior:**
- Updates the specified comment
- Verifies the comment belongs to the specified post
- Returns 404 if the post does not exist
- Returns 404 if the comment does not exist or doesn't belong to the post
- Updates the updatedAt timestamp

**Success Response (202 Accepted):**
```json
{
  "id": 1,
  "name": "Updated Name",
  "email": "updated@example.com",
  "content": "Updated comment content",
  "createdAt": "2024-01-15T11:00:00.000Z",
  "updatedAt": "2024-01-15T12:00:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "message": "Post not found"
}
```

or

```json
{
  "message": "Comment not found"
}
```

## HTTP Status Codes

| Status | Scenario |
|--------|----------|
| 200 | Successful GET or PATCH request |
| 201 | Resource created successfully (POST) |
| 202 | Resource updated successfully (PATCH on nested resource) |
| 204 | Resource deleted successfully |
| 404 | Resource not found |
| 500 | Internal server error |

## Persistence Behaviors

### Storage Requirements

- Post and comment data must be persisted across restarts
- IDs must remain stable after creation
- Timestamps must be preserved
- Comment-post relationships must be maintained

### Storage Options

Implementations may use any storage backend:
- Relational database (PostgreSQL, MySQL, SQLite)
- Document store (MongoDB)
- In-memory with file persistence
- Key-value store

## Design Principles

1. **RESTful Design** - Resources are nouns, HTTP methods define actions
2. **Consistent Responses** - Same data structure for same resource types
3. **Proper Status Codes** - Use appropriate HTTP status codes for each scenario
4. **Resource Validation** - Verify nested resources belong to parent resources
5. **Graceful Errors** - Return meaningful error messages for failures

## Test Suite Checklist

### Post API Tests
- [ ] Health check returns welcome message
- [ ] List posts returns array of posts
- [ ] Get post returns single post
- [ ] Get post returns 404 for non-existent post
- [ ] Create post returns 201 with created post
- [ ] Create post persists data correctly
- [ ] Update post returns updated post
- [ ] Update post returns 404 for non-existent post
- [ ] Delete post returns 204
- [ ] Delete post returns 404 for non-existent post

### Comment API Tests
- [ ] List comments returns array of comments
- [ ] Get comment returns single comment
- [ ] Get comment returns 404 for non-existent comment
- [ ] Delete comment returns 204
- [ ] Delete comment returns 404 for non-existent comment

### Nested Resource Tests
- [ ] Create comment via nested route returns 201
- [ ] Create comment returns 404 if post doesn't exist
- [ ] Update comment via nested route returns 202
- [ ] Update comment returns 404 if post doesn't exist
- [ ] Update comment returns 404 if comment doesn't belong to post

### E2E Tests
- [ ] Full flow: Create post → Get post → Update post → Delete post
- [ ] Full flow: Create post → Add comment → Get comment → Delete comment → Delete post
- [ ] Full flow: Create post → Add multiple comments → List comments → Delete post

## Example Usage

### Create a Post

```bash
curl -X POST http://localhost:3000/posts \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My First Blog Post",
    "body": "This is the content of my first blog post. Welcome to my blog!"
  }'
```

### Get All Posts

```bash
curl -X GET http://localhost:3000/posts
```

### Update a Post

```bash
curl -X PATCH http://localhost:3000/posts/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Blog Post Title"
  }'
```

### Delete a Post

```bash
curl -X DELETE http://localhost:3000/posts/1
```

### Create a Comment on a Post

```bash
curl -X POST http://localhost:3000/posts/1/comments \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "content": "Great post! Looking forward to more content."
  }'
```

### Update a Comment

```bash
curl -X PATCH http://localhost:3000/posts/1/comments/1 \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Updated comment content"
  }'
```

### Delete a Comment

```bash
curl -X DELETE http://localhost:3000/comments/1
```
