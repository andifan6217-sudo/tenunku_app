const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function check() {
  try {
    const orders = await prisma.order.findMany({
      include: {
        items: { include: { product: true } },
        user: true
      }
    });
    console.log('Orders found:', orders.length);
    if (orders.length > 0) {
      console.log('Sample order user id:', orders[0].userId);
      console.log('Sample order items length:', orders[0].items.length);
    }
    const users = await prisma.user.findMany();
    console.log('Users found:', users.length);
  } catch (e) {
    console.error('Error checking DB:', e);
  } finally {
    await prisma.$disconnect();
  }
}

check();
