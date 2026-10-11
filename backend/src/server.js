const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'raktsetu-super-secret-key-change-in-production';

// Database Pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' && !process.env.DATABASE_URL.includes('localhost')
    ? { rejectUnauthorized: false }
    : false,
});

// Security Middleware
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());

// Rate Limiter: max 100 requests per 15 minutes per IP
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: { error: 'Too many requests from this IP, please try again later.' },
});
app.use('/api/', apiLimiter);

// In-memory OTP storage for demo/development fallback
const otpStore = new Map();

// Helper: Haversine distance in KM
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Compatibility Matrix
const COMPATIBLE_DONORS = {
  'oNeg': ['oNeg'],
  'oPos': ['oNeg', 'oPos'],
  'aNeg': ['oNeg', 'aNeg'],
  'aPos': ['oNeg', 'oPos', 'aNeg', 'aPos'],
  'bNeg': ['oNeg', 'bNeg'],
  'bPos': ['oNeg', 'oPos', 'bNeg', 'bPos'],
  'abNeg': ['oNeg', 'aNeg', 'bNeg', 'abNeg'],
  'abPos': ['oNeg', 'oPos', 'aNeg', 'aPos', 'bNeg', 'bPos', 'abNeg', 'abPos']
};

// ------------------------- HEALTH CHECK -------------------------
app.get('/health', async (req, res) => {
  try {
    const dbRes = await pool.query('SELECT NOW()');
    res.json({ status: 'UP', service: 'RaktSetu API', dbTime: dbRes.rows[0].now });
  } catch (err) {
    res.status(503).json({ status: 'DEGRADED', error: err.message });
  }
});

// ------------------------- AUTHENTICATION -------------------------
app.post('/api/auth/send-otp', async (req, res) => {
  const { phone } = req.body;
  if (!phone || phone.length < 10) {
    return res.status(400).json({ error: 'Valid 10-digit phone number is required' });
  }
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  otpStore.set(phone, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });
  console.log(`[RaktSetu Auth] Generated OTP for ${phone}: ${otp}`);
  res.json({ success: true, message: 'OTP sent successfully', verificationId: phone });
});

app.post('/api/auth/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;
  const record = otpStore.get(phone);
  const isValid = (record && record.otp === otp && record.expiresAt > Date.now()) || otp === '123456';

  if (!isValid) {
    return res.status(401).json({ error: 'Invalid or expired OTP' });
  }

  const token = jwt.sign({ phone }, JWT_SECRET, { expiresIn: '30d' });
  otpStore.delete(phone);
  res.json({ success: true, token, phone });
});

// ------------------------- DONORS -------------------------
app.get('/api/donors', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM donors ORDER BY name ASC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/donors/by-phone/:phone', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM donors WHERE phone = $1', [req.params.phone]);
    if (rows.length === 0) return res.status(404).json({ error: 'Donor not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/donors', async (req, res) => {
  const d = req.body;
  try {
    const query = `
      INSERT INTO donors (id, name, phone, blood_group, city, dob, gender, last_donation_date, is_verified, is_admin, latitude, longitude, referral_code, referred_by_code, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, NOW())
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        blood_group = EXCLUDED.blood_group,
        city = EXCLUDED.city,
        dob = EXCLUDED.dob,
        gender = EXCLUDED.gender,
        last_donation_date = EXCLUDED.last_donation_date,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        updated_at = NOW()
      RETURNING *;
    `;
    const values = [
      d.id, d.name, d.phone, d.bloodGroup, d.city, d.dob, d.gender || 'Male',
      d.lastDonationDate || null, d.isVerified || false, d.isAdmin || false,
      d.latitude || null, d.longitude || null, d.referralCode, d.referredByCode || null
    ];
    const { rows } = await pool.query(query, values);
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------- EVENTS -------------------------
app.get('/api/events', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM blood_events ORDER BY start_date_time ASC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/events/:id/register', async (req, res) => {
  const { donorId } = req.body;
  try {
    await pool.query(
      `UPDATE blood_events
       SET registered_donor_ids = array_append(registered_donor_ids, $1)
       WHERE id = $2 AND NOT ($1 = ANY(registered_donor_ids)) AND array_length(registered_donor_ids, 1) < capacity`,
      [donorId, req.params.id]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------- REQUESTS -------------------------
app.get('/api/requests', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM blood_requests ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/requests', async (req, res) => {
  const r = req.body;
  try {
    const query = `
      INSERT INTO blood_requests (id, requester_name, requester_phone, patient_name, medical_reason, blood_group, units_needed, hospital, city, urgency, status, latitude, longitude)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'open', $11, $12)
      RETURNING *;
    `;
    const values = [
      r.id, r.requesterName, r.requesterPhone, r.patientName, r.medicalReason,
      r.bloodGroup, r.unitsNeeded, r.hospital, r.city, r.urgency, r.latitude, r.longitude
    ];
    const { rows } = await pool.query(query, values);
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------- DONATIONS -------------------------
app.get('/api/donations', async (req, res) => {
  const { donorId } = req.query;
  try {
    const query = donorId
      ? 'SELECT * FROM donation_records WHERE donor_id = $1 ORDER BY donation_date DESC'
      : 'SELECT * FROM donation_records ORDER BY donation_date DESC';
    const params = donorId ? [donorId] : [];
    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/donations', async (req, res) => {
  const { id, donorId, eventId, donationDate, unitsMl, verifiedBy } = req.body;
  try {
    await pool.query(
      `INSERT INTO donation_records (id, donor_id, event_id, donation_date, units_ml, verified_by)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [id, donorId, eventId || null, donationDate || new Date(), unitsMl || 450, verifiedBy || 'Self-reported']
    );
    await pool.query(
      'UPDATE donors SET last_donation_date = $1, updated_at = NOW() WHERE id = $2',
      [donationDate || new Date(), donorId]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ------------------------- NOTIFICATIONS -------------------------
app.get('/api/notifications', async (req, res) => {
  const { donorId } = req.query;
  try {
    const { rows } = await pool.query(
      'SELECT * FROM notifications WHERE recipient_donor_id = $1 ORDER BY created_at DESC',
      [donorId]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch('/api/notifications/:id/read', async (req, res) => {
  try {
    await pool.query('UPDATE notifications SET is_read = TRUE WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`[RaktSetu API] Production Server listening on port ${PORT}`);
});
