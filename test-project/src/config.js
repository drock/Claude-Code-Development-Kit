// Configuration - uses environment variables, no hardcoded secrets
module.exports = {
  port: process.env.PORT || 3000,
  dbUrl: process.env.DATABASE_URL || 'sqlite://./data.db',
  apiKey: process.env.API_KEY || '',
};
