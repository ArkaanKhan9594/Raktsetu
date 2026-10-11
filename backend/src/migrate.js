const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

async function runMigration() {
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: DATABASE_URL environment variable is not defined.');
    process.exit(1);
  }

  const migrationFile = path.join(__dirname, '..', 'migrations', 'init.sql');
  console.log(`Reading migration script from: ${migrationFile}`);
  const sql = fs.readFileSync(migrationFile, 'utf8');

  const client = await pool.connect();
  try {
    console.log('Applying database migrations...');
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('Database migrations applied successfully!');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
