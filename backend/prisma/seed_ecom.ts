import { PrismaClient, AddressType } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding e-commerce store catalog, coupons, and addresses...');

  // 1. Seed Rich Products
  const products = [
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f01',
      category: 'Electrical Switches',
      name: 'Phoenix Smart Switch 6-Gang',
      brand: 'Phoenix Tech',
      description: 'Ultra-modern capacitive touch smart switch board with tempered crystal glass panel. Integrates seamlessly with Alexa, Google Home, and Phoenix mobile automation. Offers overload protection, soft-touch LED backlights, and scheduled timer routines.',
      price: 2499.0,
      mrp: 3499.0,
      discountPercent: 29,
      imageUrl: 'assets/products/switch.png',
      images: [
        'assets/products/switch.png',
        'assets/products/switch.png',
      ],
      rating: 4.6,
      reviewCount: 142,
      stock: 45,
      variants: ['6-Gang (White)', '6-Gang (Matte Black)', '8-Gang (White)'],
      specifications: {
        'Panel Material': 'Scratch-resistant Toughened Glass',
        'Connectivity': 'Wi-Fi 2.4GHz b/g/n',
        'Rated Load': '10A per gang (1000W total resistive)',
        'Operating Voltage': '110V - 250V AC 50/60Hz',
        'Voice Assistant': 'Amazon Alexa, Google Assistant',
        'In the Box': '1x Smart Switch Board, 2x Screws, User Manual',
      },
      warrantyInfo: '1 Year Brand Replacement Warranty',
      returnPolicy: '7 Days Return & Replacement Policy',
      deliveryDays: 3,
    },
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f02',
      category: 'Water Pumps',
      name: 'Phoenix Super Suction 1HP Pump',
      brand: 'Phoenix Power',
      description: 'Heavy duty high-efficiency residential water booster pump engineered with 100% pure copper motor winding, brass impeller, and anti-rust CED coated casting. Includes automatic thermal overload protection and low-noise vibration dampers.',
      price: 6899.0,
      mrp: 8999.0,
      discountPercent: 23,
      imageUrl: 'assets/products/pump.png',
      images: [
        'assets/products/pump.png',
        'assets/products/pump.png',
      ],
      rating: 4.8,
      reviewCount: 98,
      stock: 20,
      variants: ['0.5 HP Standard', '1.0 HP Turbo', '1.5 HP Heavy Duty'],
      specifications: {
        'Motor Power': '1.0 HP (0.75 kW)',
        'Winding': '100% Electrolytic Grade Copper',
        'Max Flow Rate': '3200 Litres/Hour',
        'Max Head Range': '6 - 36 Metres',
        'Pipe Size': '25mm x 25mm (1 inch x 1 inch)',
        'In the Box': '1x Pump Unit, Strainer, Warranty Card',
      },
      warrantyInfo: '2 Years Comprehensive On-Site Warranty',
      returnPolicy: '10 Days Replacement for Manufacturing Defects',
      deliveryDays: 4,
    },
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f03',
      category: 'Fans',
      name: 'Phoenix BLDC Premium Ceiling Fan',
      brand: 'Phoenix Air',
      description: '5-star rated super energy-efficient Brushless DC (BLDC) motor ceiling fan that consumes only 28W at highest speed. Comes with full-function smart RF remote featuring Sleep Mode, Timer, and Boost Air Delivery mode.',
      price: 3499.0,
      mrp: 4999.0,
      discountPercent: 30,
      imageUrl: 'assets/products/fan.png',
      images: [
        'assets/products/fan.png',
        'assets/products/fan.png',
      ],
      rating: 4.7,
      reviewCount: 312,
      stock: 65,
      variants: ['Classic White 1200mm', 'Smoke Brown 1200mm', 'Midnight Black 1200mm'],
      specifications: {
        'Sweep Size': '1200 mm (48 Inches)',
        'Power Consumption': '28 Watts at Speed 5',
        'Air Delivery': '235 CMM (Cubic Metres/Minute)',
        'Speed': '360 RPM',
        'Remote Features': 'Speed 1-5, Timer (1h/2h/4h), Sleep Mode',
        'In the Box': 'Motor Unit, 3x Aerodynamic Blades, Downrod, Remote, Battery',
      },
      warrantyInfo: '3 Years On-Site Warranty on Motor',
      returnPolicy: '7 Days Replacement Policy',
      deliveryDays: 2,
    },
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f04',
      category: 'Safety Equipment',
      name: 'Phoenix MCB Distribution Board',
      brand: 'Phoenix Guard',
      description: 'Professional grade dual-door 12-way SPN distribution board crafted from high-grade CRCA sheet steel with IP43 ingress protection. Features insulated neutral busbar, earth link, and clear acrylic viewing door.',
      price: 1899.0,
      mrp: 2499.0,
      discountPercent: 24,
      imageUrl: 'assets/products/mcb_box.png',
      images: [
        'assets/products/mcb_box.png',
        'assets/products/mcb_box.png',
      ],
      rating: 4.5,
      reviewCount: 84,
      stock: 30,
      variants: ['8-Way Double Door', '12-Way Double Door', '16-Way Double Door'],
      specifications: {
        'Number of Ways': '12 Way SPN',
        'Sheet Thickness': '1.2mm High Strength CRCA Steel',
        'Protection Standard': 'IP43 Ingress Protection',
        'Busbar': '100A Tinned Copper Busbar',
        'Standards': 'IS 13032 / IEC 61439-3 Certified',
        'In the Box': 'DB Enclosure, Acrylic Door, Neutral & Earth Bars',
      },
      warrantyInfo: '5 Years Replacement Warranty',
      returnPolicy: '7 Days Replacement Policy',
      deliveryDays: 3,
    },
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f05',
      category: 'Lights',
      name: 'Phoenix 20W LED Batten Light',
      brand: 'Phoenix Glow',
      description: 'High-efficacy 20W LED slim tubelight delivering brilliant 2000 lumens flicker-free illumination with integrated 4kV surge protection. Anti-glare extruded polycarbonate diffuser provides uniform light dispersion across rooms.',
      price: 299.0,
      mrp: 499.0,
      discountPercent: 40,
      imageUrl: 'assets/products/light.png',
      images: [
        'assets/products/light.png',
        'assets/products/light.png',
      ],
      rating: 4.4,
      reviewCount: 420,
      stock: 150,
      variants: ['Cool Day White (6500K)', 'Warm Yellow (3000K)', 'Natural White (4000K)'],
      specifications: {
        'Power Rating': '20 Watts',
        'Luminous Flux': '2000 Lumens',
        'Surge Resistance': 'Up to 4kV Inbuilt MOV Protection',
        'Beam Angle': '>120 Degrees Anti-glare',
        'Life Expectancy': '25,000 Burning Hours',
        'In the Box': '1x LED Batten, Wall Mounting Clips, Screws',
      },
      warrantyInfo: '2 Years Manufacturer Replacement Warranty',
      returnPolicy: '7 Days Replacement Policy',
      deliveryDays: 2,
    },
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f06',
      category: 'Smart Home',
      name: 'Phoenix Smart Wi-Fi Video Doorbell',
      brand: 'Phoenix Vision',
      description: 'Crystal-clear 1080p Full HD smart video doorbell with infrared night vision, two-way noise-cancelling microphone and PIR human motion detection. Sends instant video alerts to your smartphone when visitors ring.',
      price: 4299.0,
      mrp: 5999.0,
      discountPercent: 28,
      imageUrl: 'assets/products/switch.png',
      images: [
        'assets/products/switch.png',
        'assets/products/switch.png',
      ],
      rating: 4.7,
      reviewCount: 165,
      stock: 25,
      variants: ['Midnight Black', 'Pearl White'],
      specifications: {
        'Video Quality': '1080p FHD (1920 x 1080) at 30fps',
        'Field of View': '166 Degrees Wide Angle',
        'Battery': '5200mAh Rechargeable Lithium Battery (Up to 6 Months)',
        'Storage': 'Free Cloud Rolling 3-Day + MicroSD up to 128GB',
        'Water Resistance': 'IP65 Weatherproof',
        'In the Box': 'Video Doorbell, Chime Unit, Wall Bracket, Screws, USB Cable',
      },
      warrantyInfo: '1 Year Brand Replacement Warranty',
      returnPolicy: '7 Days Replacement Policy',
      deliveryDays: 3,
    },
  ];

  for (const p of products) {
    await prisma.product.upsert({
      where: { id: p.id },
      update: p,
      create: p,
    });
  }
  console.log(`✓ Upserted ${products.length} rich products.`);

  // 2. Seed Coupons
  const coupons = [
    {
      code: 'PHOENIX100',
      description: 'Flat ₹100 instant discount on orders above ₹999',
      discountType: 'FLAT',
      discountValue: 100.0,
      minOrderAmount: 999.0,
      maxDiscount: 100.0,
      isActive: true,
      expiryDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    },
    {
      code: 'SAVE10',
      description: '10% instant discount up to ₹500 on orders above ₹1,499',
      discountType: 'PERCENT',
      discountValue: 10.0,
      minOrderAmount: 1499.0,
      maxDiscount: 500.0,
      isActive: true,
      expiryDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    },
    {
      code: 'FESTIVE20',
      description: '20% festive discount up to ₹1,000 on orders above ₹2,999',
      discountType: 'PERCENT',
      discountValue: 20.0,
      minOrderAmount: 2999.0,
      maxDiscount: 1000.0,
      isActive: true,
      expiryDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    },
    {
      code: 'FREEDEL',
      description: 'Free standard delivery on any purchase',
      discountType: 'FLAT',
      discountValue: 49.0,
      minOrderAmount: 299.0,
      maxDiscount: 49.0,
      isActive: true,
      expiryDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    },
  ];

  for (const c of coupons) {
    await prisma.coupon.upsert({
      where: { code: c.code },
      update: c,
      create: c,
    });
  }
  console.log(`✓ Upserted ${coupons.length} promotional coupons.`);

  // 3. Seed Sample Customer Addresses for active customers
  const customers = await prisma.user.findMany({
    where: { role: 'CUSTOMER' },
  });

  for (const customer of customers) {
    const existingAddresses = await prisma.customerAddress.count({
      where: { customerId: customer.id },
    });
    if (existingAddresses === 0) {
      await prisma.customerAddress.createMany({
        data: [
          {
            customerId: customer.id,
            fullName: customer.name || 'Prem Kumar',
            phoneNumber: customer.phoneNumber?.startsWith('fb_') ? '+919003028001' : customer.phoneNumber,
            buildingNo: 'Flat 405, Block B',
            street: 'Phoenix Towers, OMR Express Highway',
            area: 'Thoraipakkam',
            city: 'Chennai',
            state: 'Tamil Nadu',
            pincode: '600096',
            landmark: 'Near Cognizant Junction',
            addressType: AddressType.HOME,
            isDefault: true,
          },
          {
            customerId: customer.id,
            fullName: customer.name || 'Prem Kumar',
            phoneNumber: customer.phoneNumber?.startsWith('fb_') ? '+919003028001' : customer.phoneNumber,
            buildingNo: 'Floor 3, Tech Park Wing A',
            street: 'Sholinganallur Main Road',
            area: 'Sholinganallur',
            city: 'Chennai',
            state: 'Tamil Nadu',
            pincode: '600119',
            landmark: 'Opposite ELCOT SEZ Gate 2',
            addressType: AddressType.WORK,
            isDefault: false,
          },
        ],
      });
      console.log(`✓ Seeded 2 delivery addresses for customer: ${customer.email || customer.phoneNumber}`);
    }
  }

  console.log('✅ E-commerce seed completed successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
