import { Module, Global } from '@nestjs/common';
import { ValkeyService } from './services/valkey.service';
import { RabbitmqService } from './services/rabbitmq.service';
import { MinioService } from './services/minio.service';
import { MeilisearchService } from './services/meilisearch.service';
import { RateLimiterGuard } from './guards/rate-limiter.guard';

@Global()
@Module({
  providers: [ValkeyService, RabbitmqService, MinioService, MeilisearchService, RateLimiterGuard],
  exports: [ValkeyService, RabbitmqService, MinioService, MeilisearchService, RateLimiterGuard],
})
export class CommonModule {}
