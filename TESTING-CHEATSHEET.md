# 🧪 LYBOOK - Complete Testing & Commands Cheat Sheet

## 🚀 **Quick Start Commands**

```bash
# Start the application (basic mode)
./setup-mode.sh core

# Start the application (full microservices mode)
./setup-mode.sh enhanced

# Check system status
./check-status.sh

# Run comprehensive tests
./test-api-complete.sh

# Test delete functionality specifically
./test-delete-functionality.sh
```

## 📚 **Manual API Testing Commands**

### **📖 GET Operations (Read)**

```bash
# Get all books
curl "http://localhost:5000/api/books"

# Get all books (via Kong Gateway)
curl "http://localhost:8000/api/books"

# Get books by genre
curl "http://localhost:5000/api/books?genre=Science Fiction"

# Get archived books
curl "http://localhost:5000/api/books?isArchived=true"

# Get specific book by ID (replace BOOK_ID)
curl "http://localhost:5000/api/books/BOOK_ID_HERE"

# Get available genres
curl "http://localhost:5000/api/books/genres"

# Health check
curl "http://localhost:5000/health"

# Prometheus metrics
curl "http://localhost:5000/metrics"
```

### **✏️ POST Operations (Create)**

```bash
# Add a new book
curl -X POST "http://localhost:5000/api/books" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Amazing Book",
    "author": "John Author",
    "isbn": "978-1234567890",
    "publishedYear": 2024,
    "genre": "Science Fiction",
    "description": "An incredible story about the future",
    "quantity": 10
  }'

# Add book via Kong Gateway
curl -X POST "http://localhost:8000/api/books" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Kong Test Book",
    "author": "Gateway Author",
    "isbn": "978-0987654321",
    "publishedYear": 2024,
    "genre": "Fantasy",
    "description": "Book added through Kong",
    "quantity": 5
  }'
```

### **🔧 PUT Operations (Update)**

```bash
# Update a book (replace BOOK_ID)
curl -X PUT "http://localhost:5000/api/books/BOOK_ID_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Book Title",
    "quantity": 15,
    "description": "Updated description"
  }'

# Archive a book
curl -X PUT "http://localhost:5000/api/books/BOOK_ID_HERE/archive"

# Restore a book from archive
curl -X PUT "http://localhost:5000/api/books/BOOK_ID_HERE/restore"
```

### **🗑️ DELETE Operations (Remove)**

```bash
# Delete a book permanently (replace BOOK_ID)
curl -X DELETE "http://localhost:5000/api/books/BOOK_ID_HERE"

# Delete via Kong Gateway
curl -X DELETE "http://localhost:8000/api/books/BOOK_ID_HERE"
```

## 🔍 **Helper Commands**

### **Get Book IDs for Testing**

```bash
# Get all book IDs
curl -s "http://localhost:5000/api/books" | grep -o '"_id":"[^"]*"' | cut -d'"' -f4

# Get first book ID
curl -s "http://localhost:5000/api/books" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4

# Count total books
curl -s "http://localhost:5000/api/books" | grep -o '"title"' | wc -l

# Get book ID by title (replace "Book Title")
curl -s "http://localhost:5000/api/books" | grep -A5 -B5 "Book Title" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4
```

### **Test Cache Performance**

```bash
# First request (hits database)
time curl -s "http://localhost:5000/api/books" > /dev/null

# Second request (hits cache)
time curl -s "http://localhost:5000/api/books" > /dev/null

# Check cache logs
docker logs lybook-backend-1 --tail=5 | grep cache
```

## 🧪 **Testing Scenarios**

### **Test 1: Basic CRUD Operations**

```bash
# 1. Add a book
BOOK_RESPONSE=$(curl -s -X POST "http://localhost:5000/api/books" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test CRUD Book",
    "author": "Test Author",
    "isbn": "TEST-CRUD-001",
    "publishedYear": 2024,
    "genre": "Mystery",
    "description": "Testing CRUD operations",
    "quantity": 3
  }')

echo "Created: $BOOK_RESPONSE"

# 2. Get the book ID
BOOK_ID=$(echo $BOOK_RESPONSE | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
echo "Book ID: $BOOK_ID"

# 3. Read the book
curl "http://localhost:5000/api/books/$BOOK_ID"

# 4. Update the book
curl -X PUT "http://localhost:5000/api/books/$BOOK_ID" \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated CRUD Book", "quantity": 5}'

# 5. Delete the book
curl -X DELETE "http://localhost:5000/api/books/$BOOK_ID"

# 6. Verify deletion
curl "http://localhost:5000/api/books/$BOOK_ID"
```

### **Test 2: Cache Invalidation**

```bash
# 1. Add books and check cache
curl -X POST "http://localhost:5000/api/books" \
  -H "Content-Type: application/json" \
  -d '{"title": "Cache Test 1", "author": "Cache Author", "isbn": "CACHE-001", "publishedYear": 2024, "genre": "Non-Fiction", "description": "Cache test", "quantity": 1}'

# 2. Get books (cache them)
curl -s "http://localhost:5000/api/books" > /dev/null
curl -s "http://localhost:5000/api/books" > /dev/null

# 3. Add another book (should clear cache)
curl -X POST "http://localhost:5000/api/books" \
  -H "Content-Type: application/json" \
  -d '{"title": "Cache Test 2", "author": "Cache Author", "isbn": "CACHE-002", "publishedYear": 2024, "genre": "Non-Fiction", "description": "Cache test", "quantity": 1}'

# 4. Check if new book appears immediately
curl "http://localhost:5000/api/books" | grep "Cache Test 2"
```

### **Test 3: Error Handling**

```bash
# Test 1: Missing required fields
curl -X POST "http://localhost:5000/api/books" \
  -H "Content-Type: application/json" \
  -d '{"title": "Incomplete Book"}'

# Test 2: Invalid genre
curl -X POST "http://localhost:5000/api/books" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Invalid Genre Book",
    "author": "Test",
    "isbn": "INVALID-001",
    "publishedYear": 2024,
    "genre": "InvalidGenre",
    "description": "Test",
    "quantity": 1
  }'

# Test 3: Duplicate ISBN
curl -X POST "http://localhost:5000/api/books" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Duplicate Test 1",
    "author": "Test",
    "isbn": "DUPLICATE-001",
    "publishedYear": 2024,
    "genre": "Mystery",
    "description": "First book",
    "quantity": 1
  }'

curl -X POST "http://localhost:5000/api/books" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Duplicate Test 2",
    "author": "Test",
    "isbn": "DUPLICATE-001",
    "publishedYear": 2024,
    "genre": "Mystery",
    "description": "Second book - should fail",
    "quantity": 1
  }'

# Test 4: Non-existent book ID
curl -X GET "http://localhost:5000/api/books/000000000000000000000000"
curl -X DELETE "http://localhost:5000/api/books/000000000000000000000000"
```

## 🐳 **Docker Commands**

### **Container Management**

```bash
# Check running containers
docker ps

# Check all containers (including stopped)
docker ps -a

# View logs
docker logs lybook-backend-1
docker logs lybook-frontend-1
docker logs lybook-backend-1 -f  # Follow logs

# Restart a service
docker compose -f docker-compose.enhanced.yml --env-file .env.enhanced restart backend

# Rebuild a service
docker compose -f docker-compose.enhanced.yml --env-file .env.enhanced up -d --build backend
```

### **Database Operations**

```bash
# Access MongoDB shell
docker exec -it lybook-mongo-1 mongosh -u mongo_user -p mongo_password --authenticationDatabase admin library

# MongoDB commands (inside mongo shell):
# db.books.find()                    # Get all books
# db.books.countDocuments()          # Count books
# db.books.deleteMany({})            # Delete all books
# db.books.find({genre: "Fantasy"})  # Find by genre

# Access Redis CLI
docker exec -it lybook-redis-1 redis-cli

# Redis commands (inside redis-cli):
# KEYS *           # See all keys
# KEYS books:*     # See book cache keys
# FLUSHALL         # Clear all cache
# GET books:all:false  # Get cached books
```

## 📊 **Monitoring & Metrics**

```bash
# Check Prometheus metrics
curl "http://localhost:9090/metrics"

# Check backend metrics
curl "http://localhost:5000/metrics"

# Access monitoring UIs (in browser):
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3001 (admin/admin)
# RabbitMQ: http://localhost:15672 (admin/password)
# Kibana: http://localhost:5601
```

## 🔧 **System Status Commands**

```bash
# Full system status
./check-status.sh

# Quick health check
curl "http://localhost:5000/health"

# Check if services are responding
curl -I "http://localhost:3000"      # Frontend
curl -I "http://localhost:5000"      # Backend  
curl -I "http://localhost:8000"      # Kong Gateway

# Network troubleshooting
docker network ls
docker network inspect lybook_lybook-network
```

## 🚨 **Troubleshooting Commands**

```bash
# If backend not responding
docker logs lybook-backend-1 --tail=20

# If database issues
docker exec -it lybook-mongo-1 mongosh -u mongo_user -p mongo_password --authenticationDatabase admin --eval "db.adminCommand('ismaster')"

# If Redis issues  
docker exec -it lybook-redis-1 redis-cli ping

# If Kong issues
docker logs lybook-kong-1 --tail=10

# Restart everything
./setup-mode.sh core
```

## 🎯 **Performance Testing**

```bash
# Stress test with multiple requests
for i in {1..10}; do
    curl -s "http://localhost:5000/api/books" > /dev/null &
done
wait

# Load test book creation
for i in {1..5}; do
    curl -s -X POST "http://localhost:5000/api/books" \
      -H "Content-Type: application/json" \
      -d "{
        \"title\": \"Load Test Book $i\",
        \"author\": \"Load Tester\",
        \"isbn\": \"LOAD-TEST-$i\",
        \"publishedYear\": 2024,
        \"genre\": \"Science Fiction\",
        \"description\": \"Performance testing\",
        \"quantity\": $i
      }" &
done
wait
```

## 🏁 **Complete Test Workflow**

```bash
# 1. Start application
./setup-mode.sh core

# 2. Wait for startup
sleep 10

# 3. Run full test suite
./test-api-complete.sh

# 4. Check final status
./check-status.sh

# 5. Manual verification
curl "http://localhost:5000/health"
curl "http://localhost:5000/api/books" | head -c 100
```

---

## 📝 **Notes**

- Replace `BOOK_ID_HERE` with actual book IDs from GET requests
- Use `http://localhost:8000` for Kong Gateway access
- Use `http://localhost:5000` for direct backend access
- Use `http://localhost:3000` for frontend access
- All commands assume the application is running via `./setup-mode.sh core` or `./setup-mode.sh enhanced`

## 🆘 **Need Help?**

1. Check `README-FIXED.md` for complete documentation
2. Run `./check-status.sh` to diagnose issues
3. Check Docker logs: `docker logs lybook-backend-1`
4. Verify all services are running: `docker ps`

**Happy Testing! 🚀**