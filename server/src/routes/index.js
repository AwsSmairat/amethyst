import { Router } from 'express';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import swaggerUi from 'swagger-ui-express';

import authRoutes from './auth.routes.js';
import usersRoutes from './users.routes.js';
import vehiclesRoutes from './vehicles.routes.js';
import productsRoutes from './products.routes.js';
import vehicleLoadsRoutes from './vehicleLoads.routes.js';
import stationSalesRoutes from './stationSales.routes.js';
import vehicleSalesRoutes from './vehicleSales.routes.js';
import expensesRoutes from './expenses.routes.js';
import returnsRoutes from './returns.routes.js';
import dashboardRoutes from './dashboard.routes.js';
import reportsRoutes from './reports.routes.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const openApiSpec = JSON.parse(
  readFileSync(join(__dirname, '../../openapi/openapi.json'), 'utf8')
);

const api = Router();

api.get('/health', (_req, res) => {
  res.json({ success: true, message: 'API is healthy' });
});

api.get('/openapi.json', (_req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  res.json(openApiSpec);
});

api.use(
  '/docs',
  swaggerUi.serve,
  swaggerUi.setup(openApiSpec, {
    customCss: '.swagger-ui .topbar { display: none }',
    swaggerOptions: { persistAuthorization: true },
  })
);

api.use('/auth', authRoutes);
api.use('/users', usersRoutes);
api.use('/vehicles', vehiclesRoutes);
api.use('/products', productsRoutes);
api.use('/vehicle-loads', vehicleLoadsRoutes);
api.use('/station-sales', stationSalesRoutes);
api.use('/vehicle-sales', vehicleSalesRoutes);
api.use('/expenses', expensesRoutes);
api.use('/returns', returnsRoutes);
api.use('/dashboard', dashboardRoutes);
api.use('/reports', reportsRoutes);

export default api;
