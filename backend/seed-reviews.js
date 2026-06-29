const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const products = await prisma.product.findMany();
  
  if (products.length === 0) {
    console.log("No products found. Run other seeds first.");
    return;
  }

  const sampleReviews = [
    { userName: "Siti Rahma", rating: 5, comment: "Kain tenunnya sangat halus dan motifnya otentik sekali. Sesuai ekspektasi!" },
    { userName: "Budi Santoso", rating: 4, comment: "Pengiriman cepat dan packing sangat aman. Kualitas kain tebal dan warnanya mewah." },
    { userName: "Aisha", rating: 5, comment: "Songketnya luar biasa indah. Detail benang emasnya sangat rapi. Terima kasih Tenun Geza!" },
    { userName: "Irfan Hakim", rating: 4, comment: "Pelayanan sangat memuaskan, admin responsif." }
  ];

  for (const product of products) {
    // Add 2 random reviews for each product
    for (let i = 0; i < 2; i++) {
      const review = sampleReviews[Math.floor(Math.random() * sampleReviews.length)];
      await prisma.review.create({
        data: {
          productId: product.id,
          userId: 1, // Assuming user 1 exists
          userName: review.userName,
          rating: review.rating,
          comment: review.comment,
        }
      });
    }
    
    // Update product rating average (simple mock)
    await prisma.product.update({
      where: { id: product.id },
      data: { rating: 4.5 }
    });
  }

  console.log('Seed reviews success!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
