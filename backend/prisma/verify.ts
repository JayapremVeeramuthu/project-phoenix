import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- VERIFYING POSTGRESQL TABLES & SEEDED DATA ---');
  
  const users = await prisma.user.findMany();
  console.log(`Users: ${users.length} found`);
  for (const u of users) {
    console.log(` - ID: ${u.id}, Name: ${u.name}, Phone: ${u.phoneNumber}, Role: ${u.role}`);
  }

  const properties = await prisma.property.findMany();
  console.log(`Properties: ${properties.length} found`);
  for (const p of properties) {
    console.log(` - ID: ${p.id}, CustomerID: ${p.customerId}, Name: ${p.name}, Address: ${p.address}`);
  }

  const categories = await prisma.serviceCategory.findMany({
    include: { items: true }
  });
  console.log(`Service Categories: ${categories.length} found`);
  for (const c of categories) {
    console.log(` - Category: ${c.nameEn} (${c.id}) has ${c.items.length} items`);
  }

  const products = await prisma.product.findMany();
  console.log(`Products: ${products.length} found`);
  for (const p of products) {
    console.log(` - Product: ${p.name} (${p.category}) - Price: ${p.price}`);
  }

  const bookings = await prisma.booking.findMany();
  console.log(`Bookings: ${bookings.length} found`);

  const warranties = await prisma.warranty.findMany();
  console.log(`Warranties: ${warranties.length} found`);

  const invoices = await prisma.invoice.findMany();
  console.log(`Invoices: ${invoices.length} found`);

  console.log('--- VERIFICATION COMPLETE ---');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
