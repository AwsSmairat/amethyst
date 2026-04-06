import dotenv from 'dotenv';

dotenv.config();

const required = ['DATABASE_URL', 'JWT_SECRET'];

for (const key of required) {
  if (!process.env[key]) {
    console.warn(`Warning: ${key} is not set`);
  }
}

const jwtSecretRaw = process.env.JWT_SECRET?.trim();
const jwtSecret =
  jwtSecretRaw && jwtSecretRaw.length > 0
    ? jwtSecretRaw
    : 'change-me-in-production';

/** IANA zone for «today» / «this month» aggregates (station is in Jordan). */
const businessTimeZone =
  process.env.BUSINESS_TIMEZONE?.trim() || 'Asia/Amman';

export const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT) || 10000,
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  bcryptRounds: Number(process.env.BCRYPT_ROUNDS) || 12,
  corsOrigin: process.env.CORS_ORIGIN || '*',
  businessTimeZone,
};
