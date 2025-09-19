#!/bin/bash

echo "🔍 LYBOOK System Status Check"
echo "=================================="
echo ""

# Check running containers
CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep lybook)
if [ -n "$CONTAINERS" ]; then
    echo "🐳 Running Containers:"
    echo "$CONTAINERS"
    echo ""
else
    echo "❌ No LYBOOK containers running"
    echo ""
    exit 1
fi

# Function to check service health
check_service() {
    local name=$1
    local url=$2
    local expected=$3
    
    echo -n "🔍 $name: "
    
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s --max-time 3 "$url" 2>/dev/null | head -c 50)
        if [[ "$response" == *"$expected"* ]]; then
            echo "✅ Healthy"
        else
            echo "❌ Not responding"
        fi
    else
        echo "⚠️  curl not available"
    fi
}

# Check core services
echo "🏥 Health Checks:"
check_service "Backend API" "http://localhost:5000/health" "status"
check_service "Frontend" "http://localhost:3000" "html"
check_service "Books API" "http://localhost:5000/api/books" "["

# Check if enhanced services are running
KONG_RUNNING=$(docker ps | grep kong | wc -l)
if [ $KONG_RUNNING -gt 0 ]; then
    echo ""
    echo "🚀 Enhanced Mode Services:"
    check_service "Kong Gateway" "http://localhost:8000/api/books" "["
    check_service "Prometheus" "http://localhost:9090/metrics" "prometheus"
    check_service "Grafana" "http://localhost:3001/api/health" "database"
    check_service "RabbitMQ Management" "http://localhost:15672" "RabbitMQ"
fi

echo ""
echo "📊 Quick Stats:"
if command -v curl >/dev/null 2>&1; then
    BOOK_COUNT=$(curl -s http://localhost:5000/api/books 2>/dev/null | grep -o '"title"' | wc -l)
    echo "📚 Total Books: $BOOK_COUNT"
    
    # Check if Redis caching is working
    echo "⚡ Testing Redis Cache..."
    curl -s http://localhost:5000/api/books > /dev/null
    sleep 0.5
    curl -s http://localhost:5000/api/books > /dev/null
    
    CACHE_LOGS=$(docker logs lybook-backend-1 --tail=2 2>/dev/null | grep "cache" | wc -l)
    if [ $CACHE_LOGS -gt 0 ]; then
        echo "✅ Redis caching is working"
    else
        echo "⚠️  Redis caching may not be working"
    fi
fi

echo ""
echo "🎯 Access Points:"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:5000"
echo "   Books API: http://localhost:5000/api/books"

# Show Kong access if available
if [ $KONG_RUNNING -gt 0 ]; then
    echo "   Kong Gateway: http://localhost:8000"
    echo "   Kong API: http://localhost:8000/api/books"
fi

echo ""
echo "✨ To see live logs: docker logs lybook-backend-1 -f"