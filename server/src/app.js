import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { env } from './config/env.js';
import apiRoutes from './routes/index.js';
import { errorHandler } from './middlewares/errorHandler.js';

const app = express();
const __dirname = join(fileURLToPath(import.meta.url), '..');

app.use(
  helmet({
    // This API is consumed by a separate web origin (Firebase Hosting).
    // Helmet v8 defaults `Cross-Origin-Resource-Policy: same-origin`, which
    // blocks cross-origin fetch/XHR even if CORS is enabled.
    crossOriginResourcePolicy: { policy: 'cross-origin' },
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
      },
    },
  })
);
// `CORS_ORIGIN=*` uses `origin: true` so the response echoes the request `Origin`
// (required with `credentials: true`; never sends `Access-Control-Allow-Origin: *`).
const corsWildcard = env.corsOrigin === '*';
const corsOriginsList = corsWildcard
  ? []
  : env.corsOrigin
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);

const corsOptions = {
  origin: corsWildcard
    ? true
    : corsOriginsList.length === 0
      ? true
      : corsOriginsList,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  // Dio / browsers send `Accept: application/json`; omitting it breaks preflight on some clients.
  allowedHeaders: ['Authorization', 'Content-Type', 'Accept'],
};

app.use(
  cors(corsOptions)
);
app.options('*', cors(corsOptions));
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '1mb' }));
app.use('/uploads', express.static(join(__dirname, '..', 'uploads')));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

app.get('/', (_req, res) => {
  res.json({ message: 'Amethyst API is running 🔥' });
});

app.get('/health', (_req, res) => {
  res.json({ success: true, message: 'OK', data: { service: 'amethyst-api' } });
});

app.use('/api', apiRoutes);

app.use((_req, res) => {
  res.status(404).json({
    success: false,
    message: 'Not found',
    code: 'NOT_FOUND',
  });
});

app.use(errorHandler);

export default app;
