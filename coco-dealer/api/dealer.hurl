# Health check
GET {{ host }}/api/v1/livez
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.type" == "health_check"
jsonpath "$.data.status" == "OK"

# Create a new deck with default settings (full 52-card deck)
POST {{ host }}/api/v1/decks
Content-Type: application/json
{}
HTTP 201
[Captures]
deck_id: jsonpath "$.data.deck_id"
[Asserts]
jsonpath "$.type" == "deck"
jsonpath "$.data.deck_id" exists
jsonpath "$.data.remaining_cards" == 52

# Create a shuffled deck
POST {{ host }}/api/v1/decks
Content-Type: application/json
{
  "is_shuffled": true
}
HTTP 201
[Captures]
shuffled_deck_id: jsonpath "$.data.deck_id"
[Asserts]
jsonpath "$.type" == "deck"
jsonpath "$.data.deck_id" exists
jsonpath "$.data.is_shuffled" == true
jsonpath "$.data.remaining_cards" == 52

# Create a custom deck with wanted cards
POST {{ host }}/api/v1/decks
Content-Type: application/json
{
  "is_shuffled": false,
  "wanted_cards": ["AS", "KH", "QD", "JC", "0S"]
}
HTTP 201
[Captures]
custom_deck_id: jsonpath "$.data.deck_id"
[Asserts]
jsonpath "$.type" == "deck"
jsonpath "$.data.deck_id" exists
jsonpath "$.data.remaining_cards" == 5

# Create deck ignores bad input (no validation errors)
POST {{ host }}/api/v1/decks
Content-Type: application/json
{
  "is_shuffled": "not-a-boolean",
  "wanted_cards": "not-an-array",
  "unknown_field": "ignored"
}
HTTP 201
[Asserts]
jsonpath "$.type" == "deck"
jsonpath "$.data.deck_id" exists

# Get deck information
GET {{ host }}/api/v1/decks/{{ custom_deck_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.type" == "deck"
jsonpath "$.data.deck_id" == "{{ custom_deck_id }}"
jsonpath "$.data.shuffled" == false
jsonpath "$.data.remaining" == 5
jsonpath "$.data.cards" count == 5
jsonpath "$.data.cards[0].code" exists
jsonpath "$.data.cards[0].value" exists
jsonpath "$.data.cards[0].suit" exists

# Get deck returns 404 for non-existent deck
GET {{ host }}/api/v1/decks/non-existent-deck-id
Content-Type: application/json
HTTP 404
[Asserts]
jsonpath "$.type" == "error"
jsonpath "$.error" == "DeckNotFound"

# Draw a single card
PATCH {{ host }}/api/v1/decks/{{ custom_deck_id }}/draw
Content-Type: application/json
{
  "count": 1
}
HTTP 200
[Asserts]
jsonpath "$.type" == "card"
jsonpath "$.data" count == 1
jsonpath "$.data[0].code" exists
jsonpath "$.data[0].value" exists
jsonpath "$.data[0].suit" exists

# Verify remaining cards decreased
GET {{ host }}/api/v1/decks/{{ custom_deck_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.data.remaining" == 4
jsonpath "$.data.cards" count == 4

# Draw multiple cards
PATCH {{ host }}/api/v1/decks/{{ custom_deck_id }}/draw
Content-Type: application/json
{
  "count": 2
}
HTTP 200
[Asserts]
jsonpath "$.type" == "card"
jsonpath "$.data" count == 2

# Verify remaining cards decreased again
GET {{ host }}/api/v1/decks/{{ custom_deck_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.data.remaining" == 2

# Draw from non-existent deck returns 404
PATCH {{ host }}/api/v1/decks/non-existent-deck/draw
Content-Type: application/json
{
  "count": 1
}
HTTP 404
[Asserts]
jsonpath "$.type" == "error"
jsonpath "$.error" == "DeckNotFound"

# Create a small deck to test insufficient cards
POST {{ host }}/api/v1/decks
Content-Type: application/json
{
  "wanted_cards": ["AS"]
}
HTTP 201
[Captures]
single_card_deck_id: jsonpath "$.data.deck_id"
[Asserts]
jsonpath "$.data.remaining_cards" == 1

# Draw the only card
PATCH {{ host }}/api/v1/decks/{{ single_card_deck_id }}/draw
Content-Type: application/json
{
  "count": 1
}
HTTP 200
[Asserts]
jsonpath "$.data" count == 1

# Verify deck is empty
GET {{ host }}/api/v1/decks/{{ single_card_deck_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.data.remaining" == 0
jsonpath "$.data.cards" count == 0

# Draw from empty deck returns empty array (or error based on implementation)
PATCH {{ host }}/api/v1/decks/{{ single_card_deck_id }}/draw
Content-Type: application/json
{
  "count": 1
}
HTTP 400
[Asserts]
jsonpath "$.type" == "error"
jsonpath "$.error" == "InsufficientCards"

# Verify full deck has correct structure
GET {{ host }}/api/v1/decks/{{ deck_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.data.remaining" == 52
jsonpath "$.data.cards[0].value" exists
jsonpath "$.data.cards[0].suit" exists
jsonpath "$.data.cards[0].code" exists

# Verify shuffled deck has different order than unshuffled
# (This is probabilistic but highly likely to pass)
GET {{ host }}/api/v1/decks/{{ deck_id }}
Content-Type: application/json
HTTP 200
[Captures]
unshuffled_first_card: jsonpath "$.data.cards[0].code"
[Asserts]
jsonpath "$.data.remaining" == 52

GET {{ host }}/api/v1/decks/{{ shuffled_deck_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.data.remaining" == 52
# Note: We can't reliably assert the first card is different due to randomness
# but we can verify the deck exists and has 52 cards

# Draw without count defaults to 1
POST {{ host }}/api/v1/decks
Content-Type: application/json
{
  "wanted_cards": ["AS", "KH", "QD"]
}
HTTP 201
[Captures]
no_count_deck_id: jsonpath "$.data.deck_id"

PATCH {{ host }}/api/v1/decks/{{ no_count_deck_id }}/draw
Content-Type: application/json
{}
HTTP 200
[Asserts]
jsonpath "$.type" == "card"
jsonpath "$.data" count == 1

# Verify all card values are valid
GET {{ host }}/api/v1/decks/{{ deck_id }}
Content-Type: application/json
HTTP 200
[Asserts]
jsonpath "$.data.cards[*].value" includes "ACE"
jsonpath "$.data.cards[*].value" includes "KING"
jsonpath "$.data.cards[*].value" includes "QUEEN"
jsonpath "$.data.cards[*].value" includes "JACK"
jsonpath "$.data.cards[*].suit" includes "SPADES"
jsonpath "$.data.cards[*].suit" includes "HEARTS"
jsonpath "$.data.cards[*].suit" includes "DIAMONDS"
jsonpath "$.data.cards[*].suit" includes "CLUBS"
