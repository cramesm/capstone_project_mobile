import bcrypt from 'bcryptjs';
import { createHash, randomBytes, randomInt } from 'crypto';
import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import fs from 'fs';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import jwt from 'jsonwebtoken';
import { MongoClient, ObjectId } from 'mongodb';
import multer from 'multer';
import nodemailer from 'nodemailer';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const {
  PORT = '4000',
  DISABLE_DB = 'false',
  MONGODB_URI = '',
  MONGODB_DB_NAME = 'verifitor',
  MONGODB_USERS_COLLECTION = 'users',
  ALLOWED_ORIGIN = '*',
  MAILBOXLAYER_ACCESS_KEY = '',
  OTP_TTL_MINUTES = '10',
  OTP_DEV_MODE = 'false',
  JWT_SECRET = '',
  JWT_ACCESS_TTL_MINUTES = '15',
  JWT_REFRESH_TTL_DAYS = '30',
  JWT_ISSUER = 'verifitor',
  SMTP_HOST = 'smtp-relay.brevo.com',
  SMTP_PORT = '587',
  SMTP_SECURE = 'false',
  SMTP_USER = '',
  SMTP_PASS = '',
  SMTP_FROM = 'Verifitor <andreisembrano8@gmail.com>',
} = process.env;

const dbEnabled = DISABLE_DB !== 'true';

if (dbEnabled && !MONGODB_URI) {
  throw new Error('Missing MONGODB_URI in backend/.env');
}

if (!JWT_SECRET) {
  throw new Error('Missing JWT_SECRET in backend/.env');
}

const app = express();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uploadsDir = path.join(__dirname, '..', 'uploads');
const receiptsDir = path.join(uploadsDir, 'receipts');
fs.mkdirSync(receiptsDir, { recursive: true });

const allowedReceiptMimeTypes = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
]);
const receiptUpload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, receiptsDir),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname || '').toLowerCase();
      const name = randomBytes(10).toString('hex');
      cb(null, `${name}${ext || '.jpg'}`);
    },
  }),
  fileFilter: (req, file, cb) => {
    if (!allowedReceiptMimeTypes.has(file.mimetype)) {
      req.fileValidationError = 'Only JPG, PNG, or WEBP images are allowed.';
      return cb(null, false);
    }
    return cb(null, true);
  },
  limits: {
    fileSize: 8 * 1024 * 1024,
  },
});

app.use(helmet());
app.use(
  cors({
    origin: ALLOWED_ORIGIN === '*' ? true : ALLOWED_ORIGIN,
  }),
);
app.use(express.json({ limit: '1mb' }));
app.use('/uploads', express.static(uploadsDir));

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/auth', authLimiter);

const client = dbEnabled ? new MongoClient(MONGODB_URI) : null;
let users;
let receipts;
let requests;
const memoryUsers = new Map();
const memoryReceipts = [];
const memoryRequests = [];

const emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const passwordRegex =
  /^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$/;

const otpStore = new Map();
const registrationOtpStore = new Map();
const resetTokenStore = new Map();

const smtpEnabled = Boolean(SMTP_HOST && SMTP_PORT && SMTP_USER && SMTP_PASS);
const mailTransporter = smtpEnabled
  ? nodemailer.createTransport({
      host: SMTP_HOST,
      port: Number(SMTP_PORT),
      secure: SMTP_SECURE === 'true',
      auth: {
        user: SMTP_USER,
        pass: SMTP_PASS,
      },
    })
  : null;

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function makeUserId() {
  return randomBytes(12).toString('hex');
}

function buildUserResponse(user) {
  if (!user) return null;
  return {
    id: user._id || user.id,
    firstName: user.firstName,
    lastName: user.lastName,
    email: user.email,
    role: user.role,
  };
}

function buildProfileResponse(user) {
  if (!user) return null;
  const role = String(user.role || '').trim().toLowerCase();
  const isStudent = role === 'student';
  const schoolEmail = isStudent ? user.schoolEmail || '' : '';
  return {
    id: user._id || user.id,
    firstName: user.firstName,
    lastName: user.lastName,
    email: isStudent && schoolEmail ? schoolEmail : user.email,
    personalEmail: isStudent ? '' : user.personalEmail || user.email || '',
    role: role || 'alumni',
    schoolEmail,
    studentId: isStudent ? user.studentId || '' : '',
    yearLevel: user.yearLevel || '',
    program: user.program || '',
  };
}

function normalizeRole(role) {
  const normalized = String(role || '').trim().toLowerCase();
  if (normalized === 'student') return 'student';
  return 'alumni';
}

async function getUserById(id) {
  if (!id) return null;
  if (dbEnabled) {
    if (!ObjectId.isValid(id)) return null;
    return users.findOne({ _id: new ObjectId(id) });
  }

  for (const user of memoryUsers.values()) {
    const candidate = String(user?._id || user?.id || '');
    if (candidate && candidate === id) return user;
  }
  return null;
}

async function getUserFromAuth(payload) {
  if (!payload) return null;
  const sub = String(payload.sub || '').trim();
  if (sub) {
    const byId = await getUserById(sub);
    if (byId) return byId;
  }

  const email = normalizeEmail(payload.email);
  if (emailRegex.test(email)) {
    return getUserByEmail(email);
  }

  return null;
}

function toPositiveNumber(value, fallback) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return parsed;
}

const jwtIssuer = String(JWT_ISSUER || '').trim();
const accessTokenTtlSeconds =
  toPositiveNumber(JWT_ACCESS_TTL_MINUTES, 15) * 60;
const refreshTokenTtlMs =
  toPositiveNumber(JWT_REFRESH_TTL_DAYS, 30) * 24 * 60 * 60 * 1000;

function signAccessToken(user) {
  const payload = {
    sub: String(user._id || user.id || ''),
    email: user.email,
    role: user.role,
  };
  const options = jwtIssuer
    ? { expiresIn: accessTokenTtlSeconds, issuer: jwtIssuer }
    : { expiresIn: accessTokenTtlSeconds };
  return jwt.sign(payload, JWT_SECRET, options);
}

function makeRefreshToken() {
  return randomBytes(48).toString('hex');
}

function hashRefreshToken(token) {
  return createHash('sha256').update(token).digest('hex');
}

function buildRefreshTokenRecord(token) {
  return {
    tokenHash: hashRefreshToken(token),
    createdAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + refreshTokenTtlMs).toISOString(),
  };
}

function getRefreshTokenRecord(user, tokenHash) {
  const tokens = Array.isArray(user?.refreshTokens) ? user.refreshTokens : [];
  return tokens.find((record) => record.tokenHash === tokenHash);
}

function isRefreshTokenExpired(record) {
  if (!record?.expiresAt) return true;
  return new Date(record.expiresAt).getTime() <= Date.now();
}

async function storeRefreshToken(email, record) {
  if (dbEnabled) {
    await users.updateOne(
      { email },
      {
        $push: {
          refreshTokens: {
            $each: [record],
            $slice: -5,
          },
        },
      },
    );
    return;
  }

  const existing = memoryUsers.get(email);
  if (!existing) return;
  const refreshTokens = Array.isArray(existing.refreshTokens)
    ? existing.refreshTokens
    : [];
  memoryUsers.set(email, {
    ...existing,
    refreshTokens: [...refreshTokens, record].slice(-5),
  });
}

async function revokeRefreshToken(email, tokenHash) {
  if (dbEnabled) {
    await users.updateOne(
      { email },
      { $pull: { refreshTokens: { tokenHash } } },
    );
    return;
  }

  const existing = memoryUsers.get(email);
  if (!existing) return;
  const refreshTokens = Array.isArray(existing.refreshTokens)
    ? existing.refreshTokens
    : [];
  memoryUsers.set(email, {
    ...existing,
    refreshTokens: refreshTokens.filter(
      (record) => record.tokenHash !== tokenHash,
    ),
  });
}

async function issueTokensForUser(user) {
  const refreshToken = makeRefreshToken();
  const refreshRecord = buildRefreshTokenRecord(refreshToken);
  await storeRefreshToken(user.email, refreshRecord);
  const accessToken = signAccessToken(user);
  return {
    accessToken,
    refreshToken,
    expiresInSeconds: accessTokenTtlSeconds,
  };
}

function requireAuth(req, res, next) {
  const authHeader = String(req.headers.authorization || '');
  if (!authHeader.startsWith('Bearer ')) {
    return res
      .status(401)
      .json({ success: false, message: 'Missing access token.' });
  }

  const token = authHeader.slice(7).trim();
  if (!token) {
    return res
      .status(401)
      .json({ success: false, message: 'Missing access token.' });
  }

  try {
    const payload = jwtIssuer
      ? jwt.verify(token, JWT_SECRET, { issuer: jwtIssuer })
      : jwt.verify(token, JWT_SECRET);
    req.auth = payload;
    return next();
  } catch (error) {
    return res
      .status(401)
      .json({ success: false, message: 'Invalid or expired token.' });
  }
}

async function getUserByEmail(email) {
  if (dbEnabled) {
    return users.findOne({ email });
  }
  return memoryUsers.get(email) || null;
}

async function createUserDocument(user) {
  if (dbEnabled) {
    return users.insertOne(user);
  }

  const id = user._id || user.id || makeUserId();
  memoryUsers.set(user.email, { ...user, _id: id });
  return { insertedId: id };
}

async function createReceiptRecord(receipt) {
  if (dbEnabled) {
    const result = await receipts.insertOne(receipt);
    return result.insertedId;
  }

  const id = makeUserId();
  memoryReceipts.push({ ...receipt, _id: id });
  return id;
}

async function createRequestRecord(request) {
  if (dbEnabled) {
    const result = await requests.insertOne(request);
    return result.insertedId;
  }

  const id = makeUserId();
  memoryRequests.push({ ...request, _id: id });
  return id;
}

async function updateRequestStatusForPayment({
  userId,
  docName,
  purpose,
  paymentType,
}) {
  if (!userId || !docName || !purpose) return null;

  const updates = {
    status: 'pending_completion',
    paymentType,
    updatedAt: new Date().toISOString(),
  };

  if (dbEnabled) {
    const record = await requests.findOne(
      { userId, docName, purpose },
      { sort: { createdAt: -1 } },
    );
    if (!record?._id) return null;
    await requests.updateOne({ _id: record._id }, { $set: updates });
    return record._id;
  }

  const recordIndex = [...memoryRequests]
    .reverse()
    .findIndex(
      (record) =>
        String(record.userId) === String(userId) &&
        record.docName === docName &&
        record.purpose === purpose,
    );

  if (recordIndex < 0) return null;
  const actualIndex = memoryRequests.length - 1 - recordIndex;
  memoryRequests[actualIndex] = {
    ...memoryRequests[actualIndex],
    ...updates,
  };
  return memoryRequests[actualIndex]._id || memoryRequests[actualIndex].id;
}

function buildRequestResponse(record) {
  if (!record) return null;
  const id = record._id || record.id;
  return {
    id: id ? String(id) : '',
    docName: record.docName || '',
    purpose: record.purpose || '',
    status: record.status || 'pending',
    createdAt: record.createdAt || new Date().toISOString(),
    updatedAt: record.updatedAt || record.createdAt || new Date().toISOString(),
  };
}

function parseStatusFilter(value) {
  if (!value) return [];
  return String(value)
    .split(',')
    .map((status) => status.trim().toLowerCase())
    .filter(Boolean);
}

async function listRequestsForUser(user, statuses) {
  const userId = user?._id || user?.id;
  if (!userId) return [];

  if (dbEnabled) {
    const query = { userId };
    if (statuses && statuses.length > 0) {
      query.status = { $in: statuses };
    }
    return requests.find(query).sort({ createdAt: -1 }).toArray();
  }

  const userIdValue = String(userId);
  let items = memoryRequests.filter(
    (record) => String(record.userId) === userIdValue,
  );
  if (statuses && statuses.length > 0) {
    items = items.filter((record) =>
      statuses.includes(String(record.status || '').toLowerCase()),
    );
  }
  return items.sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
  );
}

async function upsertUserDocument(user) {
  if (dbEnabled) {
    const { createdAt, ...userSet } = user;
    await users.updateOne(
      { email: user.email },
      {
        $set: userSet,
        $setOnInsert: {
          createdAt: createdAt ?? new Date().toISOString(),
        },
      },
      { upsert: true },
    );
    return;
  }

  const existing = memoryUsers.get(user.email);
  memoryUsers.set(user.email, {
    ...existing,
    ...user,
    _id: existing?._id ?? user._id ?? makeUserId(),
    createdAt:
      existing?.createdAt ?? user.createdAt ?? new Date().toISOString(),
  });
}

async function updateUserPassword(email, passwordHash) {
  if (dbEnabled) {
    await users.updateOne(
      { email },
      { $set: { passwordHash, updatedAt: new Date().toISOString() } },
    );
    return;
  }

  const existing = memoryUsers.get(email);
  if (!existing) return;
  memoryUsers.set(email, {
    ...existing,
    passwordHash,
    updatedAt: new Date().toISOString(),
  });
}

async function updateUserProfile(user, updates) {
  if (!user) return;
  if (dbEnabled) {
    await users.updateOne(
      { _id: user._id },
      { $set: { ...updates, updatedAt: new Date().toISOString() } },
    );
    return;
  }

  const existing = memoryUsers.get(user.email);
  if (!existing) return;
  const nextEmailRaw = String(updates.email || existing.email || '').trim();
  const nextEmail = nextEmailRaw ? normalizeEmail(nextEmailRaw) : user.email;

  if (nextEmail !== user.email) {
    memoryUsers.delete(user.email);
  }

  memoryUsers.set(nextEmail, {
    ...existing,
    ...updates,
    email: nextEmail,
    updatedAt: new Date().toISOString(),
  });
}

async function validateEmailWithMailboxlayer(email) {
  if (!MAILBOXLAYER_ACCESS_KEY) {
    return { isValid: true, reason: 'Mailboxlayer not configured' };
  }

  const endpoint = `http://apilayer.net/api/check?access_key=${encodeURIComponent(
    MAILBOXLAYER_ACCESS_KEY,
  )}&email=${encodeURIComponent(email)}&smtp=1&format=1`;

  try {
    const response = await fetch(endpoint);
    if (!response.ok) {
      return { isValid: true, reason: 'Mailboxlayer request failed' };
    }

    const data = await response.json();
    if (data.success === false) {
      return { isValid: true, reason: 'Mailboxlayer API error' };
    }

    const isDeliverable = Boolean(data.format_valid) && Boolean(data.mx_found);
    return {
      isValid: isDeliverable,
      reason: isDeliverable ? 'ok' : 'Email failed mailbox checks',
    };
  } catch (_error) {
    return { isValid: true, reason: 'Mailboxlayer unreachable' };
  }
}

function makeOtp() {
  return String(randomInt(100000, 1000000));
}

function makeResetToken() {
  return randomBytes(24).toString('hex');
}

function cleanupOtpData() {
  const now = Date.now();

  for (const store of [otpStore, registrationOtpStore]) {
    for (const [email, value] of store.entries()) {
      if (value.expiresAt <= now) store.delete(email);
    }
  }

  for (const [token, value] of resetTokenStore.entries()) {
    if (value.expiresAt <= now) resetTokenStore.delete(token);
  }
}

function putOtp(store, email, extra = {}) {
  const otp = makeOtp();
  const expiresAt = Date.now() + Number(OTP_TTL_MINUTES) * 60 * 1000;
  store.set(email, { otp, expiresAt, attempts: 0, ...extra });
  return otp;
}

async function sendOtpEmail({ email, otp, purpose }) {
  if (!mailTransporter) {
    throw new Error('SMTP is not configured.');
  }

  const ttlMinutes = Number(OTP_TTL_MINUTES);
  const subjects = {
    registration: 'Your Verifitor registration OTP',
    login: 'Your Verifitor login OTP',
    'password-reset': 'Your Verifitor password reset OTP',
  };
  const subject = subjects[purpose] || 'Your Verifitor OTP';
  const text = `Your OTP is ${otp}. It expires in ${ttlMinutes} minutes.`;

  await mailTransporter.sendMail({
    from: SMTP_FROM,
    to: email,
    subject,
    text,
  });
}

async function sendOtpResponse(res, { email, otp, purpose }) {
  if (OTP_DEV_MODE === 'true') {
    return res.json({
      success: true,
      message: 'OTP generated (dev mode).',
      otp,
    });
  }

  if (!mailTransporter) {
    return res.status(500).json({
      success: false,
      message: 'SMTP is not configured.',
    });
  }

  try {
    await sendOtpEmail({ email, otp, purpose });
    return res.json({
      success: true,
      message: 'OTP sent to your email.',
    });
  } catch (error) {
    console.error('OTP email failed:', error?.message || error);
    return res.status(502).json({
      success: false,
      message: 'Failed to send OTP email. Check SMTP credentials and sender.',
    });
  }
}

function validateRegisterPayload(body) {
  const firstName = String(body.firstName || '').trim();
  const lastName = String(body.lastName || '').trim();
  const email = normalizeEmail(body.email);
  const password = String(body.password || '').trim();
  const schoolEmail = String(body.schoolEmail || '').trim();
  const studentId = String(body.studentId || '').trim();
  const yearLevel = String(body.yearLevel || '').trim();
  const program = String(body.program || '').trim();

  if (firstName.length < 2 || lastName.length < 2) {
    return { error: 'First name and last name are required (min 2 chars).' };
  }

  if (!emailRegex.test(email)) {
    return { error: 'Invalid email address.' };
  }

  if (!passwordRegex.test(password)) {
    return {
      error:
        'Password must be at least 8 chars and include uppercase, lowercase, number, and special character.',
    };
  }

  if (schoolEmail && !emailRegex.test(schoolEmail)) {
    return { error: 'Invalid school email address.' };
  }

  return {
    firstName,
    lastName,
    email,
    password,
    schoolEmail,
    studentId,
    yearLevel,
    program,
  };
}

function validateProfilePayload(body) {
  const firstName = String(body.firstName || '').trim();
  const lastName = String(body.lastName || '').trim();
  const schoolEmail = String(body.schoolEmail || '').trim();
  const personalEmail = String(body.personalEmail || '').trim();
  const studentId = String(body.studentId || '').trim();
  const yearLevel = String(body.yearLevel || '').trim();
  const program = String(body.program || '').trim();
  const newPassword = String(body.newPassword || '').trim();

  if (firstName.length < 2 || lastName.length < 2) {
    return { error: 'First name and last name are required (min 2 chars).' };
  }

  if (schoolEmail && !emailRegex.test(schoolEmail)) {
    return { error: 'Invalid school email address.' };
  }

  if (personalEmail && !emailRegex.test(personalEmail)) {
    return { error: 'Invalid personal email address.' };
  }

  if (newPassword && !passwordRegex.test(newPassword)) {
    return {
      error:
        'Password must be at least 8 chars and include uppercase, lowercase, number, and special character.',
    };
  }

  return {
    firstName,
    lastName,
    schoolEmail,
    personalEmail,
    studentId,
    yearLevel,
    program,
    newPassword,
  };
}

app.get('/health', (_req, res) => {
  res.json({ success: true, message: 'API is healthy' });
});

app.get('/profile', requireAuth, async (req, res, next) => {
  try {
    const user = await getUserFromAuth(req.auth);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: 'User not found.' });
    }

    return res.json({ success: true, user: buildProfileResponse(user) });
  } catch (error) {
    return next(error);
  }
});

app.post(
  '/payments/receipt',
  requireAuth,
  receiptUpload.single('receipt'),
  async (req, res, next) => {
    try {
      if (req.fileValidationError) {
        return res.status(400).json({
          success: false,
          message: req.fileValidationError,
        });
      }

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'Receipt image is required.',
        });
      }

      const paymentType = String(req.body?.paymentType || '')
        .trim()
        .toLowerCase();
      if (paymentType !== 'onsite' && paymentType !== 'gcash') {
        return res.status(400).json({
          success: false,
          message: 'Invalid payment type.',
        });
      }

      const user = await getUserFromAuth(req.auth);
      if (!user) {
        return res
          .status(404)
          .json({ success: false, message: 'User not found.' });
      }

      const receipt = {
        userId: user._id || user.id,
        email: user.email,
        paymentType,
        docName: String(req.body?.docName || '').trim(),
        purpose: String(req.body?.purpose || '').trim(),
        fileName: req.file.filename,
        originalName: req.file.originalname,
        mimeType: req.file.mimetype,
        size: req.file.size,
        path: `/uploads/receipts/${req.file.filename}`,
        createdAt: new Date().toISOString(),
      };

      const receiptId = await createReceiptRecord(receipt);
      await updateRequestStatusForPayment({
        userId: receipt.userId,
        docName: receipt.docName,
        purpose: receipt.purpose,
        paymentType: receipt.paymentType,
      });
      return res.status(201).json({
        success: true,
        receiptId,
        fileUrl: receipt.path,
      });
    } catch (error) {
      return next(error);
    }
  },
);

app.post('/requests', requireAuth, async (req, res, next) => {
  try {
    const docName = String(req.body?.docName || '').trim();
    const purpose = String(req.body?.purpose || '').trim();

    if (!docName) {
      return res.status(400).json({
        success: false,
        message: 'Document name is required.',
      });
    }

    if (!purpose) {
      return res.status(400).json({
        success: false,
        message: 'Purpose is required.',
      });
    }

    const user = await getUserFromAuth(req.auth);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: 'User not found.' });
    }

    const requestRecord = {
      userId: user._id || user.id,
      email: user.email,
      role: user.role || '',
      firstName: user.firstName || '',
      lastName: user.lastName || '',
      personalEmail: user.personalEmail || user.email || '',
      schoolEmail: user.schoolEmail || '',
      studentId: user.role === 'alumni' ? '' : user.studentId || '',
      yearGraduated: user.role === 'alumni' ? user.yearLevel || '' : '',
      yearLevel: user.role === 'alumni' ? '' : user.yearLevel || '',
      program: user.program || '',
      docName,
      purpose,
      status: 'pending_payment',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const requestId = await createRequestRecord(requestRecord);
    return res.status(201).json({
      success: true,
      requestId: String(requestId),
      request: { ...requestRecord, id: String(requestId) },
    });
  } catch (error) {
    return next(error);
  }
});

app.get('/requests', requireAuth, async (req, res, next) => {
  try {
    const user = await getUserFromAuth(req.auth);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: 'User not found.' });
    }

    const statusFilters = parseStatusFilter(req.query?.status);
    const records = await listRequestsForUser(user, statusFilters);
    return res.json({
      success: true,
      requests: records.map(buildRequestResponse).filter(Boolean),
    });
  } catch (error) {
    return next(error);
  }
});

app.put('/profile', requireAuth, async (req, res, next) => {
  try {
    const parsed = validateProfilePayload(req.body || {});
    if (parsed.error) {
      return res.status(400).json({ success: false, message: parsed.error });
    }

    const user = await getUserFromAuth(req.auth);
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: 'User not found.' });
    }

    const role = normalizeRole(user.role);
    const isStudent = role === 'student';

    if (isStudent) {
      const schoolEmail = normalizeEmail(parsed.schoolEmail || '');
      if (!emailRegex.test(schoolEmail)) {
        return res.status(400).json({
          success: false,
          message: 'School email is required for student accounts.',
        });
      }

      if (!parsed.studentId) {
        return res.status(400).json({
          success: false,
          message: 'Student ID is required for student accounts.',
        });
      }

      if (schoolEmail !== user.email) {
        const existing = await getUserByEmail(schoolEmail);
        if (
          existing &&
          String(existing._id || existing.id || '') !==
            String(user._id || user.id || '')
        ) {
          return res
            .status(409)
            .json({ success: false, message: 'Email already exists.' });
        }
      }

      const updates = {
        firstName: parsed.firstName,
        lastName: parsed.lastName,
        schoolEmail,
        personalEmail: '',
        email: schoolEmail,
        studentId: parsed.studentId,
        yearLevel: parsed.yearLevel,
        program: parsed.program,
      };

      await updateUserProfile(user, updates);
    } else {
      const nextPersonalEmail =
        parsed.personalEmail || user.personalEmail || user.email;
      const nextEmail = normalizeEmail(nextPersonalEmail);
      if (!emailRegex.test(nextEmail)) {
        return res
          .status(400)
          .json({ success: false, message: 'Invalid login email address.' });
      }

      if (nextEmail !== user.email) {
        const existing = await getUserByEmail(nextEmail);
        if (
          existing &&
          String(existing._id || existing.id || '') !==
            String(user._id || user.id || '')
        ) {
          return res
            .status(409)
            .json({ success: false, message: 'Email already exists.' });
        }
      }

      const updates = {
        firstName: parsed.firstName,
        lastName: parsed.lastName,
        schoolEmail: '',
        personalEmail: nextPersonalEmail,
        email: nextEmail,
        studentId: '',
        yearLevel: parsed.yearLevel,
        program: parsed.program,
      };

      await updateUserProfile(user, updates);
    }

    if (parsed.newPassword) {
      const passwordHash = await bcrypt.hash(parsed.newPassword, 12);
      await updateUserPassword(user.email, passwordHash);
    }

    const refreshed = await getUserByEmail(user.email);
    return res.json({
      success: true,
      message: 'Profile updated.',
      user: buildProfileResponse(refreshed || { ...user, ...updates }),
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/auth/register', async (req, res, next) => {
  try {
    const parsed = validateRegisterPayload(req.body || {});
    if (parsed.error) {
      return res.status(400).json({ success: false, message: parsed.error });
    }

    const role = normalizeRole(req.body?.role);
    const isStudent = role === 'student';
    const schoolEmail = normalizeEmail(parsed.schoolEmail || parsed.email);

    if (isStudent) {
      if (!emailRegex.test(schoolEmail)) {
        return res.status(400).json({
          success: false,
          message: 'School email is required for student accounts.',
        });
      }
      if (!parsed.studentId) {
        return res.status(400).json({
          success: false,
          message: 'Student ID is required for student accounts.',
        });
      }
    }

    const mailboxCheck = await validateEmailWithMailboxlayer(
      isStudent ? schoolEmail : parsed.email,
    );
    if (!mailboxCheck.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Email is not deliverable. Please use a valid email.',
      });
    }

    const existing = await getUserByEmail(isStudent ? schoolEmail : parsed.email);
    if (existing) {
      return res
        .status(409)
        .json({ success: false, message: 'Email already exists.' });
    }

    const passwordHash = await bcrypt.hash(parsed.password, 12);

    const result = await createUserDocument({
      firstName: parsed.firstName,
      lastName: parsed.lastName,
      email: isStudent ? schoolEmail : parsed.email,
      personalEmail: isStudent ? '' : parsed.email,
      passwordHash,
      role,
      schoolEmail: isStudent ? schoolEmail : '',
      studentId: isStudent ? parsed.studentId : '',
      yearLevel: parsed.yearLevel,
      program: parsed.program,
      createdAt: new Date().toISOString(),
    });

    return res.status(201).json({
      success: true,
      userId: result.insertedId,
      message: 'Account created successfully.',
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/auth/register/request-otp', async (req, res, next) => {
  try {
    cleanupOtpData();

    const parsed = validateRegisterPayload(req.body || {});
    if (parsed.error) {
      return res.status(400).json({ success: false, message: parsed.error });
    }

    const role = normalizeRole(req.body?.role);
    const isStudent = role === 'student';
    const schoolEmail = normalizeEmail(parsed.schoolEmail || parsed.email);

    if (isStudent) {
      if (!emailRegex.test(schoolEmail)) {
        return res.status(400).json({
          success: false,
          message: 'School email is required for student accounts.',
        });
      }
      if (!parsed.studentId) {
        return res.status(400).json({
          success: false,
          message: 'Student ID is required for student accounts.',
        });
      }
    }

    const mailboxCheck = await validateEmailWithMailboxlayer(
      isStudent ? schoolEmail : parsed.email,
    );
    if (!mailboxCheck.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Email is not deliverable. Please use a valid email.',
      });
    }

    const existing = await getUserByEmail(isStudent ? schoolEmail : parsed.email);
    if (existing) {
      return res
        .status(409)
        .json({ success: false, message: 'Email already exists.' });
    }

    const otp = putOtp(registrationOtpStore, isStudent ? schoolEmail : parsed.email, {
      payload: {
        ...parsed,
        role,
        email: isStudent ? schoolEmail : parsed.email,
        personalEmail: isStudent ? '' : parsed.email,
        schoolEmail: isStudent ? schoolEmail : '',
        studentId: isStudent ? parsed.studentId : '',
      },
    });
    return await sendOtpResponse(res, {
      email: isStudent ? schoolEmail : parsed.email,
      otp,
      purpose: 'registration',
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/auth/register/verify-otp', async (req, res, next) => {
  try {
    cleanupOtpData();

    const email = normalizeEmail(req.body?.email);
    const otp = String(req.body?.otp || '').trim();

    if (!emailRegex.test(email) || !/^\d{6}$/.test(otp)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email or OTP format.',
      });
    }

    const record = registrationOtpStore.get(email);
    if (!record || record.expiresAt <= Date.now()) {
      registrationOtpStore.delete(email);
      return res.status(400).json({
        success: false,
        message: 'OTP expired or not found. Please request a new one.',
      });
    }

    if (record.otp !== otp) {
      record.attempts += 1;
      registrationOtpStore.set(email, record);

      if (record.attempts >= 5) {
        registrationOtpStore.delete(email);
      }

      return res.status(401).json({ success: false, message: 'Invalid OTP.' });
    }

    const payload = record.payload;
    registrationOtpStore.delete(email);

    if (!payload) {
      return res
        .status(400)
        .json({ success: false, message: 'Missing registration payload.' });
    }

    const existing = await users.findOne({ email: payload.email });
    if (existing) {
      return res
        .status(409)
        .json({ success: false, message: 'Email already exists.' });
    }

    const passwordHash = await bcrypt.hash(payload.password, 12);
    const result = await createUserDocument({
      firstName: payload.firstName,
      lastName: payload.lastName,
      email: payload.email,
      personalEmail: payload.personalEmail || '',
      passwordHash,
      role: payload.role || 'alumni',
      schoolEmail: payload.schoolEmail || '',
      studentId: payload.studentId || '',
      yearLevel: payload.yearLevel,
      program: payload.program,
      createdAt: new Date().toISOString(),
    });

    return res.status(201).json({
      success: true,
      userId: result.insertedId,
      message: 'Account created successfully.',
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/auth/login', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = String(req.body?.password || '').trim();
    const requestedRole = String(req.body?.role || '').trim().toLowerCase();

    if (!emailRegex.test(email) || password.length < 8) {
      return res
        .status(400)
        .json({ success: false, message: 'Invalid email or password format.' });
    }

    const user = await getUserByEmail(email);
    if (!user) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid email or password.' });
    }

    if (requestedRole) {
      const actualRole = String(user.role || '').trim().toLowerCase();
      if (!actualRole || actualRole !== requestedRole) {
        return res.status(403).json({
          success: false,
          message: 'Account role does not match the selected login role.',
        });
      }
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash || '');
    if (!isMatch) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid email or password.' });
    }

    const session = await issueTokensForUser(user);
    return res.json({
      success: true,
      message: 'Login successful.',
      user: buildUserResponse(user),
      ...session,
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/auth/refresh', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const refreshToken = String(req.body?.refreshToken || '').trim();

    if (!emailRegex.test(email) || !refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email or refresh token.',
      });
    }

    const user = await getUserByEmail(email);
    if (!user) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid refresh session.' });
    }

    const tokenHash = hashRefreshToken(refreshToken);
    const record = getRefreshTokenRecord(user, tokenHash);
    if (!record || isRefreshTokenExpired(record)) {
      await revokeRefreshToken(email, tokenHash);
      return res
        .status(401)
        .json({ success: false, message: 'Refresh token expired.' });
    }

    await revokeRefreshToken(email, tokenHash);
    const session = await issueTokensForUser(user);

    return res.json({
      success: true,
      message: 'Session refreshed.',
      ...session,
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/auth/logout', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const refreshToken = String(req.body?.refreshToken || '').trim();

    if (!emailRegex.test(email) || !refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email or refresh token.',
      });
    }

    const tokenHash = hashRefreshToken(refreshToken);
    await revokeRefreshToken(email, tokenHash);

    return res.json({ success: true, message: 'Logged out.' });
  } catch (error) {
    return next(error);
  }
});

app.post('/auth/forgot-password/request-otp', async (req, res, next) => {
  try {
    cleanupOtpData();

    const email = normalizeEmail(req.body?.email);
    if (!emailRegex.test(email)) {
      return res.status(400).json({ success: false, message: 'Invalid email.' });
    }

    const user = await getUserByEmail(email);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'No account found for this email.',
      });
    }

    const mailboxCheck = await validateEmailWithMailboxlayer(email);
    if (!mailboxCheck.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Email is not deliverable. Please use a valid email.',
      });
    }

    const otp = putOtp(otpStore, email);

    return await sendOtpResponse(res, {
      email,
      otp,
      purpose: 'password-reset',
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/auth/forgot-password/verify-otp', async (req, res, next) => {
  try {
    cleanupOtpData();

    const email = normalizeEmail(req.body?.email);
    const otp = String(req.body?.otp || '').trim();

    if (!emailRegex.test(email) || !/^\d{6}$/.test(otp)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email or OTP format.',
      });
    }

    const record = otpStore.get(email);
    if (!record || record.expiresAt <= Date.now()) {
      otpStore.delete(email);
      return res.status(400).json({
        success: false,
        message: 'OTP expired or not found. Please request a new one.',
      });
    }

    if (record.otp !== otp) {
      record.attempts += 1;
      otpStore.set(email, record);

      if (record.attempts >= 5) {
        otpStore.delete(email);
      }

      return res.status(401).json({ success: false, message: 'Invalid OTP.' });
    }

    otpStore.delete(email);
    const resetToken = makeResetToken();
    resetTokenStore.set(resetToken, {
      email,
      expiresAt: Date.now() + Number(OTP_TTL_MINUTES) * 60 * 1000,
    });

    return res.json({
      success: true,
      message: 'OTP verified.',
      resetToken,
    });
  } catch (error) {
    return next(error);
  }
});

app.post('/auth/forgot-password/reset', async (req, res, next) => {
  try {
    cleanupOtpData();

    const resetToken = String(req.body?.resetToken || '').trim();
    const newPassword = String(req.body?.newPassword || '').trim();

    if (!resetToken) {
      return res
        .status(400)
        .json({ success: false, message: 'Missing reset token.' });
    }

    if (!passwordRegex.test(newPassword)) {
      return res.status(400).json({
        success: false,
        message:
          'Password must be at least 8 chars and include uppercase, lowercase, number, and special character.',
      });
    }

    const tokenRecord = resetTokenStore.get(resetToken);
    if (!tokenRecord || tokenRecord.expiresAt <= Date.now()) {
      resetTokenStore.delete(resetToken);
      return res.status(401).json({
        success: false,
        message: 'Reset token is invalid or expired.',
      });
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await updateUserPassword(tokenRecord.email, passwordHash);

    resetTokenStore.delete(resetToken);

    return res.json({
      success: true,
      message: 'Password reset successful.',
    });
  } catch (error) {
    return next(error);
  }
});

app.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError) {
    return res.status(400).json({
      success: false,
      message: err.code === 'LIMIT_FILE_SIZE'
        ? 'Receipt image is too large.'
        : err.message,
    });
  }
  console.error(err);
  res.status(500).json({ success: false, message: 'Internal server error.' });
});

async function start() {
  if (dbEnabled) {
    try {
      await client.connect();
      const db = client.db(MONGODB_DB_NAME);
      users = db.collection(MONGODB_USERS_COLLECTION);
      receipts = db.collection('receipts');
      requests = db.collection('requests');
      try {
        // Drop the old non-sparse username index if it exists
        try {
          await users.dropIndex('username_1');
        } catch (err) {
          // Index doesn't exist, that's fine
        }
        await users.createIndex({ email: 1 }, { unique: true });
        // Create sparse unique index on username (allows multiple null values)
        await users.createIndex({ username: 1 }, { unique: true, sparse: true });
        await receipts.createIndex({ userId: 1, createdAt: -1 });
        await requests.createIndex({ userId: 1, createdAt: -1 });
        await requests.createIndex({ status: 1, createdAt: -1 });
      } catch (err) {
        console.warn('Could not create indexes (permission denied):', err.message);
      }
    } catch (error) {
      throw new Error(`MongoDB connection failed: ${error.message}`);
    }
  } else {
    console.warn('DISABLE_DB is true. Using in-memory users only.');
  }

  app.listen(Number(PORT), () => {
    console.log(`Auth API listening on port ${PORT}`);
  });
}

setInterval(cleanupOtpData, 60 * 1000);

start().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});
