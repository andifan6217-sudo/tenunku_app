# Tenunku Backend (Express + Prisma)

## Run locally

1. Create `.env` (see `.env.example`)
2. Install deps:

```bash
npm install
```

3. Generate Prisma client (first time / after schema changes):

```bash
npm run prisma:generate
```

4. Start server:

```bash
npm run dev
```

Server default: `http://localhost:3000`

## Production notes (hosting)

- **Do not run manually** in a terminal tab. Use a process manager.
- Recommended on VPS:
  - Install Node.js LTS
  - Use **PM2**:

```bash
npm install -g pm2
cd backend
npm install --omit=dev
pm2 start index.js --name tenunku-backend
pm2 save
pm2 startup
```

- Put the backend behind **Nginx** / reverse proxy and set:
  - `PUBLIC_BASE_URL="https://api.yourdomain.com"`
  - `ALLOWED_ORIGINS="https://your-frontend-domain.com"`
  - Strong `JWT_SECRET`

## Security checklist (must)

- Rotate leaked secrets (Midtrans keys, EMAIL_PASS, JWT_SECRET) before deploying.
- Set `ALLOWED_ORIGINS` (avoid `*` in production).
- Keep `/uploads` persistent (volume) or migrate to object storage (S3/R2) for scaling.

