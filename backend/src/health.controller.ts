import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { PrismaService } from './prisma/prisma.service';
import { ValkeyService } from './common/services/valkey.service';
import { RabbitmqService } from './common/services/rabbitmq.service';
import { MinioService } from './common/services/minio.service';
import { MeilisearchService } from './common/services/meilisearch.service';

@ApiTags('Health Check')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly valkey: ValkeyService,
    private readonly rabbitmq: RabbitmqService,
    private readonly minio: MinioService,
    private readonly meilisearch: MeilisearchService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Check health status of the application and all microservices' })
  async getHealth() {
    let databaseStatus = 'down';
    let valkeyStatus = 'down';
    let rabbitmqStatus = 'down';
    let minioStatus = 'down';
    let meilisearchStatus = 'down';

    // 1. PostgreSQL check
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      databaseStatus = 'up';
    } catch (_) {}

    // 2. Valkey check
    try {
      await this.valkey.set('health_check_ping', 'pong', 5);
      const val = await this.valkey.get('health_check_ping');
      if (val === 'pong') {
        valkeyStatus = 'up';
      }
    } catch (_) {}

    // 3. MinIO check
    try {
      const files = await this.minio.listFiles();
      if (Array.isArray(files)) {
        minioStatus = 'up';
      }
    } catch (_) {}

    // 4. Meilisearch check
    try {
      const results = await this.meilisearch.search('products', '');
      if (Array.isArray(results)) {
        meilisearchStatus = 'up';
      }
    } catch (_) {}

    // 5. RabbitMQ check
    try {
      // RabbitmqService has simple channel check internally
      // We can try a simple pub fallback check or just see if the service is loaded
      await this.rabbitmq.publish('health_ping', { ping: true });
      rabbitmqStatus = 'up';
    } catch (_) {}

    const overallStatus =
      databaseStatus === 'up' &&
      valkeyStatus === 'up' &&
      minioStatus === 'up' &&
      meilisearchStatus === 'up'
        ? 'ok'
        : 'degraded';

    return {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      services: {
        database: databaseStatus,
        valkey: valkeyStatus,
        rabbitmq: rabbitmqStatus,
        minio: minioStatus,
        meilisearch: meilisearchStatus,
      },
    };
  }
}
