import { Module } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';
import { CommonModule } from './common/common.module';
import { AuthModule } from './auth/auth.module';
import { ServicesModule } from './services/services.module';
import { BookingModule } from './booking/booking.module';
import { PropertyModule } from './property/property.module';
import { InvoiceModule } from './invoice/invoice.module';
import { WarrantyModule } from './warranty/warranty.module';
import { MediaModule } from './media/media.module';
import { ProductsModule } from './products/products.module';
import { AdminModule } from './admin/admin.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    PrismaModule,
    CommonModule,
    AuthModule,
    ServicesModule,
    BookingModule,
    PropertyModule,
    InvoiceModule,
    WarrantyModule,
    MediaModule,
    ProductsModule,
    AdminModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}

