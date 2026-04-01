import app from './app.js';
import { env } from './config/env.js';

const port = env.port;

app.listen(port, () => {
  console.log(`Amethyst API listening on port ${port} (${env.nodeEnv})`);
});
