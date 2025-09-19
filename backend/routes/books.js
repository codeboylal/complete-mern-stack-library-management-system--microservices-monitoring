const express = require('express');
const router = express.Router();
const Book = require('../models/Book');

// Get all books with filters
router.get('/', async (req, res) => {
  try {
    const { genre, isArchived } = req.query;
    const cacheKey = `books:${genre || 'all'}:${isArchived || 'false'}`;
    const { redisClient, logger } = req.app.locals;
    
    // Check cache first
    if (redisClient && redisClient.isReady) {
      try {
        const cached = await redisClient.get(cacheKey);
        if (cached) {
          if (logger) logger.info('Books fetched from cache', { genre, isArchived });
          return res.json(JSON.parse(cached));
        }
      } catch (cacheError) {
        if (logger) logger.warn('Cache read failed:', cacheError);
      }
    }
    
    const filter = {};

    if (genre) {
      filter.genre = genre;
    }

    // Handle isArchived status
    if (isArchived === 'true') {
      filter.isArchived = true;
    } else {
      filter.$or = [
        { isArchived: false },
        { isArchived: { $exists: false } },
        { isArchived: null }
      ];
    }
    
    const books = await Book.find(filter).sort({ createdAt: -1 });
    
    // Cache the result for 5 minutes
    if (redisClient && redisClient.isReady) {
      try {
        await redisClient.setEx(cacheKey, 300, JSON.stringify(books));
      } catch (cacheError) {
        if (logger) logger.warn('Cache write failed:', cacheError);
      }
    }
    
    // Update metrics
    const { booksTotal } = req.app.locals;
    if (booksTotal) booksTotal.set(books.length);
    
    if (logger) logger.info('Books fetched from database', { count: books.length, genre, isArchived });
    res.json(books);
  } catch (error) {
    const { logger } = req.app.locals;
    if (logger) logger.error('Error fetching books:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get available genres
router.get('/genres', async (req, res) => {
  try {
    res.json(Book.GENRES);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get single book
router.get('/:id', async (req, res) => {
  try {
    const book = await Book.findById(req.params.id);
    if (!book) return res.status(404).json({ message: 'Book not found' });
    res.json(book);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Create book
router.post('/', async (req, res) => {
  try {
    const { redisClient, channel, logger } = req.app.locals;
    if (logger) logger.info('Book creation request', { body: req.body });
    
    const book = new Book(req.body);
    const newBook = await book.save();
    
    // Publish event
    if (channel) {
      try {
        await channel.publish('library_events', 'book.created', Buffer.from(JSON.stringify({
          bookId: newBook._id,
          title: newBook.title,
          author: newBook.author,
          genre: newBook.genre,
          timestamp: new Date().toISOString()
        })));
      } catch (eventError) {
        if (logger) logger.warn('Event publishing failed:', eventError);
      }
    }
    
    // Clear cache
    if (redisClient && redisClient.isReady) {
      try {
        const keys = await redisClient.keys('books:*');
        if (keys.length > 0) {
          await redisClient.del(keys);
        }
      } catch (cacheError) {
        if (logger) logger.warn('Cache clear failed:', cacheError);
      }
    }
    
    if (logger) logger.info('Book created', { bookId: newBook._id, title: newBook.title });
    res.status(201).json(newBook);
  } catch (error) {
    const { logger } = req.app.locals;
    if (logger) logger.error('Error creating book:', { error: error.message, body: req.body });
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      const errors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({ message: 'Validation failed', errors });
    }
    
    // Handle duplicate key error
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Book with this ISBN already exists' });
    }
    
    res.status(400).json({ message: error.message });
  }
});

// Update book
router.put('/:id', async (req, res) => {
  try {
    const { redisClient, logger } = req.app.locals;
    const book = await Book.findById(req.params.id);
    if (!book) return res.status(404).json({ message: 'Book not found' });
    
    Object.assign(book, req.body);
    const updatedBook = await book.save();
    
    // Clear cache after update
    if (redisClient && redisClient.isReady) {
      try {
        const keys = await redisClient.keys('books:*');
        if (keys.length > 0) {
          await redisClient.del(keys);
        }
      } catch (cacheError) {
        if (logger) logger.warn('Cache clear failed:', cacheError);
      }
    }
    
    if (logger) logger.info('Book updated', { bookId: updatedBook._id, title: updatedBook.title });
    res.json(updatedBook);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Archive book
router.put('/:id/archive', async (req, res) => {
  try {
    const { redisClient, logger } = req.app.locals;
    const book = await Book.findById(req.params.id);
    if (!book) return res.status(404).json({ message: 'Book not found' });
    
    book.isArchived = true;
    book.archivedAt = new Date();
    await book.save();
    
    // Clear cache after archive
    if (redisClient && redisClient.isReady) {
      try {
        const keys = await redisClient.keys('books:*');
        if (keys.length > 0) {
          await redisClient.del(keys);
        }
      } catch (cacheError) {
        if (logger) logger.warn('Cache clear failed:', cacheError);
      }
    }
    
    if (logger) logger.info('Book archived', { bookId: book._id, title: book.title });
    res.json({ message: 'Book archived successfully', book });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Restore book from archive
router.put('/:id/restore', async (req, res) => {
  try {
    const { redisClient, logger } = req.app.locals;
    const book = await Book.findById(req.params.id);
    if (!book) return res.status(404).json({ message: 'Book not found' });
    
    book.isArchived = false;
    book.archivedAt = null;
    await book.save();
    
    // Clear cache after restore
    if (redisClient && redisClient.isReady) {
      try {
        const keys = await redisClient.keys('books:*');
        if (keys.length > 0) {
          await redisClient.del(keys);
        }
      } catch (cacheError) {
        if (logger) logger.warn('Cache clear failed:', cacheError);
      }
    }
    
    if (logger) logger.info('Book restored', { bookId: book._id, title: book.title });
    res.json({ message: 'Book restored successfully', book });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Delete book (permanent delete)
router.delete('/:id', async (req, res) => {
  try {
    const { redisClient, logger } = req.app.locals;
    const book = await Book.findById(req.params.id);
    if (!book) return res.status(404).json({ message: 'Book not found' });
    
    const bookTitle = book.title; // Store title for logging
    await book.deleteOne();
    
    // Clear cache after deletion
    if (redisClient && redisClient.isReady) {
      try {
        const keys = await redisClient.keys('books:*');
        if (keys.length > 0) {
          await redisClient.del(keys);
        }
      } catch (cacheError) {
        if (logger) logger.warn('Cache clear failed:', cacheError);
      }
    }
    
    if (logger) logger.info('Book deleted', { bookId: req.params.id, title: bookTitle });
    res.json({ message: 'Book deleted permanently' });
  } catch (error) {
    const { logger } = req.app.locals;
    if (logger) logger.error('Error deleting book:', { error: error.message, bookId: req.params.id });
    res.status(500).json({ message: error.message });
  }
});

module.exports = router; 