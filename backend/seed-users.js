const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function main() {
  const hashedPasswordAdmin = await bcrypt.hash('admin', 10);
  const hashedPasswordPenjual = await bcrypt.hash('penjual', 10);

  // Create Admin
  await prisma.user.upsert({
    where: { email: 'admin@geza.com' },
    update: {},
    create: {
      email: 'admin@geza.com',
      password: hashedPasswordAdmin,
      name: 'Admin Geza',
      role: 'ADMIN',
      phone: '08123456789'
    }
  });

  // Create Seller (Penjual)
  await prisma.user.upsert({
    where: { email: 'penjual@geza.com' },
    update: {},
    create: {
      email: 'penjual@geza.com',
      password: hashedPasswordPenjual,
      name: 'Penjual Geza',
      role: 'PENJUAL',
      phone: '08987654321'
    }
  });

  console.log('Seed successful!');
  console.log('Admin: admin@geza.com / admin');
  console.log('Penjual: penjual@geza.com / penjual');
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
