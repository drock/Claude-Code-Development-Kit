// Sample application for testing CDK plugins
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'Test project running' });
});

app.get('/api/users', (req, res) => {
  res.json([{ id: 1, name: 'Test User' }]);
});

module.exports = app;
