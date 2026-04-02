import multer from 'multer';
import { mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function uploadsDir(...parts) {
  // server/src/middlewares -> server/uploads/...
  return join(__dirname, '..', '..', 'uploads', ...parts);
}

const receiptsDir = uploadsDir('receipts');
mkdirSync(receiptsDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, receiptsDir),
  filename: (_req, file, cb) => {
    const ext = file.mimetype === 'image/png' ? 'png' : 'jpg';
    cb(null, `expense_${Date.now()}_${Math.random().toString(16).slice(2)}.${ext}`);
  },
});

export const uploadExpenseReceipt = multer({
  storage,
  limits: { fileSize: 2 * 1024 * 1024 }, // 2MB
  fileFilter: (_req, file, cb) => {
    const ok = file.mimetype === 'image/jpeg' || file.mimetype === 'image/png';
    cb(ok ? null : new Error('Invalid file type'), ok);
  },
});

