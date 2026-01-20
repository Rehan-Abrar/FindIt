// Cloudinary configuration
// SECURITY: Signing uploads in the client requires your API secret which is
// sensitive. Only do this for local/testing or if you understand the risks.
// Recommended: generate signatures on a secure backend and return them to the client.

const String CLOUDINARY_CLOUD_NAME = 'dhm6mpxhw'; // e.g. 'demo'
// If using unsigned uploads set the preset name, otherwise leave empty when using signed uploads.
const String CLOUDINARY_UPLOAD_PRESET = 'findit_posts'; // leave empty for signed uploads

// For signed uploads (not recommended in production), set your API key and secret here.
// WARNING: Do NOT commit secrets into source control for production apps.
const String CLOUDINARY_API_KEY = '674366974637813'; // e.g. '123456789012345'
const String CLOUDINARY_API_SECRET = ''; // your API secret

// Optional: a signing endpoint that returns { api_key, timestamp, signature }
// Example: 'http://localhost:3000/sign'
const String CLOUDINARY_SIGNING_ENDPOINT = ''; 

// Example unsigned preset: CLOUDINARY_UPLOAD_PRESET = 'unsigned_preset'
// Example signed usage: set CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET (insecure on client)
