// Simple signing server for Cloudinary uploads
// Usage: set CLOUDINARY_URL in env or set CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET
// Then: node cloudinary_sign_server.js

const express = require('express');
const crypto = require('crypto');
const url = require('url');

const app = express();
const PORT = process.env.PORT || 3000;

// Parse CLOUDINARY_URL if present
const cloudinaryUrl = process.env.CLOUDINARY_URL || '';
let apiKey = process.env.CLOUDINARY_API_KEY || '';
let apiSecret = process.env.CLOUDINARY_API_SECRET || '';
if (cloudinaryUrl) {
  try {
    const parsed = url.parse(cloudinaryUrl);
    if (parsed.auth) {
      const parts = parsed.auth.split(':');
      apiKey = parts[0];
      apiSecret = parts[1];
    }
  } catch (e) {
    console.error('Failed to parse CLOUDINARY_URL:', e);
  }
}

if (!apiKey || !apiSecret) {
  console.warn('CLOUDINARY_API_KEY or CLOUDINARY_API_SECRET not set. Set CLOUDINARY_URL or env vars.');
}

app.get('/sign', (req, res) => {
  const folder = req.query.folder || 'posts';
  const timestamp = Math.floor(Date.now() / 1000);
  const paramsToSign = `folder=${folder}&timestamp=${timestamp}`;
  const signature = crypto.createHash('sha1').update(paramsToSign + apiSecret).digest('hex');
  res.json({ api_key: apiKey, timestamp, signature });
});

app.listen(PORT, () => console.log(`Cloudinary sign server listening on http://localhost:${PORT}`));
