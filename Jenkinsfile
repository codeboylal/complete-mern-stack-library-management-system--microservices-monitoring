pipeline {
    agent any
    
    environment {
        GITHUB_REPO = "https://github.com/devops-12112/vc-book-management.git"
        GITHUB_BRANCH = "gcp"
        DOCKER_COMPOSE_FILE = "docker-compose.yml"
        
        // Environment variables for application
        FRONTEND_PORT = "3000"
        REACT_APP_API_URL = "http://44.198.122.92:5000/api"
        FRONTEND_URL = "http://44.198.122.92:3000"
        PORT = "5000"
        NODE_ENV = "production"
        MONGO_PORT = "27017"
        MONGO_INITDB_ROOT_USERNAME = "mongo_user"
        MONGO_INITDB_ROOT_PASSWORD = "mongo_password"
        MONGO_INITDB_DATABASE = "library"
        MONGODB_URI = "mongodb://mongo_user:mongo_password@mongo:27017/library?authSource=admin"
    }
    
    stages {
        stage('Pull Code') {
            steps {
                echo 'Pulling code from GitHub...'
                // Clean workspace before checkout
                sh 'rm -rf ./* || true'
                checkout([$class: 'GitSCM', 
                    branches: [[name: "*/${GITHUB_BRANCH}"]], 
                    doGenerateSubmoduleConfigurations: false, 
                    extensions: [[$class: 'CleanBeforeCheckout']], 
                    submoduleCfg: [], 
                    userRemoteConfigs: [[url: "${GITHUB_REPO}"]]
                ])
                echo 'Code pulled successfully!'
            }
        }
        
        stage('Build Docker Images') {
            steps {
                echo 'Building Docker images...'
                sh 'docker-compose build'
                echo 'Docker images built successfully!'
            }
        }
        
        stage('Deploy with Docker Compose') {
            steps {
                echo 'Deploying application with Docker Compose...'
                
                // Create .env file with Jenkins environment variables
                sh '''
                    cat > .env << EOL
# Frontend
FRONTEND_PORT=${FRONTEND_PORT}
REACT_APP_API_URL=${REACT_APP_API_URL}
FRONTEND_URL=${FRONTEND_URL}

# Backend
PORT=${PORT}
NODE_ENV=${NODE_ENV}

# MongoDB
MONGO_PORT=${MONGO_PORT}
MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME}
MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}
MONGO_INITDB_DATABASE=${MONGO_INITDB_DATABASE}
MONGODB_URI=${MONGODB_URI}
EOL
                '''
                
                // Deploy with docker-compose
                sh 'docker-compose down || true'
                
                // Fix permissions before building
                sh 'chmod -R 755 . || true'
                
                sh 'docker-compose build --no-cache'
                sh 'docker-compose up -d'
                
                echo 'Application deployed successfully!'
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline execution failed!'
        }
        always {
            echo 'Cleaning up workspace...'
            // Don't clean workspace to avoid permission issues
            // Just clean docker resources
            sh 'docker system prune -f || true'
        }
    }
}


// test jenkins