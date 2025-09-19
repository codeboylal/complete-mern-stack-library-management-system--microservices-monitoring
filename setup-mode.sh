#!/bin/bash

# LYBOOK Setup Script - Choose your deployment mode
# Usage: ./setup-mode.sh [core|enhanced]

MODE=${1:-core}

case $MODE in
  "core")
    echo "🔧 Starting LYBOOK in CORE mode (Backend + Frontend + MongoDB + Redis)"
    echo "   This mode includes:"
    echo "   ✅ Library Management API (Backend)"
    echo "   ✅ React Frontend"
    echo "   ✅ MongoDB Database"
    echo "   ✅ Redis Caching"
    echo ""
    
    docker compose -f docker-compose.core.yml --env-file .env.enhanced up -d --build
    
    if [ $? -eq 0 ]; then
      echo ""
      echo "🎉 CORE mode started successfully!"
      echo "📋 Available services:"
      echo "   🌐 Frontend: http://localhost:3000"
      echo "   🔌 Backend API: http://localhost:5000"
      echo "   📊 MongoDB: localhost:27017"
      echo "   ⚡ Redis: localhost:6379"
      echo ""
      echo "🧪 Test the setup:"
      echo "   curl http://localhost:5000/api/books"
    fi
    ;;
    
  "enhanced")
    echo "🚀 Starting LYBOOK in ENHANCED mode (Full microservices setup)"
    echo "   This mode includes everything from CORE plus:"
    echo "   ✅ Kong API Gateway"
    echo "   ✅ Prometheus + Grafana monitoring"
    echo "   ✅ RabbitMQ messaging"
    echo "   ✅ Elasticsearch + Kibana logging"
    echo "   ✅ Jaeger distributed tracing"
    echo ""
    
    # Check if Docker Hub is accessible
    echo "🔍 Checking Docker Hub connectivity..."
    if timeout 10 docker pull hello-world:latest > /dev/null 2>&1; then
      echo "✅ Docker Hub is accessible"
      
      docker compose -f docker-compose.enhanced.yml --env-file .env.enhanced up -d --build
      
      if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 ENHANCED mode started successfully!"
        echo "📋 Available services:"
        echo "   🌐 Frontend: http://localhost:3000"
        echo "   🔌 Backend API: http://localhost:5000"
        echo "   🚪 Kong Gateway: http://localhost:8000"
        echo "   📊 Prometheus: http://localhost:9090"
        echo "   📈 Grafana: http://localhost:3001"
        echo "   🔍 Kibana: http://localhost:5601"
        echo "   📡 Jaeger: http://localhost:16686"
        echo "   🐰 RabbitMQ: http://localhost:15672"
        echo ""
        echo "🧪 Test the setup:"
        echo "   curl http://localhost:8000/api/books  # Through Kong"
        echo "   curl http://localhost:5000/api/books  # Direct to backend"
      fi
    else
      echo "❌ Docker Hub connectivity issues detected"
      echo "💡 Falling back to CORE mode..."
      $0 core
    fi
    ;;
    
  *)
    echo "❓ Usage: $0 [core|enhanced]"
    echo ""
    echo "🔧 CORE mode: Basic library app (Backend + Frontend + MongoDB + Redis)"
    echo "🚀 ENHANCED mode: Full microservices (Kong + Monitoring + Logging + etc.)"
    echo ""
    echo "💡 Use CORE mode if you have network issues or want to focus on the main app"
    echo "💡 Use ENHANCED mode to learn about Kong, monitoring, and microservices"
    ;;
esac