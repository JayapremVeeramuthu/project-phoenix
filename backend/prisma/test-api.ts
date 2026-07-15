import axios from 'axios';
import * as FormData from 'form-data';

const BASE_URL = 'http://localhost:3000/api/v1';

async function main() {
  console.log('=== RUNNING REAL BACKEND API VERIFICATIONS ===');

  try {
    // 1. Health check & Service Categories fetch
    console.log('\n[1/6] Testing Service Categories API...');
    const catResponse = await axios.get(`${BASE_URL}/services/categories`);
    console.log(`- Status: ${catResponse.status}`);
    console.log(`- Categories fetched: ${catResponse.data.data.length}`);
    const firstItem = catResponse.data.data[0].items[0];
    console.log(`- Sample Service Item: ${firstItem.nameEn} (${firstItem.id})`);

    // 2. Products Store fetch
    console.log('\n[2/6] Testing Products Store API...');
    const prodResponse = await axios.get(`${BASE_URL}/products`);
    console.log(`- Status: ${prodResponse.status}`);
    console.log(`- Products fetched: ${prodResponse.data.data.length}`);

    // 3. Upload File to MinIO
    console.log('\n[3/6] Testing Media Upload to MinIO...');
    const form = new FormData();
    form.append('file', Buffer.from('Phoenix dummy image content'), 'test_image.jpg');
    
    const uploadResponse = await axios.post(`${BASE_URL}/media/upload`, form, {
      headers: form.getHeaders(),
    });
    console.log(`- Status: ${uploadResponse.status}`);
    console.log(`- Uploaded URL: ${uploadResponse.data.url}`);
    const uploadedUrl = uploadResponse.data.url;

    // 4. Create Booking in PostgreSQL
    console.log('\n[4/6] Testing Create Booking API (PostgreSQL)...');
    const bookingPayload = {
      localId: `PHX-TEST-${Date.now()}`,
      customerId: 'e0e84430-6e08-46d2-b96f-e95a2e235341', // seeded user UUID
      propertyId: 'b87fa109-178c-42b7-8977-628d08cb5f09', // seeded property UUID
      serviceId: firstItem.id,
      address: 'Flat 405, Phoenix Tower B, Chennai',
      scheduledAt: new Date().toISOString(),
      timeSlot: '10:00 AM',
      isEmergency: true,
      description: 'Test booking with real PostgreSQL & MinIO integrations.',
      imageUrls: [uploadedUrl],
      voiceNoteUrl: uploadedUrl,
      voiceTranscript: 'Audio transcript verify testing.',
      estimatedPrice: 799.0,
    };

    const bookingResponse = await axios.post(`${BASE_URL}/bookings`, bookingPayload);
    console.log(`- Status: ${bookingResponse.status}`);
    console.log(`- Booking ID: ${bookingResponse.data.id}`);
    const createdBookingId = bookingResponse.data.id;

    // 5. Verify Payment & Generate Invoice & Warranty
    console.log('\n[5/6] Testing Payment Verification, Invoice & Warranty generation...');
    const verifyPayload = {
      bookingId: createdBookingId,
      amount: 799.0,
      paymentMethod: 'UPI',
      paymentId: `pay_verification_${Date.now()}`,
      discountAmount: 0.0,
    };

    const verifyResponse = await axios.post(`${BASE_URL}/payments/verify`, verifyPayload);
    console.log(`- Status: ${verifyResponse.status}`);
    console.log(`- Payment status: ${verifyResponse.data.status}`);
    console.log(`- Invoice ID: ${verifyResponse.data.invoiceId}`);
    console.log(`- Total Amount: ${verifyResponse.data.totalAmount}`);

    // 6. Check MinIO Console/List
    console.log('\n[6/6] Listing Files stored in MinIO Bucket...');
    const listResponse = await axios.get(`${BASE_URL}/media/list`);
    console.log(`- Status: ${listResponse.status}`);
    console.log(`- Files in MinIO:`, listResponse.data.files);

    console.log('\n=== REAL INFRASTRUCTURE INTEGRATIONS VERIFIED SUCCESSFULLY ===');
  } catch (error: any) {
    console.error('API Verification Failed:', error.response?.data || error.message);
    process.exit(1);
  }
}

main();
