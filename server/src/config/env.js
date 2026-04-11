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

const nodeEnv = process.env.NODE_ENV || 'development';

/** Firebase Hosting origins for this app (Flutter web). */
const defaultProductionCorsOrigins =
  'https://amethyst-6a511.web.app,https://amethyst-6a511.firebaseapp.com';

const corsOriginRaw = process.env.CORS_ORIGIN?.trim();
/** Comma-separated allow-list, `*`, or unset (see default below). */
const corsOrigin =
  corsOriginRaw && corsOriginRaw.length > 0
    ? corsOriginRaw
    : nodeEnv === 'production'
      ? defaultProductionCorsOrigins
      : '*';

export const env = {
  nodeEnv,
  port: Number(process.env.PORT) || 10000,
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  bcryptRounds: Number(process.env.BCRYPT_ROUNDS) || 12,
  corsOrigin,
  businessTimeZone,
};
