const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Default error
  let error = {
    message: err.message || 'Internal Server Error',
    status: err.status || 500
  };

  // Validation errors
  if (err.name === 'ValidationError') {
    error.status = 400;
    error.message = err.details ? err.details.map(d => d.message).join(', ') : err.message;
  }

  // Database errors
  if (err.code === 'SQLITE_CONSTRAINT') {
    error.status = 409;
    error.message = 'Database constraint violation';
  }

  // Rate limit errors
  if (err.status === 429) {
    error.message = 'Too many requests, please try again later';
  }

  res.status(error.status).json({
    success: false,
    error: error.message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = {
  errorHandler,
  asyncHandler
};