import { Module, Global } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ValkeyService } from './services/valkey.service';
import { RabbitmqService } from './services/rabbitmq.service';
import { MinioService } from './services/minio.service';
import { MeilisearchService } from './services/meilisearch.service';
import { RateLimiterGuard } from './guards/rate-limiter.guard';
import { JwtAuthGuard, OptionalJwtAuthGuard } from './guards/jwt-auth.guard';

@Global()
@Module({
  imports: [JwtModule.register({})],
  providers: [
    ValkeyService,
    RabbitmqService,
    MinioService,
    MeilisearchService,
    RateLimiterGuard,
    JwtAuthGuard,
    OptionalJwtAuthGuard,
  ],
  exports: [
    ValkeyService,
    RabbitmqService,
    MinioService,
    MeilisearchService,
    RateLimiterGuard,
    JwtAuthGuard,
    OptionalJwtAuthGuard,
    JwtModule,
  ],
})
export class CommonModule {}
