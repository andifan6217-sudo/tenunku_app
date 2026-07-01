require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const midtransClient = require('midtrans-client');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const crypto = require('crypto');
const https = require('https');

// ==========================================
// PAYMENT GATEWAY CONFIG
// ==========================================
const ACTIVE_GATEWAY = (process.env.ACTIVE_PAYMENT_GATEWAY || 'tripay').toLowerCase();

// Midtrans Snap setup (tetap disimpan sebagai cadangan)
const snap = new midtransClient.Snap({
  isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY
});

// TriPay Config
const TRIPAY_MERCHANT_CODE = process.env.TRIPAY_MERCHANT_CODE || '';
const TRIPAY_API_KEY = process.env.TRIPAY_API_KEY || '';
const TRIPAY_PRIVATE_KEY = process.env.TRIPAY_PRIVATE_KEY || '';
const TRIPAY_IS_PRODUCTION = process.env.TRIPAY_IS_PRODUCTION === 'true';
const TRIPAY_BASE_URL = TRIPAY_IS_PRODUCTION
  ? 'https://tripay.co.id/api'
  : 'https://tripay.co.id/api-sandbox';

// Helper: Panggil TriPay API
function tripayRequest(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(TRIPAY_BASE_URL + path);
    const options = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      method,
      headers: {
        'Authorization': `Bearer ${TRIPAY_API_KEY}`,
        'Content-Type': 'application/json',
      },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error('Invalid JSON response from TriPay: ' + data)); }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

// Helper: Generate TriPay signature untuk create transaction
function generateTripaySignature(merchantRef, amount) {
  return crypto
    .createHmac('sha256', TRIPAY_PRIVATE_KEY)
    .update(TRIPAY_MERCHANT_CODE + merchantRef + amount)
    .digest('hex');
}

console.log(`[PAYMENT] Gateway aktif: ${ACTIVE_GATEWAY.toUpperCase()}`);

const prisma = new PrismaClient();
const app = express();

// 0. Security headers (safe defaults)
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }, // allow images/uploads consumed by app
}));

// 1. CORS first (configure in production via env)
// ALLOWED_ORIGINS="https://app.example.com,https://admin.example.com"
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '*')
  .split(',')
  .map(s => s.trim())
  .filter(Boolean);

app.use(cors({
  origin: (origin, cb) => {
    // allow non-browser clients (curl/postman) and same-origin
    if (!origin) return cb(null, true);
    if (allowedOrigins.includes('*')) return cb(null, true);
    return cb(null, allowedOrigins.includes(origin));
  },
  methods: 'GET,POST,PUT,DELETE,OPTIONS',
  allowedHeaders: 'Content-Type,Authorization'
}));

// 2. Body Parser
app.use(express.json({ limit: process.env.JSON_BODY_LIMIT || '1mb' }));

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_geza_key';

// Warn if running production with default JWT secret
if (process.env.NODE_ENV === 'production' && JWT_SECRET === 'super_secret_geza_key') {
  console.warn('[SECURITY] JWT_SECRET is using the default fallback. Set JWT_SECRET in environment variables.');
}

// Middleware for auth
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader) {
    const token = authHeader.split(' ')[1];
    jwt.verify(token, JWT_SECRET, (err, user) => {
      if (err) return res.sendStatus(403);
      req.user = user;
      next();
    });
  } else {
    res.sendStatus(401);
  }
};


const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure upload directory exists
const uploadDir = 'uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// Multer storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
// Filter only image files — tolak file non-gambar (security untuk upload dari mobile)
const imageFileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Hanya file gambar (JPEG, PNG, WEBP, dll) yang diperbolehkan.'), false);
  }
};

const upload = multer({
  storage,
  limits: {
    fileSize: Number(process.env.UPLOAD_MAX_BYTES || 5 * 1024 * 1024), // 5MB max (optimal untuk mobile)
  },
  fileFilter: imageFileFilter,
});

// Serve static files
app.use('/uploads', express.static('uploads'));

// Upload endpoint
app.post('/api/upload', authenticate, upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: "No file uploaded" });
  const publicBaseUrl = process.env.PUBLIC_BASE_URL || `${req.protocol}://${req.get('host')}`;
  const url = `${publicBaseUrl}/uploads/${req.file.filename}`;
  res.json({ url });
});

// 3. Logging
// Avoid leaking secrets in logs
app.use(morgan('tiny'));
app.use((req, _res, next) => {
  const safeBody = { ...(req.body || {}) };
  for (const k of ['password', 'newPassword', 'currentPassword', 'otp', 'token']) {
    if (safeBody[k] != null) safeBody[k] = '[REDACTED]';
  }
  console.log(`${req.method} ${req.url}`, safeBody);
  next();
});

// 4. Rate limiters (security & abuse prevention)
const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: Number(process.env.OTP_RATE_LIMIT_MAX || 5),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Terlalu banyak permintaan OTP. Coba lagi beberapa menit.' },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: Number(process.env.AUTH_RATE_LIMIT_MAX || 20),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Terlalu banyak percobaan. Coba lagi nanti.' },
});



// Nodemailer setup
const nodemailer = require('nodemailer');
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// Auth Routes
app.post('/api/request-otp', otpLimiter, async (req, res) => {
  try {
    const { email } = req.body;
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) return res.status(400).json({ error: "Email sudah terdaftar" });
    
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60000); // 10 minutes
    
    await prisma.otp.upsert({
      where: { email },
      update: { otp, expiresAt },
      create: { email, otp, expiresAt }
    });
    
    const mailOptions = {
      from: `"Tenun Geza" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Kode Verifikasi Registrasi Tenun Geza',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h2 style="color: #D4AF37;">Selamat datang di Tenun Geza!</h2>
          <p>Terima kasih telah mendaftar. Untuk menyelesaikan registrasi, silakan masukkan kode verifikasi (OTP) berikut:</p>
          <div style="font-size: 24px; font-weight: bold; padding: 10px; background: #f9f9f9; text-align: center; letter-spacing: 5px; color: #333; margin: 20px 0;">
            ${otp}
          </div>
          <p>Kode ini hanya berlaku selama 10 menit. Jangan berikan kode ini kepada siapapun.</p>
        </div>
      `
    };
    
    await transporter.sendMail(mailOptions);
    res.json({ message: "OTP sent successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Gagal mengirim OTP. Pastikan email valid dan konfigurasi benar." });
  }
});

app.post('/api/forgot-password/otp', otpLimiter, async (req, res) => {
  try {
    const { email } = req.body;
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (!existingUser) return res.status(400).json({ error: "Email tidak terdaftar" });
    
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60000); // 10 minutes
    
    await prisma.otp.upsert({
      where: { email },
      update: { otp, expiresAt },
      create: { email, otp, expiresAt }
    });
    
    const mailOptions = {
      from: `"Tenun Geza" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Kode Reset Password Tenun Geza',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h2 style="color: #D4AF37;">Reset Password</h2>
          <p>Seseorang telah meminta reset password untuk akun Anda. Gunakan kode verifikasi (OTP) berikut untuk membuat password baru:</p>
          <div style="font-size: 24px; font-weight: bold; padding: 10px; background: #f9f9f9; text-align: center; letter-spacing: 5px; color: #333; margin: 20px 0;">
            ${otp}
          </div>
          <p>Kode ini hanya berlaku selama 10 menit. Jika Anda tidak meminta reset password, abaikan email ini.</p>
        </div>
      `
    };
    
    await transporter.sendMail(mailOptions);
    res.json({ message: "OTP sent successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Gagal mengirim OTP. Pastikan email valid dan konfigurasi benar." });
  }
});

app.post('/api/forgot-password/reset', authLimiter, async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    
    if (!otp) return res.status(400).json({ error: "OTP wajib diisi" });
    
    const otpRecord = await prisma.otp.findUnique({ where: { email } });
    if (!otpRecord) return res.status(400).json({ error: "OTP belum direquest untuk email ini" });
    if (otpRecord.otp !== otp) return res.status(400).json({ error: "Kode OTP salah" });
    if (otpRecord.expiresAt < new Date()) return res.status(400).json({ error: "Kode OTP telah kedaluwarsa" });

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (!existingUser) return res.status(400).json({ error: "Email tidak ditemukan" });
    
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.user.update({
      where: { email },
      data: { password: hashedPassword }
    });
    
    await prisma.otp.delete({ where: { email } });
    
    res.json({ message: "Password berhasil direset" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post('/api/register', authLimiter, async (req, res) => {
  try {
    const { email, password, name, phone, role, otp } = req.body;
    
    if (!otp) return res.status(400).json({ error: "OTP wajib diisi" });
    
    const otpRecord = await prisma.otp.findUnique({ where: { email } });
    if (!otpRecord) return res.status(400).json({ error: "OTP belum direquest untuk email ini" });
    if (otpRecord.otp !== otp) return res.status(400).json({ error: "Kode OTP salah" });
    if (otpRecord.expiresAt < new Date()) return res.status(400).json({ error: "Kode OTP telah kedaluwarsa" });

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) return res.status(400).json({ error: "Email sudah terdaftar" });
    
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, password: hashedPassword, name, phone, role: role || 'USER' }
    });
    
    await prisma.otp.delete({ where: { email } });
    
    res.json({ message: "User created successfully", user: { id: user.id, email: user.email, name: user.name, role: user.role } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post('/api/login', authLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(401).json({ error: "Invalid credentials" });
    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(401).json({ error: "Invalid credentials" });
    
    // Check 2FA
    if (user.isTwoFactorEnabled) {
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date(Date.now() + 10 * 60000); // 10 minutes
      
      await prisma.otp.upsert({
        where: { email },
        update: { otp, expiresAt },
        create: { email, otp, expiresAt }
      });
      
      const mailOptions = {
        from: `"Tenun Geza" <${process.env.EMAIL_USER}>`,
        to: email,
        subject: 'Kode 2FA Tenun Geza',
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
            <h2 style="color: #D4AF37;">Login 2FA</h2>
            <p>Seseorang sedang mencoba login ke akun Anda. Masukkan OTP berikut untuk melanjutkan:</p>
            <div style="font-size: 24px; font-weight: bold; padding: 10px; background: #f9f9f9; text-align: center; letter-spacing: 5px; color: #333; margin: 20px 0;">
              ${otp}
            </div>
            <p>Kode ini berlaku 10 menit.</p>
          </div>
        `
      };
      await transporter.sendMail(mailOptions);
      return res.json({ requires2FA: true, email: user.email, message: "Kode 2FA telah dikirim ke email." });
    }

    const token = jwt.sign({ userId: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '24h' });
    res.json({ token, user: { id: user.id, email: user.email, name: user.name, role: user.role } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post('/api/login/verify-2fa', authLimiter, async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!otp) return res.status(400).json({ error: "OTP wajib diisi" });
    
    const otpRecord = await prisma.otp.findUnique({ where: { email } });
    if (!otpRecord) return res.status(400).json({ error: "Sesi 2FA tidak ditemukan" });
    if (otpRecord.otp !== otp) return res.status(400).json({ error: "Kode OTP salah" });
    if (otpRecord.expiresAt < new Date()) return res.status(400).json({ error: "Kode OTP telah kedaluwarsa" });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(400).json({ error: "Pengguna tidak ditemukan" });

    await prisma.otp.delete({ where: { email } });

    const token = jwt.sign({ userId: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '24h' });
    res.json({ token, user: { id: user.id, email: user.email, name: user.name, role: user.role } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Product Routes
app.get('/api/products', async (req, res) => {
  try {
    const products = await prisma.product.findMany();
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch products" });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    const product = await prisma.product.findUnique({ 
      where: { id: Number(req.params.id) },
      include: { 
        reviews: {
          orderBy: { createdAt: 'desc' },
          include: { images: true } // Sertakan gambar ulasan untuk ditampilkan di detail produk
        }
      }
    });
    if (!product) return res.status(404).json({ error: "Product not found" });
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch product" });
  }
});

// Admin-only route ideally, but keeping it open for initial setup
app.post('/api/products', async (req, res) => {
  try {
    const { name, description, price, imageUrl, stock } = req.body;
    const product = await prisma.product.create({
      data: { name, description, price: parseInt(price), imageUrl, stock: parseInt(stock) }
    });
    res.json(product);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to create product" });
  }
});

// Settings Routes
app.get('/api/settings/payment', authenticate, async (req, res) => {
  try {
    let settings = await prisma.storeSettings.findFirst();
    if (!settings) {
      settings = await prisma.storeSettings.create({
        data: { id: 1 }
      });
    }
    res.json(settings);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch settings" });
  }
});

app.put('/api/settings/payment', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { bankName, bankAccount, accountName, qrisImageUrl } = req.body;
    let settings = await prisma.storeSettings.findFirst();
    if (!settings) {
       settings = await prisma.storeSettings.create({
         data: { bankName, bankAccount, accountName, qrisImageUrl }
       });
    } else {
       settings = await prisma.storeSettings.update({
         where: { id: settings.id },
         data: { bankName, bankAccount, accountName, qrisImageUrl }
       });
    }
    res.json(settings);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update settings" });
  }
});

// Order Routes
app.post('/api/orders', authenticate, async (req, res) => {
  try {
    const { items, totalPrice, dpAmount } = req.body; 
    const order = await prisma.order.create({
      data: {
        userId: req.user.userId,
        totalPrice: parseInt(totalPrice),
        dpAmount: parseInt(dpAmount || 0),
        items: {
          create: items.map(item => ({
            productId: item.productId,
            quantity: item.quantity,
            price: item.price,
            size: item.size,
            notes: item.notes
          }))
        }
      },
      include: { items: true }
    });
    res.json(order);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to create order" });
  }
});

app.get('/api/orders', authenticate, async (req, res) => {
  try {
    const isOwnerOrSeller = req.user.role === 'ADMIN' || req.user.role === 'PENJUAL';
    const whereClause = isOwnerOrSeller ? {} : { userId: req.user.userId };
    
    const orders = await prisma.order.findMany({
      where: whereClause,
      include: { 
        items: { include: { product: true } }, 
        user: {
          include: {
            addresses: {
              where: { isMain: true },
              take: 1
            }
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });
    res.json(orders);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch orders" });
  }
});

app.get('/api/orders/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const order = await prisma.order.findUnique({
      where: { id: parseInt(id) },
      include: { 
        items: { include: { product: true } }, 
        user: true 
      }
    });
    
    if (!order) return res.status(404).json({ error: "Order not found" });
    
    // Authorization check: User can only see their own orders unless they are ADMIN/PENJUAL
    if (order.userId !== req.user.userId && req.user.role !== 'ADMIN' && req.user.role !== 'PENJUAL') {
      return res.sendStatus(403);
    }
    
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch order details" });
  }
});

app.post('/api/orders/:id/tracking', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const { courierName, awbNumber, trackingStatus } = req.body;
    
    const data = {};
    if (courierName !== undefined) data.courierName = courierName;
    if (awbNumber !== undefined) data.awbNumber = awbNumber;
    if (trackingStatus !== undefined) data.trackingStatus = trackingStatus;
    
    const updated = await prisma.order.update({
      where: { id: parseInt(id) },
      data
    });
    res.json(updated);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update tracking info" });
  }
});

app.delete('/api/orders/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const order = await prisma.order.findUnique({ where: { id: parseInt(id) } });
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.userId !== req.user.userId && req.user.role !== 'ADMIN' && req.user.role !== 'PENJUAL') return res.sendStatus(403);
    
    // Only allow cancelling PENDING orders
    if (order.status !== 'PENDING' && req.user.role !== 'ADMIN') {
      return res.status(400).json({ error: "Only pending orders can be cancelled" });
    }

    await prisma.orderItem.deleteMany({ where: { orderId: parseInt(id) } });
    await prisma.order.delete({ where: { id: parseInt(id) } });
    res.json({ message: "Order cancelled successfully" });
  } catch (err) {
    res.status(500).json({ error: "Failed to cancel order" });
  }
});

app.post('/api/orders/:id/update-status', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, paymentProofUrl, courierName, awbNumber } = req.body;
    const updateData = { status };
    if (paymentProofUrl !== undefined) {
      updateData.paymentProofUrl = paymentProofUrl;
    }
    if (courierName !== undefined) {
      updateData.courierName = courierName;
    }
    if (awbNumber !== undefined) {
      updateData.awbNumber = awbNumber;
    }
    
    // Sinkronisasi status tracking saat sampai
    if (status === 'DELIVERED') {
      updateData.trackingStatus = "Pesanan telah diterima. Terima kasih telah berbelanja di Tenun Geza!";
    }

    const order = await prisma.order.update({
      where: { id: parseInt(id) },
      data: updateData
    });
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: "Failed to update order status" });
  }
});

// Seller: Get orders needing DP verification
app.get('/api/seller/orders', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { status } = req.query;
    const whereClause = status ? { status } : {};
    const orders = await prisma.order.findMany({
      where: whereClause,
      include: { 
        items: { include: { product: true } }, 
        user: {
          include: {
            addresses: {
              where: { isMain: true },
              take: 1
            }
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });
    res.json(orders);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch seller orders" });
  }
});

// Seller: Verify DP payment
app.post('/api/orders/:id/verify', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const order = await prisma.order.findUnique({ where: { id: parseInt(id) } });
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.status !== 'DP_PAID') return res.status(400).json({ error: "Order is not awaiting DP verification" });
    
    const updated = await prisma.order.update({
      where: { id: parseInt(id) },
      data: { status: 'VERIFIED' }
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: "Failed to verify order" });
  }
});

// Seller: Mark as Processed (Production Finished)
app.post('/api/orders/:id/mark-processed', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const order = await prisma.order.findUnique({ where: { id: parseInt(id) } });
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.status !== 'VERIFIED') return res.status(400).json({ error: "Order must be verified before being processed" });
    
    const updated = await prisma.order.update({
      where: { id: parseInt(id) },
      data: { status: 'PROCESSED' }
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: "Failed to mark order as processed" });
  }
});

// ==========================================
// PAYMENT GATEWAY (TRIPAY + MIDTRANS SAKLAR)
// ==========================================

// GET: Informasi gateway yang aktif
app.get('/api/payment/config', authenticate, (req, res) => {
  res.json({
    gateway: ACTIVE_GATEWAY,
    isProduction: ACTIVE_GATEWAY === 'tripay' ? TRIPAY_IS_PRODUCTION : process.env.MIDTRANS_IS_PRODUCTION === 'true',
  });
});

// GET: Daftar channel pembayaran TriPay
app.get('/api/payment/channels', authenticate, async (req, res) => {
  if (ACTIVE_GATEWAY !== 'tripay') {
    return res.json({ channels: [] });
  }
  try {
    const result = await tripayRequest('/merchant/payment-channel');
    if (!result.success) {
      return res.status(500).json({ error: result.message || 'Gagal mengambil channel pembayaran TriPay' });
    }
    // Filter hanya channel yang aktif & kembalikan field yang dibutuhkan Flutter
    const channels = (result.data || []).map(ch => ({
      code: ch.code,
      name: ch.name,
      group: ch.group,
      type: ch.type,
      fee_merchant: ch.fee_merchant,
      fee_customer: ch.fee_customer,
      total_fee: ch.total_fee,
      icon_url: ch.icon_url || '',
      active: ch.active,
    })).filter(ch => ch.active);
    res.json({ channels });
  } catch (err) {
    console.error('TriPay Channel Error:', err.message);
    res.status(500).json({ error: 'Gagal mengambil channel pembayaran: ' + err.message });
  }
});

// POST: Buat token/link pembayaran (TriPay atau Midtrans sesuai gateway aktif)
app.post('/api/orders/:id/payment-token', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { amountType, method } = req.body; // amountType: 'DP' or 'FULL', method: kode channel TriPay (e.g. 'QRIS', 'BCAVA')

    const order = await prisma.order.findUnique({
      where: { id: parseInt(id) },
      include: { user: true, items: { include: { product: true } } }
    });

    if (!order) return res.status(404).json({ error: "Order not found" });

    // Tentukan jumlah pembayaran
    let amount = 0;
    let paymentLabel = '';
    if (amountType === 'DP') {
      amount = order.dpAmount || 0;
      paymentLabel = 'DP Pembayaran';
    } else {
      amount = order.totalPrice - (order.dpAmount || 0);
      paymentLabel = 'Pelunasan Pembayaran';
    }

    if (amount <= 0) return res.status(400).json({ error: 'Jumlah pembayaran tidak valid' });

    const productName = (order.items[0]?.product?.name || 'Produk Tenun') +
      (order.items.length > 1 ? ` +${order.items.length - 1} lainnya` : '');

    // ==================================
    // TRIPAY FLOW
    // ==================================
    if (ACTIVE_GATEWAY === 'tripay') {
      if (!method) {
        return res.status(400).json({ error: 'Parameter method (kode channel pembayaran) wajib diisi untuk TriPay' });
      }
      if (!TRIPAY_MERCHANT_CODE || !TRIPAY_API_KEY || !TRIPAY_PRIVATE_KEY) {
        return res.status(500).json({ error: 'Konfigurasi TriPay belum lengkap. Isi TRIPAY_MERCHANT_CODE, TRIPAY_API_KEY, dan TRIPAY_PRIVATE_KEY di file .env' });
      }

      const merchantRef = `TENUN-${order.id}-${Date.now()}`;
      const signature = generateTripaySignature(merchantRef, amount);
      const expiredTime = Math.floor(Date.now() / 1000) + (24 * 60 * 60); // 24 jam

      const payload = {
        method,
        merchant_ref: merchantRef,
        amount,
        customer_name: order.user.name || 'Customer',
        customer_email: order.user.email || 'customer@tenungeza.com',
        customer_phone: order.user.phone || '08000000000',
        order_items: [{
          sku: `ORD-${order.id}`,
          name: (`${paymentLabel} - ${productName}`).substring(0, 255),
          price: amount,
          quantity: 1,
        }],
        callback_url: `${process.env.PUBLIC_BASE_URL}/api/payment/tripay-callback`,
        return_url: `${process.env.PUBLIC_BASE_URL}/payment/success`,
        expired_time: expiredTime,
        signature,
      };

      const tripayRes = await tripayRequest('/transaction/create', 'POST', payload);

      if (!tripayRes.success) {
        console.error('TriPay Error:', tripayRes);
        return res.status(500).json({ error: tripayRes.message || 'Gagal membuat transaksi TriPay' });
      }

      const txData = tripayRes.data;

      // Simpan ke DB menggunakan kolom yang sudah ada
      await prisma.order.update({
        where: { id: order.id },
        data: {
          midtransOrderId: merchantRef,         // Digunakan sebagai reference ID
          snapToken: txData.reference || null,  // TriPay reference code
          snapUrl: txData.checkout_url || null, // TriPay checkout URL
        }
      });

      return res.json({
        gateway: 'tripay',
        reference: txData.reference,
        redirectUrl: txData.checkout_url,
        expiredTime: txData.expired_time,
        method: txData.payment_method,
      });
    }

    // ==================================
    // MIDTRANS FLOW (CADANGAN)
    // ==================================
    const midtransOrderId = `TENUN-${order.id}-${Date.now()}`;
    const nameParts = (order.user.name || 'Customer').split(' ');
    const parameter = {
      transaction_details: { order_id: midtransOrderId, gross_amount: amount },
      credit_card: { secure: true },
      customer_details: {
        first_name: nameParts[0] || 'Customer',
        last_name: nameParts.slice(1).join(' ') || '',
        email: order.user.email || 'customer@tenungeza.com',
        phone: order.user.phone || '08000000000',
      },
      item_details: [{
        id: amountType,
        price: amount,
        quantity: 1,
        name: (`${paymentLabel} - ${productName}`).substring(0, 50),
      }],
      enabled_payments: [
        'gopay', 'qris', 'shopeepay',
        'bca_va', 'bni_va', 'bri_va', 'permata_va', 'other_va',
        'echannel', 'credit_card', 'indomaret', 'alfamart',
      ],
    };

    const transaction = await snap.createTransaction(parameter);
    await prisma.order.update({
      where: { id: order.id },
      data: {
        midtransOrderId,
        snapToken: transaction.token,
        snapUrl: transaction.redirect_url,
      }
    });

    return res.json({
      gateway: 'midtrans',
      token: transaction.token,
      redirectUrl: transaction.redirect_url,
    });

  } catch (err) {
    console.error('Payment Token Error:', err);
    const errorMessage = err.ApiResponse
      ? JSON.stringify(err.ApiResponse.error_messages)
      : err.message;
    res.status(500).json({ error: `Gagal membuat token pembayaran: ${errorMessage}` });
  }
});

// Midtrans Webhook (Notification) - tetap aktif sebagai cadangan
app.post('/api/payment/notification', async (req, res) => {
  try {
    const notification = await snap.transaction.notification(req.body);
    const orderId = notification.order_id;
    const transactionStatus = notification.transaction_status;
    const fraudStatus = notification.fraud_status;
    console.log(`[Midtrans Webhook] Order: ${orderId}, Status: ${transactionStatus}`);
    const orderParts = orderId.split('-');
    if (orderParts.length < 2) return res.sendStatus(400);
    const internalId = parseInt(orderParts[1]);
    if (transactionStatus === 'settlement' || transactionStatus === 'capture') {
      if (fraudStatus !== 'challenge') {
        const order = await prisma.order.findUnique({ where: { id: internalId } });
        if (order) {
          let nextStatus = order.status;
          if (order.status === 'PENDING') nextStatus = 'VERIFIED';
          if (order.status === 'PROCESSED') nextStatus = 'PAID';
          await prisma.order.update({ where: { id: internalId }, data: { status: nextStatus } });
        }
      }
    }
    res.sendStatus(200);
  } catch (err) {
    console.error('Midtrans Webhook Error:', err);
    res.sendStatus(500);
  }
});

// TriPay Callback Webhook
app.post('/api/payment/tripay-callback', express.json(), async (req, res) => {
  try {
    // Verifikasi signature dari TriPay
    const callbackSignature = req.headers['x-callback-signature'] || '';
    const json = req.body;
    const expectedSignature = crypto
      .createHmac('sha256', TRIPAY_PRIVATE_KEY)
      .update(JSON.stringify(json))
      .digest('hex');

    if (callbackSignature !== expectedSignature) {
      console.warn('[TriPay Callback] Signature tidak valid, request ditolak.');
      return res.status(400).json({ success: false, message: 'Invalid signature' });
    }

    const { merchant_ref, status } = json;
    console.log(`[TriPay Callback] Ref: ${merchant_ref}, Status: ${status}`);

    // Ekstrak internal order ID dari merchant_ref (format: TENUN-{id}-{timestamp})
    const refParts = merchant_ref.split('-');
    if (refParts.length < 2) return res.status(400).json({ success: false, message: 'Invalid merchant_ref' });
    const internalId = parseInt(refParts[1]);

    if (status === 'PAID') {
      const order = await prisma.order.findUnique({ where: { id: internalId } });
      if (order) {
        let nextStatus = order.status;
        // Pembayaran DP → otomatis VERIFIED (tidak perlu manual penjual)
        if (order.status === 'PENDING') nextStatus = 'VERIFIED';
        // Pembayaran pelunasan → otomatis PAID
        if (order.status === 'PROCESSED') nextStatus = 'PAID';
        if (nextStatus !== order.status) {
          await prisma.order.update({ where: { id: internalId }, data: { status: nextStatus } });
          console.log(`[TriPay Callback] Order #${internalId} status → ${nextStatus}`);
        }
      }
    } else if (status === 'EXPIRED' || status === 'FAILED') {
      console.log(`[TriPay Callback] Order #${internalId} pembayaran ${status}, tidak ada perubahan status.`);
    }

    res.json({ success: true });
  } catch (err) {
    console.error('[TriPay Callback Error]', err);
    res.status(500).json({ success: false });
  }
});

// Seller: Verify Final Payment
app.post('/api/orders/:id/verify-final', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const order = await prisma.order.findUnique({ where: { id: parseInt(id) } });
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.status !== 'FULL_PAY_PAID') return res.status(400).json({ error: "Order is not awaiting final payment verification" });
    
    const updated = await prisma.order.update({
      where: { id: parseInt(id) },
      data: { status: 'PAID' }
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: "Failed to verify final payment" });
  }
});

// Seller: Reject DP payment
app.post('/api/orders/:id/reject', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const order = await prisma.order.findUnique({ where: { id: parseInt(id) } });
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.status !== 'DP_PAID') return res.status(400).json({ error: "Order is not awaiting DP verification" });
    
    const updated = await prisma.order.update({
      where: { id: parseInt(id) },
      data: { status: 'PENDING' }
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: "Failed to reject order" });
  }
});

// Admin Stats
app.get('/api/admin/stats', authenticate, async (req, res) => {
  if (req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const userCount = await prisma.user.count();
    const productCount = await prisma.product.count();
    const orderCount = await prisma.order.count();
    const processedTransactions = await prisma.order.count({
      where: {
        status: { in: ['PAID', 'SHIPPED', 'DELIVERED', 'COMPLETED'] }
      }
    });
    const unverifiedDP = await prisma.order.count({
      where: {
        status: { in: ['DP_PAID', 'FULL_PAY_PAID'] }
      }
    });
    
    const lowStockCount = await prisma.product.count({ where: { stock: { lte: 5 } } });
    const inStockCount = await prisma.product.count({ where: { stock: { gt: 0 } } });
    
    // Get 5 recent orders
    const recentOrders = await prisma.order.findMany({
      take: 5,
      orderBy: { createdAt: 'desc' },
      include: { user: true }
    });

    res.json({
      totals: {
        users: userCount,
        products: productCount,
        orders: orderCount,
        processed: processedTransactions,
        unverified: unverifiedDP,
        lowStock: lowStockCount,
        inStock: inStockCount
      },
      recentOrders
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch stats" });
  }
});

// Seller Stats
app.get('/api/seller/stats', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const productCount = await prisma.product.count();
    const activeProductCount = await prisma.product.count({ where: { status: 'ACTIVE' } });
    const orderCount = await prisma.order.count();
    
    // Revenue (Sum of PAID/VERIFIED/COMPLETED/DELIVERED orders)
    const paidOrders = await prisma.order.findMany({ where: { status: { in: ['PAID', 'VERIFIED', 'COMPLETED', 'DELIVERED'] } } });
    const revenue = paidOrders.reduce((sum, order) => sum + order.totalPrice, 0);
    
    // Low stock
    const lowStockCount = await prisma.product.count({ where: { stock: { lte: 5 } } });
    
    // Unpaid DP (PENDING status)
    const unpaidDPCount = await prisma.order.count({ where: { status: 'PENDING' } });
    
    // DP Paid but not yet verified by seller
    const dpPaidCount = await prisma.order.count({ where: { status: 'DP_PAID' } });

    // Processed but waiting for full payment proof
    const processedUnpaidCount = await prisma.order.count({ where: { status: 'PROCESSED' } });

    // Full payment proof uploaded but not yet verified
    const fullPayPaidCount = await prisma.order.count({ where: { status: 'FULL_PAY_PAID' } });
    
    // Recent orders with details
    const recentOrders = await prisma.order.findMany({
      take: 10,
      orderBy: { createdAt: 'desc' },
      include: { 
        user: true,
        items: { include: { product: true } }
      }
    });

    // Growth (Real calculation: comparing last 30 days vs 30 days before that)
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const sixtyDaysAgo = new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000);

    const currentPeriodOrders = await prisma.order.findMany({
      where: {
        createdAt: { gte: thirtyDaysAgo },
        status: { in: ['PAID', 'VERIFIED', 'COMPLETED', 'DELIVERED'] }
      }
    });
    const currentRevenue = currentPeriodOrders.reduce((sum, o) => sum + o.totalPrice, 0);

    const previousPeriodOrders = await prisma.order.findMany({
      where: {
        createdAt: { gte: sixtyDaysAgo, lt: thirtyDaysAgo },
        status: { in: ['PAID', 'VERIFIED', 'COMPLETED', 'DELIVERED'] }
      }
    });
    const previousRevenue = previousPeriodOrders.reduce((sum, o) => sum + o.totalPrice, 0);

    let growth = "0%";
    if (previousRevenue === 0) {
      growth = currentRevenue > 0 ? "+100%" : "0%";
    } else {
      const growthPercent = ((currentRevenue - previousRevenue) / previousRevenue) * 100;
      const sign = growthPercent >= 0 ? "+" : "";
      growth = `${sign}${growthPercent.toFixed(1)}%`;
    } 

    res.json({
      totals: {
        products: productCount,
        activeProducts: activeProductCount,
        orders: orderCount,
        revenue: revenue,
        growth: growth,
        lowStock: lowStockCount,
        unpaidDP: unpaidDPCount,
        dpPendingVerification: dpPaidCount,
        processedUnpaid: processedUnpaidCount,
        fullPayPendingVerification: fullPayPaidCount
      },
      recentOrders: recentOrders.map(order => ({
        id: order.id,
        pelanggan: order.user.name,
        produk: order.items.map(i => i.product.name).join(", "),
        total: order.totalPrice,
        dpAmount: order.dpAmount,
        status: order.status,
        tanggal: order.createdAt
      }))
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch seller stats" });
  }
});

// Finance Report (Admin & Seller)
// Note: We don't have separate payment timestamps, so we report based on order.createdAt
// and current status buckets (DP verified vs full paid).
app.get('/api/finance/report', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { from, to } = req.query;

    const fromDate = from ? new Date(from) : null;
    const toDate = to ? new Date(to) : null;

    if (fromDate && isNaN(fromDate.getTime())) {
      return res.status(400).json({ error: "Invalid 'from' date" });
    }
    if (toDate && isNaN(toDate.getTime())) {
      return res.status(400).json({ error: "Invalid 'to' date" });
    }

    const createdAt = {};
    if (fromDate) createdAt.gte = fromDate;
    if (toDate) createdAt.lte = toDate;

    const where = Object.keys(createdAt).length ? { createdAt } : {};

    const orders = await prisma.order.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        user: true,
        items: { include: { product: true } }
      }
    });

    const fullPaidStatuses = ['PAID', 'SHIPPED', 'DELIVERED', 'COMPLETED'];
    const dpVerifiedStatuses = ['VERIFIED', 'PROCESSED', 'FULL_PAY_PAID', ...fullPaidStatuses];

    let revenueFullPaid = 0;
    let dpVerifiedTotal = 0;
    let outstandingDpTotal = 0;
    let outstandingFullTotal = 0;

    let countFullPaid = 0;
    let countDpVerified = 0;
    let countPendingDp = 0;
    let countPendingFull = 0;

    for (const o of orders) {
      const total = Number(o.totalPrice || 0);
      const dp = Number(o.dpAmount || 0);
      const remaining = Math.max(0, total - dp);

      if (fullPaidStatuses.includes(o.status)) {
        revenueFullPaid += total;
        countFullPaid += 1;
      }

      if (dpVerifiedStatuses.includes(o.status)) {
        dpVerifiedTotal += dp;
        countDpVerified += 1;
      }

      if (o.status === 'PENDING') {
        outstandingDpTotal += dp;
        countPendingDp += 1;
      }

      if (o.status === 'PROCESSED') {
        outstandingFullTotal += remaining;
        countPendingFull += 1;
      }
    }

    res.json({
      range: { from: fromDate ? fromDate.toISOString() : null, to: toDate ? toDate.toISOString() : null },
      totals: {
        orders: orders.length,
        revenueFullPaid,
        dpVerifiedTotal,
        outstandingDpTotal,
        outstandingFullTotal,
        countFullPaid,
        countDpVerified,
        countPendingDp,
        countPendingFull
      },
      orders: orders.map(o => ({
        id: o.id,
        createdAt: o.createdAt,
        status: o.status,
        customerName: o.user?.name,
        totalPrice: o.totalPrice,
        dpAmount: o.dpAmount,
        remainingAmount: Math.max(0, Number(o.totalPrice || 0) - Number(o.dpAmount || 0)),
        products: o.items?.map(i => i.product?.name).filter(Boolean).join(', ')
      }))
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch finance report" });
  }
});

// Customer Stats
app.get('/api/customer/stats', authenticate, async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const orderCount = await prisma.order.count({ where: { userId } });
    const pendingCount = await prisma.order.count({ 
      where: { 
        userId, 
        status: { in: ['PENDING', 'DP_PAID', 'VERIFIED', 'PAID', 'SHIPPED'] } 
      } 
    });
    const completedCount = await prisma.order.count({ 
      where: { 
        userId, 
        status: { in: ['COMPLETED', 'DELIVERED'] } 
      } 
    });
    
    // Total spent
    const allOrders = await prisma.order.findMany({ where: { userId } });
    const totalSpent = allOrders.reduce((sum, order) => sum + order.totalPrice, 0);
    
    // Recent orders
    const recentOrders = await prisma.order.findMany({
      where: { userId },
      take: 5,
      orderBy: { createdAt: 'desc' },
      include: { 
        items: { include: { product: true } }
      }
    });

    // Active order tracking (most recent uncompleted)
    const activeOrder = await prisma.order.findFirst({
      where: { 
        userId, 
        status: { in: ['PENDING', 'DP_PAID', 'VERIFIED', 'PAID', 'SHIPPED', 'DELIVERED'] } 
      },
      orderBy: { createdAt: 'desc' },
      include: { items: { include: { product: true } } }
    });

    res.json({
      totals: {
        orders: orderCount,
        spent: totalSpent,
        pending: pendingCount,
        completed: completedCount
      },
      activeOrder: activeOrder ? {
        id: activeOrder.id,
        status: activeOrder.status,
        produk: activeOrder.items.map(i => i.product.name).join(", "),
        tanggal: activeOrder.createdAt,
        total: activeOrder.totalPrice
      } : null,
      recentOrders: recentOrders.map(order => ({
        id: order.id,
        produk: order.items.map(i => i.product.name).join(", "),
        total: order.totalPrice,
        status: order.status,
        tanggal: order.createdAt
      }))
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch customer stats" });
  }
});

// Product Actions for Seller
app.put('/api/products/:id', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const { name, description, price, imageUrl, stock, status } = req.body;
    const product = await prisma.product.update({
      where: { id: parseInt(id) },
      data: { 
        name, 
        description, 
        price: parseInt(price), 
        imageUrl, 
        stock: parseInt(stock),
        status: status || 'ACTIVE'
      }
    });
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: "Failed to update product" });
  }
});

app.delete('/api/products/:id', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const productId = parseInt(id);
    
    // 1. Delete associated order items first to avoid foreign key constraints
    await prisma.orderItem.deleteMany({
      where: { productId: productId }
    });

    // 2. Delete associated reviews to avoid foreign key constraints
    await prisma.review.deleteMany({
      where: { productId: productId }
    });

    // 3. Now delete the product
    await prisma.product.delete({
      where: { id: productId }
    });
    
    res.json({ message: "Product deleted" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to delete product" });
  }
});

app.post('/api/products/:id/toggle', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const product = await prisma.product.findUnique({ where: { id: parseInt(id) } });
    const nextStatus = product.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    const updated = await prisma.product.update({
      where: { id: parseInt(id) },
      data: { status: nextStatus }
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: "Failed to toggle product status" });
  }
});

app.post('/api/admin/users', authenticate, async (req, res) => {
  if (req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { name, email, password, phone, role } = req.body;
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) return res.status(400).json({ error: "Email sudah terdaftar" });
    
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, password: hashedPassword, name, phone, role: role || 'USER' }
    });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: "Failed to create user" });
  }
});

app.get('/api/admin/users', authenticate, async (req, res) => {
  if (req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: 'desc' }
    });
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch users" });
  }
});

app.put('/api/admin/users/:id', authenticate, async (req, res) => {
  if (req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const { name, email, phone, role } = req.body;
    const user = await prisma.user.update({
      where: { id: parseInt(id) },
      data: { name, email, phone, role }
    });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: "Failed to update user" });
  }
});

app.delete('/api/admin/users/:id', authenticate, async (req, res) => {
  if (req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    await prisma.user.delete({ where: { id: parseInt(id) } });
    res.json({ message: "User deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: "Failed to delete user" });
  }
});

app.post('/api/admin/users/:id/reset', authenticate, async (req, res) => {
  if (req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const { password } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    await prisma.user.update({
      where: { id: parseInt(id) },
      data: { password: hashedPassword }
    });
    res.json({ message: "Password reset successfully" });
  } catch (err) {
    res.status(500).json({ error: "Failed to reset password" });
  }
});

app.post('/api/admin/users/:id/toggle', authenticate, async (req, res) => {
  if (req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { id } = req.params;
    const user = await prisma.user.findUnique({ where: { id: parseInt(id) } });
    const nextStatus = user.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    const updatedUser = await prisma.user.update({
      where: { id: parseInt(id) },
      data: { status: nextStatus }
    });
    res.json(updatedUser);
  } catch (err) {
    res.status(500).json({ error: "Failed to toggle status" });
  }
});

// ==========================================
// USER PROFILE & REVIEWS
// ==========================================

// Get Current User Info
app.get('/api/users/me', authenticate, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.userId },
      select: { id: true, email: true, name: true, phone: true, role: true, birthDate: true, isTwoFactorEnabled: true, createdAt: true }
    });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch user" });
  }
});

// Update Profile
app.put('/api/users/profile', authenticate, async (req, res) => {
  try {
    const { name, phone, email, birthDate } = req.body;
    
    // If email is changing, ensure it's not already used
    if (email) {
      const existing = await prisma.user.findUnique({ where: { email } });
      if (existing && existing.id !== req.user.userId) {
        return res.status(400).json({ error: "Email sudah digunakan oleh akun lain" });
      }
    }

    const updated = await prisma.user.update({
      where: { id: req.user.userId },
      data: { name, phone, email, birthDate }
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: "Failed to update profile" });
  }
});

// Toggle 2FA
app.post('/api/users/2fa/toggle', authenticate, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user.userId } });
    const updated = await prisma.user.update({
      where: { id: req.user.userId },
      data: { isTwoFactorEnabled: !user.isTwoFactorEnabled }
    });
    res.json({ isTwoFactorEnabled: updated.isTwoFactorEnabled, message: updated.isTwoFactorEnabled ? "2FA diaktifkan" : "2FA dinonaktifkan" });
  } catch (err) {
    res.status(500).json({ error: "Failed to toggle 2FA" });
  }
});

// Change Password
app.post('/api/users/change-password', authenticate, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = await prisma.user.findUnique({ where: { id: req.user.userId } });
    
    const validPassword = await bcrypt.compare(currentPassword, user.password);
    if (!validPassword) return res.status(401).json({ error: "Password sekarang salah" });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.user.update({
      where: { id: req.user.userId },
      data: { password: hashedPassword }
    });
    res.json({ message: "Password berjaya diubah" });
  } catch (err) {
    res.status(500).json({ error: "Gagal menukar password" });
  }
});

// Get My Reviews
app.get('/api/reviews/me', authenticate, async (req, res) => {
  try {
    const reviews = await prisma.review.findMany({
      where: { userId: req.user.userId },
      include: {
        product: true,
        images: true // Sertakan gambar ulasan
      },
      orderBy: { createdAt: 'desc' }
    });
    res.json(reviews);
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch reviews" });
  }
});

// Submit Review (dengan dukungan upload gambar dari kamera/galeri HP)
app.post('/api/reviews', authenticate, async (req, res) => {
  try {
    const { productId, rating, comment, imageUrls } = req.body;
    
    // Check if user has ordered this product and it's COMPLETED
    const orderItem = await prisma.orderItem.findFirst({
      where: {
        productId: productId,
        order: {
          userId: req.user.userId,
          status: { in: ['COMPLETED', 'DELIVERED'] }
        }
      }
    });

    if (!orderItem) {
      return res.status(403).json({ error: "Anda hanya boleh memberi ulasan untuk produk yang telah dibeli dan diselesaikan." });
    }

    // Buat ulasan baru
    const review = await prisma.review.create({
      data: {
        productId,
        userId: req.user.userId,
        userName: req.user.name || "Customer",
        rating,
        comment
      }
    });

    // Simpan URL gambar ulasan jika ada (dikirim dari kamera/galeri di HP)
    if (imageUrls && Array.isArray(imageUrls) && imageUrls.length > 0) {
      // Batasi maksimal 5 gambar per ulasan untuk optimasi mobile
      const limitedUrls = imageUrls.slice(0, 5);
      await prisma.reviewImage.createMany({
        data: limitedUrls.map(url => ({
          reviewId: review.id,
          imageUrl: url
        }))
      });
    }

    // Ambil ulasan beserta gambar-gambarnya untuk respons
    const reviewWithImages = await prisma.review.findUnique({
      where: { id: review.id },
      include: { images: true }
    });

    // Update product rating (simple average)
    const allReviews = await prisma.review.findMany({ where: { productId } });
    const avgRating = allReviews.reduce((acc, r) => acc + r.rating, 0) / allReviews.length;
    
    await prisma.product.update({
      where: { id: productId },
      data: { rating: avgRating }
    });

    res.json(reviewWithImages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to submit review" });
  }
});

// Get user addresses (for seller/admin to view buyer's addresses)
app.get('/api/users/:userId/addresses', authenticate, async (req, res) => {
  if (req.user.role !== 'PENJUAL' && req.user.role !== 'ADMIN') return res.sendStatus(403);
  try {
    const { userId } = req.params;
    const addresses = await prisma.userAddress.findMany({
      where: { userId: parseInt(userId) },
      orderBy: { isMain: 'desc' }
    });
    res.json(addresses);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Gagal mengambil alamat pengguna" });
  }
});

// Address Routes
app.get('/api/addresses', authenticate, async (req, res) => {
  try {
    const addresses = await prisma.userAddress.findMany({
      where: { userId: req.user.userId },
      orderBy: { isMain: 'desc' }
    });
    res.json(addresses);
  } catch (err) {
    res.status(500).json({ error: "Gagal mengambil alamat" });
  }
});

app.post('/api/addresses', authenticate, async (req, res) => {
  try {
    const { name, phone, province, city, district, postalCode, streetAddress, detailAddress, latitude, longitude, isMain, label } = req.body;
    
    if (isMain) {
      await prisma.userAddress.updateMany({
        where: { userId: req.user.userId },
        data: { isMain: false }
      });
    }

    const address = await prisma.userAddress.create({
      data: {
        userId: req.user.userId,
        name, phone, province, city, district, postalCode, streetAddress, detailAddress, latitude, longitude, isMain, label
      }
    });
    res.json(address);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Gagal menambah alamat" });
  }
});

app.put('/api/addresses/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, phone, province, city, district, postalCode, streetAddress, detailAddress, latitude, longitude, isMain, label } = req.body;
    
    const existing = await prisma.userAddress.findUnique({ where: { id: parseInt(id) } });
    if (!existing || existing.userId !== req.user.userId) return res.sendStatus(403);

    if (isMain) {
      await prisma.userAddress.updateMany({
        where: { userId: req.user.userId },
        data: { isMain: false }
      });
    }

    const address = await prisma.userAddress.update({
      where: { id: parseInt(id) },
      data: {
        name, phone, province, city, district, postalCode, streetAddress, detailAddress, latitude, longitude, isMain, label
      }
    });
    res.json(address);
  } catch (err) {
    res.status(500).json({ error: "Gagal mengupdate alamat" });
  }
});

app.delete('/api/addresses/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const existing = await prisma.userAddress.findUnique({ where: { id: parseInt(id) } });
    if (!existing || existing.userId !== req.user.userId) return res.sendStatus(403);

    await prisma.userAddress.delete({ where: { id: parseInt(id) } });
    res.json({ message: "Alamat berjaya dihapus" });
  } catch (err) {
    res.status(500).json({ error: "Gagal menghapus alamat" });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
