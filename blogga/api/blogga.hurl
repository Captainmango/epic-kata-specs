# Health check / Index
GET {{ host }}/
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.message" exists

# Create a new post
POST {{ host }}/posts
Content-Type: application/json
{
  "title": "My First Blog Post",
  "body": "This is the content of my first blog post."
}
HTTP 201
[Captures]
post_id: jsonpath "$.id"
[Asserts]
jsonpath "$.id" exists
jsonpath "$.title" == "My First Blog Post"
jsonpath "$.body" == "This is the content of my first blog post."
jsonpath "$.createdAt" exists
jsonpath "$.updatedAt" exists

# List all posts
GET {{ host }}/posts
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$" isArray
jsonpath "$[0].id" exists
jsonpath "$[0].title" exists
jsonpath "$[0].body" exists

# Get a single post
GET {{ host }}/posts/{{ post_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.id" == {{ post_id }}
jsonpath "$.title" == "My First Blog Post"
jsonpath "$.body" == "This is the content of my first blog post."

# Get post returns 404 for non-existent post
GET {{ host }}/posts/999999
Content-Type: application/json
HTTP 404
[Asserts]
jsonpath "$.message" exists

# Update a post
PATCH {{ host }}/posts/{{ post_id }}
Content-Type: application/json
{
  "title": "Updated Blog Post Title",
  "body": "Updated blog post content."
}
HTTP 200
[Asserts]
jsonpath "$.id" == {{ post_id }}
jsonpath "$.title" == "Updated Blog Post Title"
jsonpath "$.body" == "Updated blog post content."
jsonpath "$.updatedAt" exists

# Update post returns 404 for non-existent post
PATCH {{ host }}/posts/999999
Content-Type: application/json
{
  "title": "This should not work"
}
HTTP 404
[Asserts]
jsonpath "$.message" exists

# Create a second post
POST {{ host }}/posts
Content-Type: application/json
{
  "title": "Second Post",
  "body": "Content for the second post."
}
HTTP 201
[Captures]
post_id_2: jsonpath "$.id"
[Asserts]
jsonpath "$.id" exists

# Create a comment on the first post
POST {{ host }}/posts/{{ post_id }}/comments
Content-Type: application/json
{
  "name": "John Doe",
  "email": "john@example.com",
  "content": "Great post! Thanks for sharing."
}
HTTP 201
[Captures]
comment_id: jsonpath "$.id"
[Asserts]
jsonpath "$.id" exists
jsonpath "$.name" == "John Doe"
jsonpath "$.email" == "john@example.com"
jsonpath "$.content" == "Great post! Thanks for sharing."
jsonpath "$.createdAt" exists
jsonpath "$.updatedAt" exists

# Create comment returns 404 if post doesn't exist
POST {{ host }}/posts/999999/comments
Content-Type: application/json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "content": "This should not work."
}
HTTP 404
[Asserts]
jsonpath "$.message" exists

# Create another comment on the first post
POST {{ host }}/posts/{{ post_id }}/comments
Content-Type: application/json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "content": "Thanks for this informative post!"
}
HTTP 201
[Captures]
comment_id_2: jsonpath "$.id"
[Asserts]
jsonpath "$.id" exists

# List all comments
GET {{ host }}/comments
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$" isArray
jsonpath "$[0].id" exists
jsonpath "$[0].name" exists
jsonpath "$[0].email" exists
jsonpath "$[0].content" exists

# Get a single comment
GET {{ host }}/comments/{{ comment_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.id" == {{ comment_id }}
jsonpath "$.name" == "John Doe"
jsonpath "$.email" == "john@example.com"
jsonpath "$.content" == "Great post! Thanks for sharing."

# Get comment returns 404 for non-existent comment
GET {{ host }}/comments/999999
Content-Type: application/json
HTTP 404
[Asserts]
jsonpath "$.message" exists

# Update a comment via nested route
PATCH {{ host }}/posts/{{ post_id }}/comments/{{ comment_id }}
Content-Type: application/json
{
  "name": "John Updated",
  "email": "john.updated@example.com",
  "content": "Updated comment content."
}
HTTP 202
[Asserts]
jsonpath "$.id" == {{ comment_id }}
jsonpath "$.name" == "John Updated"
jsonpath "$.email" == "john.updated@example.com"
jsonpath "$.content" == "Updated comment content."

# Update comment returns 404 if post doesn't exist
PATCH {{ host }}/posts/999999/comments/{{ comment_id }}
Content-Type: application/json
{
  "content": "This should not work."
}
HTTP 404
[Asserts]
jsonpath "$.message" exists

# Update comment returns 404 if comment doesn't belong to post
PATCH {{ host }}/posts/{{ post_id_2 }}/comments/{{ comment_id }}
Content-Type: application/json
{
  "content": "This should not work - comment belongs to different post."
}
HTTP 404
[Asserts]
jsonpath "$.message" exists

# Delete a comment
DELETE {{ host }}/comments/{{ comment_id_2 }}
HTTP 204

# Delete comment returns 404 for non-existent comment
DELETE {{ host }}/comments/999999
HTTP 404
[Asserts]
jsonpath "$.message" exists

# Delete the first post
DELETE {{ host }}/posts/{{ post_id }}
HTTP 204

# Delete post returns 404 for non-existent post
DELETE {{ host }}/posts/999999
HTTP 404
[Asserts]
jsonpath "$.message" exists

# Delete the second post
DELETE {{ host }}/posts/{{ post_id_2 }}
HTTP 204

# Verify posts are deleted - list should be empty or not contain deleted posts
GET {{ host }}/posts
Content-Type: application/json
HTTP 200
