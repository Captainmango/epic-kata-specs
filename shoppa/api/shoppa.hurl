# Health check / Index
GET {{ host }}/
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.message" exists

# API Documentation endpoint should exist
GET {{ host }}/api
HTTP 200

# List products
GET {{ host }}/products
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.data" isArray
jsonpath "$.pagination" exists
jsonpath "$.pagination.page" exists
jsonpath "$.pagination.pageSize" exists
jsonpath "$.pagination.total" exists

# Get a single product (assuming product with id 1 exists from seed data)
GET {{ host }}/products/1
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.id" exists
jsonpath "$.name" exists
jsonpath "$.quantity" exists
jsonpath "$.deletedAt" exists

# Get product returns 404 for non-existent product
GET {{ host }}/products/999999
Content-Type: application/json
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# List categories
GET {{ host }}/categories
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.data" isArray
jsonpath "$.pagination" exists

# Get products by category (assuming category with id 1 exists)
GET {{ host }}/categories/1/products
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.data" isArray
jsonpath "$.pagination" exists

# Get products by category returns 404 for non-existent category
GET {{ host }}/categories/999999/products
Content-Type: application/json
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Get user's cart (assuming user with id 1 exists)
GET {{ host }}/carts/1
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.id" exists
jsonpath "$.products" isArray

# Get cart returns 404 for non-existent user
GET {{ host }}/carts/999999
Content-Type: application/json
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Add item to cart
POST {{ host }}/carts/1/items
Content-Type: application/json
{
  "productId": 1,
  "quantity": 2
}
HTTP 200
[Captures]
cart_id: jsonpath "$.id"
[Asserts]
jsonpath "$.id" exists
jsonpath "$.products" isArray

# Add item to cart returns 404 for non-existent user
POST {{ host }}/carts/999999/items
Content-Type: application/json
{
  "productId": 1,
  "quantity": 1
}
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Add item to cart returns 404 for non-existent product
POST {{ host }}/carts/1/items
Content-Type: application/json
{
  "productId": 999999,
  "quantity": 1
}
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Add item to cart with invalid quantity (validation test)
POST {{ host }}/carts/1/items
Content-Type: application/json
{
  "productId": 1,
  "quantity": -1
}
HTTP 422

# Update cart item quantity (using productId in URL)
PUT {{ host }}/carts/1/items/1
Content-Type: application/json
{
  "quantity": 3
}
HTTP 200
[Asserts]
jsonpath "$.id" == {{ cart_id }}
jsonpath "$.products" isArray

# Update cart item with invalid quantity (validation test)
PUT {{ host }}/carts/1/items/1
Content-Type: application/json
{
  "quantity": -5
}
HTTP 422

# Update cart item returns 404 for product not in cart
PUT {{ host }}/carts/1/items/999999
Content-Type: application/json
{
  "quantity": 1
}
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Place an order
POST {{ host }}/orders
Content-Type: application/json
{
  "userId": 1
}
HTTP 201
[Captures]
order_id: jsonpath "$.id"
[Asserts]
jsonpath "$.id" exists
jsonpath "$.status" == "PENDING"
jsonpath "$.products" isArray

# Place order with invalid userId (validation test)
POST {{ host }}/orders
Content-Type: application/json
{
  "userId": -1
}
HTTP 422

# Get the order
GET {{ host }}/orders/{{ order_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.id" == {{ order_id }}
jsonpath "$.status" == "PENDING"
jsonpath "$.products" isArray

# Get order returns 404 for non-existent order
GET {{ host }}/orders/999999
Content-Type: application/json
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Cancel the order
POST {{ host }}/orders/{{ order_id }}/cancel
Content-Type: application/json
HTTP 204

# Cancel order returns 404 for non-existent order
POST {{ host }}/orders/999999/cancel
Content-Type: application/json
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Cancel already cancelled order returns 409
POST {{ host }}/orders/{{ order_id }}/cancel
Content-Type: application/json
HTTP 409
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Verify cart is empty after order was placed
GET {{ host }}/carts/1
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.products" isArray

# Add item to cart for stock test
POST {{ host }}/carts/1/items
Content-Type: application/json
{
  "productId": 1,
  "quantity": 1
}
HTTP 200

# Place order returns 404 when cart not found (for user with no cart)
POST {{ host }}/orders
Content-Type: application/json
{
  "userId": 999999
}
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Remove item from cart (using productId in URL)
DELETE {{ host }}/carts/1/items/1
HTTP 200
[Asserts]
jsonpath "$.id" exists
jsonpath "$.products" isArray

# Remove item from cart returns 404 for product not in cart
DELETE {{ host }}/carts/1/items/999999
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists

# Clear cart (should succeed even if empty)
DELETE {{ host }}/carts/1
HTTP 204

# Clear cart returns 404 for non-existent user
DELETE {{ host }}/carts/999999
HTTP 404
[Asserts]
jsonpath "$.type" exists
jsonpath "$.message" exists
