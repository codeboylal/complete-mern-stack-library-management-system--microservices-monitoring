const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const promClient = require('prom-client');
const winston = require('winston');
const redis = require('redis');
const amqp = require('amqplib');
require('dotenv').config();

const app = express();

// Metrics setup
const register = new promClient.Registry();
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});
const booksTotal = new promClient.Gauge({
  name: 'books_total',
  help: 'Total number of books in the library'
});
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(booksTotal);

// Logger setup
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'logs/app.log' })
  ]
});

// Redis client
let redisClient;
const connectRedis = async () => {
  try {
    redisClient = redis.createClient({
      socket: {
        host: process.env.REDIS_HOST || 'redis',
        port: process.env.REDIS_PORT || 6379
      }
    });
    
    redisClient.on('error', (err) => {
      logger.error('Redis Client Error:', err);
    });
    
    redisClient.on('connect', () => {
      logger.info('Redis client connected');
    });
    
    redisClient.on('ready', () => {
      logger.info('Redis client ready');
    });
    
    await redisClient.connect();
    logger.info('Connected to Redis successfully');
  } catch (error) {
    logger.error('Redis connection failed:', error);
    // Don't set redisClient to null, just leave it undefined
  }
};

// RabbitMQ setup
let channel;
const connectRabbitMQ = async () => {
  try {
    const connection = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://rabbitmq:5672');
    channel = await connection.createChannel();
    await channel.assertExchange('library_events', 'topic', { durable: true });
    logger.info('Connected to RabbitMQ');
  } catch (error) {
    logger.error('RabbitMQ connection failed:', error);
  }
};

// // Middleware
// app.use(cors({
//   origin: function (origin, callback) {
//     const allowedOrigins = [
//       'http://mern-library.local', // For Kind Ingress
//       'http://dev.lanskill.com',   // For future VPS deployment
//       'http://localhost:3000',     // For local `npm start` frontend dev
//       'http://34.69.207.255:3000', // GCP frontend
//       process.env.FRONTEND_URL    // For more dynamic configuration
//     ];
//     // Allow requests with no origin (like mobile apps or curl requests)
//     if (!origin) return callback(null, true);
//     if (allowedOrigins.indexOf(origin) === -1) {
//       const msg = 'The CORS policy for this site does not allow access from the specified Origin.';
//       return callback(new Error(msg), false);
//     }
//     return callback(null, true);
//   },
//   credentials: true,
//   methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
//   allowedHeaders: ['Content-Type', 'Authorization']
// }));
// app.use(express.json());
// app.use(morgan('dev'));





// Generate allowed origins from ALLOWED_IPS
const generateAllowedOrigins = () => {
  const ips = process.env.ALLOWED_IPS?.split(',') || [];
  const origins = ['http://mern-library.local'];
  
  ips.forEach(ip => {
    const cleanIP = ip.trim();
    if (cleanIP === 'localhost') {
      origins.push('http://localhost:3000');
    } else {
      origins.push(`http://${cleanIP}:3000`);
    }
  });
  
  return origins;
};

// Security and rate limiting
app.use(helmet());
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 1000,                 // Increased for development
  standardHeaders: true,     // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false       // Disable the `X-RateLimit-*` headers
}));

app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(morgan('combined'));

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
    httpRequestsTotal
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .inc();
  });
  next();
});









// MongoDB Connection
const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      console.error('FATAL ERROR: MONGODB_URI is not defined.');
      process.exit(1);
    }
    console.log('Attempting to connect to MongoDB at:', mongoURI);
    
    mongoose.connection.on('connected', () => console.log('Mongoose: connected to DB'));
    mongoose.connection.on('error', (err) => console.error('Mongoose: connection error:', err));
    mongoose.connection.on('disconnected', () => console.log('Mongoose: disconnected'));
    mongoose.connection.on('reconnected', () => console.log('Mongoose: reconnected'));
    mongoose.connection.on('close', () => console.log('Mongoose: connection closed'));

    await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 30000, // Increase timeout to 30 seconds
      socketTimeoutMS: 45000,
    });
    
    // console.log('MongoDB Connected Successfully'); // Covered by 'connected' event
  } catch (err) {
    console.error('MongoDB Connection Error:', err);
    // Don't exit the process, just log the error
    console.error('Will retry connection...');
  }
};

// Connect to MongoDB with retry
const connectWithRetry = () => {
  connectDB().catch(err => {
    console.log('MongoDB connection unsuccessful, retry after 5 seconds...');
    setTimeout(connectWithRetry, 5000);
  });
};

connectWithRetry();

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (error) {
    logger.error('Metrics endpoint error:', error);
    res.status(500).json({ error: 'Metrics unavailable' });
  }
});

// Make connections available globally
app.locals.redisClient = redisClient;
app.locals.channel = channel;
app.locals.logger = logger;
app.locals.booksTotal = booksTotal;

// Routes
app.use('/api/books', require('./routes/books'));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something broke!' });
});

// Initialize connections and start server
const startServer = async () => {
  await connectRedis();
  await connectRabbitMQ();
  
  // Make connections available globally after they're established
  app.locals.redisClient = redisClient;
  app.locals.channel = channel;
  app.locals.logger = logger;
  app.locals.booksTotal = booksTotal;
  
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, '0.0.0.0', () => {
    logger.info(`LYBOOK Server running on port ${PORT}`);
    console.log(`Server is running on port ${PORT}`);
  });
};

startServer().catch(console.error); 