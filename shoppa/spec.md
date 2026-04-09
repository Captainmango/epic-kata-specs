# shoppa Specification

shoppa is an e-commerce platform API that manages products, categories, shopping carts, and orders with a focus on inventory safety and concurrency control.

## System Behaviors

### Core Capabilities

1. **Product Management** - Browse and search products with inventory tracking and soft delete support
2. **Category Management** - Organize products into categories for discovery
3. **Cart Management** - Add, update, and remove items from a user's shopping cart with stock validation
4. **Order Management** - Place orders from cart contents and manage order lifecycle with atomic stock operations
5. **Inventory Management** - Track stock levels and prevent overselling through robust concurrency control
6. **API Documentation** - Auto-generated interactive API documentation

## Technical Requirements

### Data Validation

All request inputs must be validated and sanitized:
- Use DTOs (Data Transfer Objects) for all request bodies
- Validate data types, required fields, and value constraints
- Reject negative quantities and invalid IDs
- Return clear validation error messages

### API Documentation

The API must provide auto-generated documentation:
- Interactive documentation accessible at `/api` or `/api/docs`
- OpenAPI/Swagger specification generated from code
- Document all endpoints, request/response schemas, and error cases
- Include example requests and responses

### Persistence Options

Implementations must use one of the following storage backends:
- **SQLite** - File-based relational database (good for development/testing)
- **MySQL** - Popular open-source relational database
- **PostgreSQL** - Advanced relational database with robust concurrency features

The choice should consider the concurrency requirements for stock management.

## Data Contracts

### Product Object

```json
{
  "id": 1,
  "name": "Organic Bananas",
  "quantity": 50,
  "categories": ["Fruits", "Organic"],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z",
  "deletedAt": null
}
```

Fields:
- `id`: Unique identifier for the product (integer)
- `name`: Product name (string)
- `quantity`: Available stock quantity (integer, must be >= 0)
- `categories`: Array of category names the product belongs to (optional)
- `createdAt`: ISO 8601 timestamp of creation
- `updatedAt`: ISO 8601 timestamp of last modification
- `deletedAt`: ISO 8601 timestamp when product was soft deleted, or null if active

**Soft Delete Behavior:**
- When a product is "deleted", it receives a `deletedAt` timestamp
- Soft deleted products do not appear in public product lists (`GET /products`, `GET /categories/:id/products`)
- Soft deleted products remain accessible via direct ID lookup (`GET /products/:id`) for order history
- Past orders containing deleted products remain valid and viewable

### Category Object

```json
{
  "id": 1,
  "name": "Fruits",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

Fields:
- `id`: Unique identifier for the category (integer)
- `name`: Category name (string)
- `createdAt`: ISO 8601 timestamp of creation
- `updatedAt`: ISO 8601 timestamp of last modification

### Cart Object

```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 2
    }
  ],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

Fields:
- `id`: Unique identifier for the cart (integer)
- `products`: Array of products in the cart, each with quantity
- `createdAt`: ISO 8601 timestamp of creation
- `updatedAt`: ISO 8601 timestamp of last modification

### Cart Item Object

```json
{
  "productId": 1,
  "quantity": 2
}
```

Fields:
- `productId`: ID of the product to add (integer, must be >= 1)
- `quantity`: Quantity to add (integer, must be >= 1)

**Validation Rules:**
- `productId`: Must be a positive integer
- `quantity`: Must be a positive integer (>= 1), no negative or zero quantities allowed

### Order Object

```json
{
  "id": 1,
  "status": "PENDING",
  "products": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 2
    }
  ],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

Fields:
- `id`: Unique identifier for the order (integer)
- `status`: Order status - one of `PENDING`, `CONFIRMED`, `CANCELLED` (string)
- `products`: Array of products in the order, each with quantity
- `createdAt`: ISO 8601 timestamp of creation
- `updatedAt`: ISO 8601 timestamp of last modification

### User Object

```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

Fields:
- `id`: Unique identifier for the user (integer)
- `name`: User's full name (string)
- `email`: User's email address (string)
- `createdAt`: ISO 8601 timestamp of creation
- `updatedAt`: ISO 8601 timestamp of last modification

### Error Response

```json
{
  "type": "error_type",
  "message": "Human-readable error message"
}
```

Fields:
- `type`: Error type identifier (string)
- `message`: Human-readable error description (string)

**Stock Error with Details:**
```json
{
  "type": "InsufficientStock",
  "message": "Not enough stock for one or more items",
  "details": [
    {
      "productId": 1,
      "productName": "Organic Bananas",
      "requested": 10,
      "available": 5
    }
  ]
}
```

### Paginated List Response

```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "pageSize": 10,
    "total": 100
  }
}
```

Fields:
- `data`: Array of items
- `pagination.page`: Current page number (integer, 1-based)
- `pagination.pageSize`: Number of items per page (integer)
- `pagination.total`: Total number of items available (integer)

## API Behaviors

### HTTP Endpoints

| Method | Endpoint | Behavior |
|--------|----------|----------|
| GET | `/` | Health check / API index |
| GET | `/products` | List all products with pagination |
| GET | `/products/{id}` | Retrieve a single product (including soft-deleted) |
| GET | `/categories` | List all categories with pagination |
| GET | `/categories/{id}/products` | List products in a category (excluding soft-deleted) |
| GET | `/carts/{userId}` | Retrieve a user's cart |
| POST | `/carts/{userId}/items` | Add item to user's cart (updates quantity if exists) |
| PUT | `/carts/{userId}/items/{productId}` | Update cart item quantity |
| DELETE | `/carts/{userId}/items/{productId}` | Remove item from cart |
| DELETE | `/carts/{userId}` | Clear user's cart |
| POST | `/orders` | Place an order from cart |
| GET | `/orders/{id}` | Retrieve a single order |
| POST | `/orders/{id}/cancel` | Cancel an order |
| GET | `/api` or `/api/docs` | API documentation (Swagger/OpenAPI) |

#### Health Check / Index

**Behavior:**
- Returns a welcome message indicating the API is running
- Provides link to API documentation

**Success Response (200 OK):**
```json
{
  "message": "Welcome to the Shoppa API",
  "documentation": "/api"
}
```

#### API Documentation

**Behavior:**
- Serves interactive API documentation
- Auto-generated from API code and annotations
- Includes all endpoints with request/response examples
- Allows testing endpoints directly from the documentation UI

**Access:**
- `GET /api` or `GET /api/docs` - Swagger UI
- `GET /api-json` - Raw OpenAPI JSON specification

#### List Products

**Query Parameters:**
- `page` (integer, optional): Page number, defaults to 1
- `pageSize` (integer, optional): Items per page, defaults to 20

**Behavior:**
- Returns a paginated list of all **active** (non-deleted) products
- Soft deleted products (where `deletedAt` is not null) are excluded
- Products include all fields
- Results are ordered by creation date (newest first)

**Success Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 50,
      "categories": ["Fruits"],
      "createdAt": "2024-01-15T10:30:00.000Z",
      "updatedAt": "2024-01-15T10:30:00.000Z",
      "deletedAt": null
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 100
  }
}
```

#### Get Product

**Behavior:**
- Returns a single product by ID
- Returns soft-deleted products (for order history viewing)
- Returns 404 if product does not exist

**Success Response (200 OK):**
```json
{
  "id": 1,
  "name": "Organic Bananas",
  "quantity": 50,
  "categories": ["Fruits"],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z",
  "deletedAt": null
}
```

**Success Response (200 OK - Soft Deleted):**
```json
{
  "id": 1,
  "name": "Organic Bananas",
  "quantity": 0,
  "categories": ["Fruits"],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z",
  "deletedAt": "2024-02-01T12:00:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "type": "ProductNotFound",
  "message": "Product not found"
}
```

#### List Categories

**Query Parameters:**
- `page` (integer, optional): Page number, defaults to 1
- `pageSize` (integer, optional): Items per page, defaults to 20

**Behavior:**
- Returns a paginated list of all categories

**Success Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Fruits",
      "createdAt": "2024-01-15T10:30:00.000Z",
      "updatedAt": "2024-01-15T10:30:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 10
  }
}
```

#### Get Products by Category

**Query Parameters:**
- `page` (integer, optional): Page number, defaults to 1
- `pageSize` (integer, optional): Items per page, defaults to 20

**Behavior:**
- Returns all **active** products belonging to the specified category
- Soft deleted products are excluded
- Returns 404 if category does not exist
- Results are paginated

**Success Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 50,
      "categories": ["Fruits"],
      "createdAt": "2024-01-15T10:30:00.000Z",
      "updatedAt": "2024-01-15T10:30:00.000Z",
      "deletedAt": null
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 25
  }
}
```

**Error Response (404 Not Found):**
```json
{
  "type": "CategoryNotFound",
  "message": "Category not found"
}
```

#### Get Cart

**Behavior:**
- Returns the user's current cart with all items
- Returns 404 if user does not exist
- Creates and returns empty cart if user has no cart yet

**Success Response (200 OK):**
```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 2
    }
  ],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "type": "UserNotFound",
  "message": "User not found"
}
```

#### Add Item to Cart

**Request Body:**
```json
{
  "productId": 1,
  "quantity": 2
}
```

Required fields:
- `productId`: ID of product to add (integer, >= 1)
- `quantity`: Quantity to add (integer, >= 1)

**Behavior:**
- Adds the specified product to the user's cart
- **If the product is already in the cart, updates the quantity** (adds to existing)
- Creates a new cart if user doesn't have one
- Returns 404 if user does not exist
- Returns 404 if product does not exist or is soft-deleted
- Returns 409 if insufficient stock available
- Updates cart's updatedAt timestamp

**Success Response (200 OK - New Item):**
```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 2
    }
  ],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:35:00.000Z"
}
```

**Success Response (200 OK - Updated Quantity):**
```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 5
    }
  ],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:40:00.000Z"
}
```

**Error Response (404 Not Found - User):**
```json
{
  "type": "UserNotFound",
  "message": "User not found"
}
```

**Error Response (404 Not Found - Product):**
```json
{
  "type": "ProductNotFound",
  "message": "Product not found"
}
```

**Error Response (409 Conflict - Insufficient Stock):**
```json
{
  "type": "InsufficientStock",
  "message": "Not enough stock available"
}
```

#### Update Cart Item

**Endpoint:** `PUT /carts/{userId}/items/{productId}`

**Request Body:**
```json
{
  "quantity": 3
}
```

Required fields:
- `quantity`: New quantity (integer, must be >= 1)

**Behavior:**
- Updates the quantity of a specific cart item (replaces existing quantity)
- `productId` in URL identifies which cart item to update
- Returns 404 if user does not exist
- Returns 404 if cart does not exist
- Returns 404 if product is not in cart
- Returns 409 if insufficient stock available
- Updates cart's updatedAt timestamp

**Success Response (200 OK):**
```json
{
  "id": 1,
  "products": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 3
    }
  ],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:40:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "type": "CartItemNotFound",
  "message": "Product not found in cart"
}
```

**Error Response (409 Conflict - Insufficient Stock):**
```json
{
  "type": "InsufficientStock",
  "message": "Not enough stock available"
}
```

#### Remove Item from Cart

**Endpoint:** `DELETE /carts/{userId}/items/{productId}`

**Behavior:**
- Removes a specific product from the user's cart
- `productId` in URL identifies which product to remove
- Returns 404 if user does not exist
- Returns 404 if cart does not exist
- Returns 404 if product is not in cart
- Returns the updated cart

**Success Response (200 OK):**
```json
{
  "id": 1,
  "products": [],
  "createdAt": "2024-01-15T10:30:00.000Z",
  "updatedAt": "2024-01-15T10:45:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "type": "CartItemNotFound",
  "message": "Product not found in cart"
}
```

#### Clear Cart

**Behavior:**
- Removes all items from the user's cart
- Returns 404 if user does not exist
- Returns 204 No Content on success

**Success Response:** 204 No Content (empty body)

**Error Response (404 Not Found):**
```json
{
  "type": "UserNotFound",
  "message": "User not found"
}
```

#### Place Order

**Request Body:**
```json
{
  "userId": 1
}
```

Required fields:
- `userId`: ID of user placing the order (integer, >= 1)

**Behavior:**
- Creates a new order from the user's current cart contents
- **Must be atomic** - validates and reserves stock for all items in a single transaction
- Decrements product stock quantities
- Clears the user's cart after successful order creation
- Sets order status to `PENDING`
- Returns 404 if user does not exist
- Returns 404 if cart does not exist
- Returns 409 if cart is empty
- Returns 400 if insufficient stock for any item (with details)
- No stock changes should occur if any item fails validation

**Success Response (201 Created):**
```json
{
  "id": 1,
  "status": "PENDING",
  "products": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 2
    }
  ],
  "createdAt": "2024-01-15T10:50:00.000Z",
  "updatedAt": "2024-01-15T10:50:00.000Z"
}
```

**Error Response (404 Not Found - User):**
```json
{
  "type": "UserNotFound",
  "message": "User not found"
}
```

**Error Response (404 Not Found - Cart):**
```json
{
  "type": "CartNotFound",
  "message": "Cart not found"
}
```

**Error Response (409 Conflict - Empty Cart):**
```json
{
  "type": "CartEmpty",
  "message": "Cart is empty"
}
```

**Error Response (400 Bad Request - Insufficient Stock):**
```json
{
  "type": "InsufficientStock",
  "message": "Not enough stock for one or more items",
  "details": [
    {
      "productId": 1,
      "productName": "Organic Bananas",
      "requested": 10,
      "available": 5
    },
    {
      "productId": 2,
      "productName": "Whole Milk",
      "requested": 3,
      "available": 0
    }
  ]
}
```

#### Get Order

**Behavior:**
- Returns a single order by ID
- Includes products that may have been soft-deleted since order creation
- Returns 404 if order does not exist

**Success Response (200 OK):**
```json
{
  "id": 1,
  "status": "PENDING",
  "products": [
    {
      "id": 1,
      "name": "Organic Bananas",
      "quantity": 2
    }
  ],
  "createdAt": "2024-01-15T10:50:00.000Z",
  "updatedAt": "2024-01-15T10:50:00.000Z"
}
```

**Error Response (404 Not Found):**
```json
{
  "type": "OrderNotFound",
  "message": "Order not found"
}
```

#### Cancel Order

**Behavior:**
- Cancels an existing order
- Sets order status to `CANCELLED`
- **Restores product stock quantities** for all items in the order
- Returns 404 if order does not exist
- Returns 409 if order is already cancelled

**Success Response:** 204 No Content (empty body)

**Error Response (404 Not Found):**
```json
{
  "type": "OrderNotFound",
  "message": "Order not found"
}
```

**Error Response (409 Conflict):**
```json
{
  "type": "OrderAlreadyCancelled",
  "message": "Order is already cancelled"
}
```

## HTTP Status Codes

| Status | Scenario |
|--------|----------|
| 200 | Successful GET, PUT, or POST request (non-resource creation) |
| 201 | Resource created successfully (POST for orders) |
| 204 | Resource deleted successfully or action completed |
| 400 | Bad request - validation errors or insufficient stock for order placement |
| 404 | Resource not found |
| 409 | Conflict - business rule violation (empty cart, already cancelled, insufficient stock for cart) |
| 422 | Validation error - invalid input data (negative quantities, invalid types) |
| 500 | Internal server error |

## Persistence Behaviors

### Storage Requirements

- Product data must be persisted across restarts
- Category data must be persisted across restarts
- Cart data must be persisted across restarts (in database, not Redis or in-memory)
- Order data must be persisted across restarts
- User data must be persisted across restarts
- IDs must remain stable after creation
- Timestamps must be preserved
- Stock quantities must be accurately maintained
- Soft delete state (`deletedAt`) must be preserved

### Supported Databases

Implementations must use one of:
- **SQLite** - File-based, good for development and testing
- **MySQL** - Popular relational database with good concurrency support
- **PostgreSQL** - Advanced relational database with excellent concurrency features (row-level locking, MVCC)

The database choice should consider the concurrency requirements. PostgreSQL is recommended for production-like scenarios due to its robust locking mechanisms.

### Concurrency Requirements

**The Critical Challenge: Preventing Race Conditions**

The system must prevent overselling when multiple `POST /orders` requests arrive simultaneously. A simple "check stock then update" approach is insufficient.

**Required Concurrency Strategy (choose one):**

1. **Database-Level Transactions with Row-Level Locking (Recommended)**
   - Wrap order creation in a database transaction
   - Use `SELECT ... FOR UPDATE` to lock product rows during stock validation
   - Prevents other transactions from modifying stock until current transaction completes
   - Atomic validation and decrement of all items

2. **Optimistic Concurrency Control**
   - Add a `version` column to products table
   - Include version in UPDATE WHERE clause
   - Retry on version mismatch
   - Works well for low-contention scenarios

3. **Database Constraints**
   - Use CHECK constraints to prevent negative quantities
   - Combine with transactions for atomic operations
   - Database enforces integrity at the lowest level

**Minimum Requirements:**
- Order placement must be atomic (all items succeed or none)
- Stock validation and decrement must occur in the same transaction
- Concurrent order attempts must not result in overselling
- Cart updates should handle concurrent modifications safely

### Seed Data

The system should include a seed script to populate the database with initial data:
- 5-10 product categories (e.g., "Dairy", "Fruits", "Bakery", "Vegetables", "Meat")
- 20-30 sample products with realistic stock levels
- 2-3 test users for immediate API testing

Seed data enables immediate testing without manual data entry.

## Design Principles

1. **RESTful Design** - Resources are nouns, HTTP methods define actions
2. **Consistent Responses** - Same data structure for same resource types
3. **Proper Status Codes** - Use appropriate HTTP status codes for each scenario
4. **Inventory Safety** - Never allow overselling through atomic stock checks
5. **Graceful Errors** - Return meaningful error messages with typed errors and details
6. **Cart-Order Separation** - Carts are working state, orders are committed state
7. **Soft Delete Support** - Products can be hidden without breaking order history
8. **Input Validation** - All inputs validated and sanitized with clear error messages
9. **Documentation First** - API documentation auto-generated and always up-to-date

## Test Suite Checklist

### Product API Tests
- [ ] List products returns paginated list (excluding soft-deleted)
- [ ] List products respects page and pageSize parameters
- [ ] Get product returns single product (including soft-deleted)
- [ ] Get product returns 404 for non-existent product
- [ ] Soft deleted products don't appear in product list

### Category API Tests
- [ ] List categories returns paginated list
- [ ] Get products by category returns active products only
- [ ] Get products by category returns 404 for non-existent category

### Cart API Tests
- [ ] Get cart returns user's cart (creates if none exists)
- [ ] Get cart returns 404 for non-existent user
- [ ] Add item to cart creates cart if none exists
- [ ] Add item to cart updates quantity if product already in cart
- [ ] Add item to cart returns 404 for non-existent user
- [ ] Add item to cart returns 404 for non-existent product
- [ ] Add item to cart returns 404 for soft-deleted product
- [ ] Add item to cart returns 409 when insufficient stock
- [ ] Add item to cart rejects negative quantities (422)
- [ ] Update cart item updates quantity
- [ ] Update cart item returns 404 for product not in cart
- [ ] Update cart item returns 409 when insufficient stock
- [ ] Update cart item rejects negative quantities (422)
- [ ] Remove item from cart removes the item
- [ ] Remove item from cart returns 404 for product not in cart
- [ ] Clear cart removes all items
- [ ] Clear cart returns 404 for non-existent user

### Order API Tests
- [ ] Place order creates order from cart
- [ ] Place order returns 404 for non-existent user
- [ ] Place order returns 404 when cart not found
- [ ] Place order returns 409 when cart is empty
- [ ] Place order returns 400 when insufficient stock (with details)
- [ ] Place order clears cart after success
- [ ] Place order decrements stock quantities
- [ ] Place order is atomic (fails entirely or succeeds entirely)
- [ ] Get order returns single order
- [ ] Get order returns 404 for non-existent order
- [ ] Get order includes soft-deleted products
- [ ] Cancel order sets status to CANCELLED
- [ ] Cancel order restores stock quantities
- [ ] Cancel order returns 404 for non-existent order
- [ ] Cancel order returns 409 when already cancelled

### Concurrency Tests
- [ ] Concurrent orders don't oversell stock
- [ ] Stock remains accurate after concurrent order attempts
- [ ] One order fails when two try to buy last item simultaneously

### API Documentation Tests
- [ ] API documentation is accessible at `/api` or `/api/docs`
- [ ] Documentation includes all endpoints
- [ ] Documentation includes request/response schemas

### E2E Tests
- [ ] Full flow: Add to cart → Update quantity → Place order → Get order → Cancel order
- [ ] Full flow: Add multiple items → Place order → Verify stock decremented
- [ ] Full flow: Create order → Cancel order → Verify stock restored
- [ ] Stock protection: Attempt to order more than available stock
- [ ] Soft delete: Create product → Create order → Soft delete product → View order (product still visible)

## Example Usage

### List Products

```bash
curl -X GET "http://localhost:3000/products?page=1&pageSize=20"
```

### Get a Product

```bash
curl -X GET http://localhost:3000/products/1
```

### List Categories

```bash
curl -X GET http://localhost:3000/categories
```

### Get Products in a Category

```bash
curl -X GET "http://localhost:3000/categories/1/products?page=1&pageSize=20"
```

### Get User's Cart

```bash
curl -X GET http://localhost:3000/carts/1
```

### Add Item to Cart

```bash
curl -X POST http://localhost:3000/carts/1/items \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 1,
    "quantity": 2
  }'
```

### Update Cart Item

```bash
curl -X PUT http://localhost:3000/carts/1/items/1 \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 3
  }'
```

### Remove Item from Cart

```bash
curl -X DELETE http://localhost:3000/carts/1/items/1
```

### Clear Cart

```bash
curl -X DELETE http://localhost:3000/carts/1
```

### Place an Order

```bash
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1
  }'
```

### Get an Order

```bash
curl -X GET http://localhost:3000/orders/1
```

### Cancel an Order

```bash
curl -X POST http://localhost:3000/orders/1/cancel
```

### View API Documentation

```bash
# Open in browser
curl -X GET http://localhost:3000/api
```
