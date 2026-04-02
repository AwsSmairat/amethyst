import app from './app.js';
import { env } from './config/env.js';

const PORT = Number(process.env.PORT) || 10000;

app.listen(PORT, () => {
  console.log(`Amethyst API listening on port ${PORT} (${env.nodeEnv})`);
});
