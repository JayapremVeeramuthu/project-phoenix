-- CreateEnum
CREATE TYPE "AddressType" AS ENUM ('HOME', 'WORK', 'OTHER');

-- CreateEnum
CREATE TYPE "EcomOrderStatus" AS ENUM ('PLACED', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED', 'RETURN_REQUESTED', 'RETURNED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "PaymentMethodType" AS ENUM ('UPI', 'CREDIT_CARD', 'DEBIT_CARD', 'NET_BANKING', 'WALLET', 'CASH_ON_DELIVERY');

-- CreateEnum
CREATE TYPE "EcomPaymentStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "ReturnType" AS ENUM ('RETURN', 'REPLACEMENT');

-- CreateEnum
CREATE TYPE "ReturnStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'PICKED_UP', 'COMPLETED');

-- AlterEnum
ALTER TYPE "BookingStatus" ADD VALUE 'WAITING_FOR_TECHNICIAN';
ALTER TYPE "BookingStatus" ADD VALUE 'TECHNICIAN_ASSIGNED';
ALTER TYPE "BookingStatus" ADD VALUE 'PAYMENT_PENDING';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "address" TEXT,
ADD COLUMN     "branch" TEXT,
ADD COLUMN     "city" TEXT,
ADD COLUMN     "dateOfBirth" TEXT,
ADD COLUMN     "experience" TEXT,
ADD COLUMN     "firebaseUid" TEXT,
ADD COLUMN     "gender" TEXT,
ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "isEmailVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "isFounder" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "isOnline" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "lastLoginAt" TIMESTAMP(3),
ADD COLUMN     "mustChangePassword" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "password" TEXT,
ADD COLUMN     "pincode" TEXT,
ADD COLUMN     "provider" TEXT,
ADD COLUMN     "serviceAreas" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "skills" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "state" TEXT,
ADD COLUMN     "technicianId" TEXT;

-- AlterTable
ALTER TABLE "Booking" ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "longitude" DOUBLE PRECISION,
ADD COLUMN     "rejectedBy" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- AlterTable
ALTER TABLE "Product" ADD COLUMN     "brand" TEXT NOT NULL DEFAULT 'Phoenix',
ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "deliveryDays" INTEGER NOT NULL DEFAULT 3,
ADD COLUMN     "discountPercent" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "images" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "mrp" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
ADD COLUMN     "rating" DOUBLE PRECISION NOT NULL DEFAULT 4.5,
ADD COLUMN     "returnPolicy" TEXT DEFAULT '7 Days Replacement Policy',
ADD COLUMN     "reviewCount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "specifications" JSONB,
ADD COLUMN     "stock" INTEGER NOT NULL DEFAULT 50,
ADD COLUMN     "variants" JSONB,
ADD COLUMN     "warrantyInfo" TEXT DEFAULT '1 Year Brand Warranty';

-- CreateTable
CREATE TABLE "CustomerAddress" (
    "id" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "fullName" TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "buildingNo" TEXT NOT NULL,
    "street" TEXT NOT NULL,
    "area" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "pincode" TEXT NOT NULL,
    "landmark" TEXT,
    "addressType" "AddressType" NOT NULL DEFAULT 'HOME',
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "CustomerAddress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EcomCart" (
    "id" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EcomCart_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EcomCartItem" (
    "id" UUID NOT NULL,
    "cartId" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "selectedVariant" TEXT,
    "savedForLater" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EcomCartItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EcomOrder" (
    "id" UUID NOT NULL,
    "orderNumber" TEXT NOT NULL,
    "customerId" UUID NOT NULL,
    "status" "EcomOrderStatus" NOT NULL DEFAULT 'PLACED',
    "deliveryAddress" JSONB NOT NULL,
    "deliveryOption" JSONB NOT NULL,
    "paymentMethod" "PaymentMethodType" NOT NULL DEFAULT 'UPI',
    "paymentStatus" "EcomPaymentStatus" NOT NULL DEFAULT 'PENDING',
    "paymentId" TEXT,
    "subtotal" DOUBLE PRECISION NOT NULL,
    "discountAmount" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "deliveryFee" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "couponDiscount" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "taxAmount" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "totalAmount" DOUBLE PRECISION NOT NULL,
    "couponCode" TEXT,
    "estimatedDelivery" TIMESTAMP(3) NOT NULL,
    "trackingNumber" TEXT,
    "timeline" JSONB NOT NULL DEFAULT '[]',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "EcomOrder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EcomOrderItem" (
    "id" UUID NOT NULL,
    "orderId" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "productName" TEXT NOT NULL,
    "productImage" TEXT NOT NULL,
    "price" DOUBLE PRECISION NOT NULL,
    "mrp" DOUBLE PRECISION NOT NULL,
    "quantity" INTEGER NOT NULL,
    "selectedVariant" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EcomOrderItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Coupon" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "discountType" TEXT NOT NULL,
    "discountValue" DOUBLE PRECISION NOT NULL,
    "minOrderAmount" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "maxDiscount" DOUBLE PRECISION,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "expiryDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Coupon_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EcomReturnRequest" (
    "id" UUID NOT NULL,
    "orderId" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "type" "ReturnType" NOT NULL DEFAULT 'RETURN',
    "reason" TEXT NOT NULL,
    "comments" TEXT,
    "status" "ReturnStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EcomReturnRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "CustomerAddress_customerId_idx" ON "CustomerAddress"("customerId");

-- CreateIndex
CREATE INDEX "CustomerAddress_pincode_idx" ON "CustomerAddress"("pincode");

-- CreateIndex
CREATE UNIQUE INDEX "EcomCart_customerId_key" ON "EcomCart"("customerId");

-- CreateIndex
CREATE INDEX "EcomCartItem_cartId_idx" ON "EcomCartItem"("cartId");

-- CreateIndex
CREATE INDEX "EcomCartItem_productId_idx" ON "EcomCartItem"("productId");

-- CreateIndex
CREATE UNIQUE INDEX "EcomCartItem_cartId_productId_selectedVariant_key" ON "EcomCartItem"("cartId", "productId", "selectedVariant");

-- CreateIndex
CREATE UNIQUE INDEX "EcomOrder_orderNumber_key" ON "EcomOrder"("orderNumber");

-- CreateIndex
CREATE INDEX "EcomOrder_customerId_idx" ON "EcomOrder"("customerId");

-- CreateIndex
CREATE INDEX "EcomOrder_orderNumber_idx" ON "EcomOrder"("orderNumber");

-- CreateIndex
CREATE INDEX "EcomOrder_status_idx" ON "EcomOrder"("status");

-- CreateIndex
CREATE INDEX "EcomOrderItem_orderId_idx" ON "EcomOrderItem"("orderId");

-- CreateIndex
CREATE INDEX "EcomOrderItem_productId_idx" ON "EcomOrderItem"("productId");

-- CreateIndex
CREATE UNIQUE INDEX "Coupon_code_key" ON "Coupon"("code");

-- CreateIndex
CREATE INDEX "EcomReturnRequest_orderId_idx" ON "EcomReturnRequest"("orderId");

-- CreateIndex
CREATE INDEX "EcomReturnRequest_customerId_idx" ON "EcomReturnRequest"("customerId");

-- CreateIndex
CREATE UNIQUE INDEX "User_firebaseUid_key" ON "User"("firebaseUid");

-- CreateIndex
CREATE UNIQUE INDEX "User_technicianId_key" ON "User"("technicianId");

-- CreateIndex
CREATE INDEX "Product_category_idx" ON "Product"("category");

-- AddForeignKey
ALTER TABLE "CustomerAddress" ADD CONSTRAINT "CustomerAddress_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EcomCart" ADD CONSTRAINT "EcomCart_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EcomCartItem" ADD CONSTRAINT "EcomCartItem_cartId_fkey" FOREIGN KEY ("cartId") REFERENCES "EcomCart"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EcomCartItem" ADD CONSTRAINT "EcomCartItem_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EcomOrder" ADD CONSTRAINT "EcomOrder_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EcomOrderItem" ADD CONSTRAINT "EcomOrderItem_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "EcomOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EcomOrderItem" ADD CONSTRAINT "EcomOrderItem_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EcomReturnRequest" ADD CONSTRAINT "EcomReturnRequest_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "EcomOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EcomReturnRequest" ADD CONSTRAINT "EcomReturnRequest_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
