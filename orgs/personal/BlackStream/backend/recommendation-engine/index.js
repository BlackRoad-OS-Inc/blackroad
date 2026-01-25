const express = require('express');
const app = express();
const port = process.env.PORT || 4000;

// Dummy recommendations endpoint
app.get('/recommendations', (req, res) => {
  // In a real service this would use ML algorithms and user preferences
  const recommendations = [
    { id: 1, title: 'The Office', genre: 'Comedy' },
    { id: 2, title: 'Stranger Things', genre: 'Sci-Fi' },
    { id: 3, title: 'The Crown', genre: 'Drama' }
  ];
  res.json({ recommendations });
});

app.listen(port, () => {
  console.log(`Recommendation engine running on port ${port}`);
});
