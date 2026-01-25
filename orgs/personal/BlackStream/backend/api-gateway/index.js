const express = require('express');
const app = express();
const port = process.env.PORT || 4000;

app.get('/', (req, res) => {
  res.send('Welcome to the BlackStream API Gateway');
});

// Example search endpoint
app.get('/search', (req, res) => {
  const { q } = req.query;
  res.json({ query: q, results: [] });
});

app.listen(port, () => {
  console.log(`API Gateway listening on port ${port}`);
});
