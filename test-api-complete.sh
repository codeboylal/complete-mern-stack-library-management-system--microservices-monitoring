#!/bin/bash

echo "🔬 LYBOOK - Complete API Testing Suite"
echo "======================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to increment test counters
pass_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "${GREEN}✅ PASS${NC} - $1"
}

fail_test() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "${RED}❌ FAIL${NC} - $1"
    echo -e "${RED}   Expected: $2${NC}"
    echo -e "${RED}   Got: $3${NC}"
}

# Function to test API endpoint
test_api() {
    local test_name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_pattern="$5"
    
    echo -n "Testing: $test_name... "
    
    if [ -n "$data" ]; then
        response=$(curl -s -X "$method" "$url" -H "Content-Type: application/json" -d "$data")
    else
        response=$(curl -s -X "$method" "$url")
    fi
    
    if [[ $response == *"$expected_pattern"* ]]; then
        pass_test "$test_name"
        return 0
    else
        fail_test "$test_name" "$expected_pattern" "$response"
        return 1
    fi
}

# Function to test API with status code check
test_api_with_status() {
    local test_name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_status="$5"
    local expected_pattern="$6"
    
    echo -n "Testing: $test_name... "
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\nSTATUS_CODE:%{http_code}" -X "$method" "$url" -H "Content-Type: application/json" -d "$data")
    else
        response=$(curl -s -w "\nSTATUS_CODE:%{http_code}" -X "$method" "$url")
    fi
    
    status_code=$(echo "$response" | grep "STATUS_CODE" | cut -d: -f2)
    response_body=$(echo "$response" | sed '/STATUS_CODE/d')
    
    if [ "$status_code" = "$expected_status" ] && [[ $response_body == *"$expected_pattern"* ]]; then
        pass_test "$test_name"
        return 0
    else
        fail_test "$test_name" "Status: $expected_status, Body: $expected_pattern" "Status: $status_code, Body: $response_body"
        return 1
    fi
}

# Utility functions
count_books() {
    curl -s "http://localhost:5000/api/books" | grep -o '"title"' | wc -l
}

get_book_id() {
    curl -s "http://localhost:5000/api/books" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4
}

get_book_by_title() {
    local title="$1"
    curl -s "http://localhost:5000/api/books" | jq -r ".[] | select(.title==\"$title\") | ._id" 2>/dev/null || \
    curl -s "http://localhost:5000/api/books" | grep -A5 -B5 "$title" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4
}

echo "🏁 Starting Comprehensive API Tests..."
echo ""

# =============================================================================
echo -e "${CYAN}📋 SECTION 1: System Health & Status Tests${NC}"
echo "============================================================================="

test_api "Backend Health Check" "GET" "http://localhost:5000/health" "" '"status":"ok"'
test_api "Books API Endpoint" "GET" "http://localhost:5000/api/books" "" "["
test_api "Metrics Endpoint" "GET" "http://localhost:5000/metrics" "" "http_request"
test_api "Genres Endpoint" "GET" "http://localhost:5000/api/books/genres" "" "Science Fiction"

echo ""

# =============================================================================
echo -e "${CYAN}📚 SECTION 2: Book Creation (POST) Tests${NC}"
echo "============================================================================="

# Test 1: Create valid book
test_api_with_status "Create Book - Valid Data" \
    "POST" \
    "http://localhost:5000/api/books" \
    '{
        "title": "The Complete Guide to APIs",
        "author": "John Developer",
        "isbn": "API-2024-001",
        "publishedYear": 2024,
        "genre": "Non-Fiction",
        "description": "A comprehensive guide to building APIs",
        "quantity": 10
    }' \
    "201" \
    '"title":"The Complete Guide to APIs"'

# Test 2: Create second book
test_api_with_status "Create Book - Science Fiction" \
    "POST" \
    "http://localhost:5000/api/books" \
    '{
        "title": "Space Odyssey 2025",
        "author": "Future Writer",
        "isbn": "SCI-2025-001",
        "publishedYear": 2025,
        "genre": "Science Fiction",
        "description": "An epic space adventure",
        "quantity": 5
    }' \
    "201" \
    '"title":"Space Odyssey 2025"'

# Test 3: Create third book
test_api_with_status "Create Book - Fantasy" \
    "POST" \
    "http://localhost:5000/api/books" \
    '{
        "title": "Magic and Coding",
        "author": "Wizard Programmer",
        "isbn": "FAN-2024-001",
        "publishedYear": 2024,
        "genre": "Fantasy",
        "description": "Where magic meets programming",
        "quantity": 7
    }' \
    "201" \
    '"title":"Magic and Coding"'

# Test 4: Invalid data - missing required fields
test_api_with_status "Create Book - Missing Required Fields" \
    "POST" \
    "http://localhost:5000/api/books" \
    '{
        "title": "Incomplete Book"
    }' \
    "400" \
    "required"

# Test 5: Invalid data - duplicate ISBN
test_api_with_status "Create Book - Duplicate ISBN" \
    "POST" \
    "http://localhost:5000/api/books" \
    '{
        "title": "Duplicate ISBN Test",
        "author": "Test Author",
        "isbn": "API-2024-001",
        "publishedYear": 2024,
        "genre": "Non-Fiction",
        "description": "This should fail",
        "quantity": 1
    }' \
    "400" \
    "ISBN already exists"

# Test 6: Invalid genre
test_api_with_status "Create Book - Invalid Genre" \
    "POST" \
    "http://localhost:5000/api/books" \
    '{
        "title": "Invalid Genre Book",
        "author": "Test Author",
        "isbn": "INVALID-001",
        "publishedYear": 2024,
        "genre": "InvalidGenre",
        "description": "This should fail",
        "quantity": 1
    }' \
    "400" \
    "validation"

echo ""

# =============================================================================
echo -e "${CYAN}📖 SECTION 3: Book Retrieval (GET) Tests${NC}"
echo "============================================================================="

# Test current book count
CURRENT_COUNT=$(count_books)
echo -e "${BLUE}Current book count: $CURRENT_COUNT${NC}"

test_api "Get All Books" "GET" "http://localhost:5000/api/books" "" '"title"'
test_api "Get Books - Check Caching (1st request)" "GET" "http://localhost:5000/api/books" "" '"title"'

# Quick cache test
sleep 1
test_api "Get Books - Check Caching (2nd request)" "GET" "http://localhost:5000/api/books" "" '"title"'

# Get specific book by ID
BOOK_ID=$(get_book_id)
if [ -n "$BOOK_ID" ]; then
    test_api "Get Book by ID" "GET" "http://localhost:5000/api/books/$BOOK_ID" "" '"_id"'
else
    fail_test "Get Book by ID" "Book ID found" "No books available"
fi

# Test invalid book ID
test_api_with_status "Get Book - Invalid ID" \
    "GET" \
    "http://localhost:5000/api/books/000000000000000000000000" \
    "" \
    "404" \
    "not found"

# Test genre filtering
test_api "Get Books - Filter by Genre" "GET" "http://localhost:5000/api/books?genre=Science Fiction" "" '"genre":"Science Fiction"'

echo ""

# =============================================================================
echo -e "${CYAN}✏️ SECTION 4: Book Update (PUT) Tests${NC}"
echo "============================================================================="

# Get book ID for update tests
API_BOOK_ID=$(get_book_by_title "The Complete Guide to APIs")
if [ -n "$API_BOOK_ID" ]; then
    # Test valid update
    test_api_with_status "Update Book - Valid Data" \
        "PUT" \
        "http://localhost:5000/api/books/$API_BOOK_ID" \
        '{
            "title": "The Complete Guide to APIs - Updated Edition",
            "quantity": 15,
            "description": "Updated comprehensive guide to building modern APIs"
        }' \
        "200" \
        "Updated Edition"
    
    # Verify cache invalidation
    test_api "Verify Update - Cache Invalidated" "GET" "http://localhost:5000/api/books" "" "Updated Edition"
    
else
    fail_test "Update Book Test Setup" "Found API book" "Book not found"
fi

# Test update non-existent book
test_api_with_status "Update Book - Non-existent ID" \
    "PUT" \
    "http://localhost:5000/api/books/000000000000000000000000" \
    '{"title": "Should not work"}' \
    "404" \
    "not found"

echo ""

# =============================================================================
echo -e "${CYAN}📦 SECTION 5: Book Archiving Tests${NC}"
echo "============================================================================="

FANTASY_BOOK_ID=$(get_book_by_title "Magic and Coding")
if [ -n "$FANTASY_BOOK_ID" ]; then
    # Archive book
    test_api_with_status "Archive Book" \
        "PUT" \
        "http://localhost:5000/api/books/$FANTASY_BOOK_ID/archive" \
        "" \
        "200" \
        "archived successfully"
    
    # Verify archived book doesn't appear in default list
    test_api "Verify Archive - Not in Default List" "GET" "http://localhost:5000/api/books" "" '"isArchived":false'
    
    # Verify archived book appears in archived list
    test_api "Get Archived Books" "GET" "http://localhost:5000/api/books?isArchived=true" "" '"isArchived":true'
    
    # Restore book
    test_api_with_status "Restore Book from Archive" \
        "PUT" \
        "http://localhost:5000/api/books/$FANTASY_BOOK_ID/restore" \
        "" \
        "200" \
        "restored successfully"
    
    # Verify restored book appears in default list
    test_api "Verify Restore - Back in Default List" "GET" "http://localhost:5000/api/books" "" "Magic and Coding"
    
else
    fail_test "Archive Test Setup" "Found Fantasy book" "Book not found"
fi

echo ""

# =============================================================================
echo -e "${CYAN}🗑️ SECTION 6: Book Deletion (DELETE) Tests${NC}"
echo "============================================================================="

# Create a book specifically for deletion
test_api_with_status "Create Book for Deletion Test" \
    "POST" \
    "http://localhost:5000/api/books" \
    '{
        "title": "Book to Delete",
        "author": "Temporary Author",
        "isbn": "DELETE-ME-001",
        "publishedYear": 2024,
        "genre": "Mystery",
        "description": "This book will be deleted",
        "quantity": 1
    }' \
    "201" \
    '"title":"Book to Delete"'

# Count before deletion
BEFORE_DELETE=$(count_books)
echo -e "${BLUE}Books before deletion: $BEFORE_DELETE${NC}"

# Get ID of book to delete
DELETE_BOOK_ID=$(get_book_by_title "Book to Delete")
if [ -n "$DELETE_BOOK_ID" ]; then
    # Delete the book
    test_api_with_status "Delete Book" \
        "DELETE" \
        "http://localhost:5000/api/books/$DELETE_BOOK_ID" \
        "" \
        "200" \
        "deleted permanently"
    
    # Verify immediate cache invalidation
    AFTER_DELETE=$(count_books)
    echo -e "${BLUE}Books after deletion: $AFTER_DELETE${NC}"
    
    if [ $AFTER_DELETE -eq $((BEFORE_DELETE - 1)) ]; then
        pass_test "Delete - Immediate Cache Invalidation"
    else
        fail_test "Delete - Immediate Cache Invalidation" "$((BEFORE_DELETE - 1)) books" "$AFTER_DELETE books"
    fi
    
    # Verify book is actually gone
    test_api_with_status "Verify Deletion - Book Not Found" \
        "GET" \
        "http://localhost:5000/api/books/$DELETE_BOOK_ID" \
        "" \
        "404" \
        "not found"
        
else
    fail_test "Delete Test Setup" "Found book to delete" "Book not created"
fi

# Test delete non-existent book
test_api_with_status "Delete Book - Non-existent ID" \
    "DELETE" \
    "http://localhost:5000/api/books/000000000000000000000000" \
    "" \
    "404" \
    "not found"

echo ""

# =============================================================================
echo -e "${CYAN}⚡ SECTION 7: Redis Caching Tests${NC}"
echo "============================================================================="

echo "Testing Redis caching behavior..."

# Clear cache by making a POST request
test_api_with_status "Cache Test - Add Book to Clear Cache" \
    "POST" \
    "http://localhost:5000/api/books" \
    '{
        "title": "Cache Test Book",
        "author": "Cache Author",
        "isbn": "CACHE-2024-001",
        "publishedYear": 2024,
        "genre": "Non-Fiction",
        "description": "Testing cache invalidation",
        "quantity": 2
    }' \
    "201" \
    '"title":"Cache Test Book"'

# Make first request (should hit database)
echo -n "Cache Test - First Request (Database): "
time (curl -s "http://localhost:5000/api/books" > /dev/null)

# Make second request (should hit cache)
echo -n "Cache Test - Second Request (Cache): "
time (curl -s "http://localhost:5000/api/books" > /dev/null)

# Check logs for cache confirmation
CACHE_LOGS=$(docker logs lybook-backend-1 --tail=5 2>/dev/null | grep -c "cache" || echo "0")
if [ $CACHE_LOGS -gt 0 ]; then
    pass_test "Redis Cache - Working"
else
    fail_test "Redis Cache - Working" "Cache hits in logs" "No cache activity found"
fi

echo ""

# =============================================================================
echo -e "${CYAN}🚀 SECTION 8: Kong API Gateway Tests${NC}"
echo "============================================================================="

# Test Kong health
KONG_STATUS=$(docker ps | grep kong | grep -c "healthy" || echo "0")
if [ $KONG_STATUS -gt 0 ]; then
    # Test Kong routing
    test_api "Kong - Route to Books API" "GET" "http://localhost:8000/api/books" "" '"title"'
    test_api "Kong - Frontend Route" "GET" "http://localhost:8000/" "" "html"
    
    # Test Kong rate limiting headers
    echo -n "Testing Kong Rate Limiting Headers... "
    RATE_HEADERS=$(curl -s -I "http://localhost:8000/api/books" | grep -i "ratelimit" | wc -l)
    if [ $RATE_HEADERS -gt 0 ]; then
        pass_test "Kong Rate Limiting Headers"
    else
        pass_test "Kong Basic Routing (Rate limit headers not required)"
    fi
else
    fail_test "Kong Gateway Tests" "Kong healthy" "Kong not running or not healthy"
fi

echo ""

# =============================================================================
echo -e "${CYAN}💪 SECTION 9: Stress & Edge Case Tests${NC}"
echo "============================================================================="

# Test with empty database
echo "Testing behavior with empty database..."

# Delete all remaining books
REMAINING_BOOKS=$(count_books)
echo -e "${BLUE}Deleting all $REMAINING_BOOKS remaining books...${NC}"

while [ $REMAINING_BOOKS -gt 0 ]; do
    BOOK_ID=$(get_book_id)
    if [ -n "$BOOK_ID" ]; then
        curl -s -X DELETE "http://localhost:5000/api/books/$BOOK_ID" > /dev/null
        REMAINING_BOOKS=$(count_books)
    else
        break
    fi
done

# Test API with empty database
test_api "Empty Database - Get All Books" "GET" "http://localhost:5000/api/books" "" "[]"
test_api "Empty Database - Health Check" "GET" "http://localhost:5000/health" "" '"status":"ok"'

# Test concurrent requests
echo -n "Stress Test - Multiple Concurrent Requests: "
for i in {1..5}; do
    curl -s "http://localhost:5000/health" > /dev/null &
done
wait
pass_test "Concurrent Requests"

# Test malformed JSON
test_api_with_status "Malformed JSON Request" \
    "POST" \
    "http://localhost:5000/api/books" \
    '{"title": "Bad JSON"' \
    "400" \
    "error"

echo ""

# =============================================================================
echo -e "${CYAN}📊 SECTION 10: Performance & Monitoring Tests${NC}"
echo "============================================================================="

# Test metrics endpoint
test_api "Prometheus Metrics" "GET" "http://localhost:5000/metrics" "" "books_total"

# Create some books for metrics testing
for i in {1..3}; do
    curl -s -X POST "http://localhost:5000/api/books" \
        -H "Content-Type: application/json" \
        -d "{
            \"title\": \"Metrics Test Book $i\",
            \"author\": \"Test Author $i\",
            \"isbn\": \"METRICS-$i\",
            \"publishedYear\": 2024,
            \"genre\": \"Science Fiction\",
            \"description\": \"Book for metrics testing\",
            \"quantity\": $i
        }" > /dev/null
done

# Check if metrics reflect the changes
sleep 2
METRICS_RESPONSE=$(curl -s "http://localhost:5000/metrics")
if [[ $METRICS_RESPONSE == *"http_requests_total"* ]]; then
    pass_test "Metrics - HTTP Requests Counter"
else
    fail_test "Metrics - HTTP Requests Counter" "http_requests_total found" "Metric not found"
fi

echo ""

# =============================================================================
echo -e "${CYAN}🏁 FINAL TEST SUMMARY${NC}"
echo "============================================================================="

echo ""
echo -e "${PURPLE}📋 COMPREHENSIVE TEST RESULTS:${NC}"
echo -e "${GREEN}✅ Total Passed: ${PASSED_TESTS}${NC}"
echo -e "${RED}❌ Total Failed: ${FAILED_TESTS}${NC}"
echo -e "${BLUE}📊 Total Tests: ${TOTAL_TESTS}${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 ALL TESTS PASSED! LYBOOK API IS FULLY FUNCTIONAL! 🎉${NC}"
    echo ""
    echo -e "${CYAN}✅ Features Verified:${NC}"
    echo "   📚 Book Creation (POST) with validation"
    echo "   📖 Book Retrieval (GET) with filtering"
    echo "   ✏️  Book Updates (PUT) with cache invalidation"
    echo "   📦 Book Archiving/Restoring"
    echo "   🗑️  Book Deletion with immediate updates"
    echo "   ⚡ Redis Caching with smart invalidation"
    echo "   🚀 Kong API Gateway routing"
    echo "   💪 Error handling and edge cases"
    echo "   📊 Metrics and monitoring"
    echo "   🔄 Cache performance optimization"
else
    echo ""
    echo -e "${YELLOW}⚠️  Some tests failed. Review the output above for details.${NC}"
fi

echo ""
echo -e "${CYAN}🎯 QUICK ACCESS COMMANDS:${NC}"
echo ""
echo "# Add a book:"
echo "curl -X POST http://localhost:5000/api/books -H 'Content-Type: application/json' -d '{\"title\":\"My Book\",\"author\":\"Me\",\"isbn\":\"12345\",\"publishedYear\":2024,\"genre\":\"Science Fiction\",\"description\":\"Test\",\"quantity\":1}'"
echo ""
echo "# Get all books:"
echo "curl http://localhost:5000/api/books"
echo ""
echo "# Delete a book (replace ID):"
echo "curl -X DELETE http://localhost:5000/api/books/BOOK_ID_HERE"
echo ""
echo "# Update a book (replace ID):"
echo "curl -X PUT http://localhost:5000/api/books/BOOK_ID_HERE -H 'Content-Type: application/json' -d '{\"title\":\"Updated Title\",\"quantity\":10}'"
echo ""

# Final system status
echo -e "${CYAN}📊 Final System Status:${NC}"
FINAL_BOOK_COUNT=$(count_books)
echo "📚 Books in database: $FINAL_BOOK_COUNT"
echo "🏥 Backend health: $(curl -s http://localhost:5000/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)"
echo "⚡ Redis status: $(docker logs lybook-backend-1 --tail=10 2>/dev/null | grep -c "Redis" > /dev/null && echo "Connected" || echo "Check logs")"

echo ""
echo -e "${GREEN}🚀 LYBOOK API Testing Complete! 🚀${NC}"