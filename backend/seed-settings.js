const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const existing = await prisma.storeSettings.findFirst();
  if (!existing) {
    await prisma.storeSettings.create({
      data: {
        id: 1,
        bankName: 'BCA',
        bankAccount: '0123456789',
        accountName: 'TENUN GEZA OFFICIAL'
      }
    });
    console.log('Created default store settings');
  } else {
    console.log('Store settings already exist');
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
