import { Injectable, CanActivate, ExecutionContext, HttpException, HttpStatus } from '@nestjs/common';
import { ValkeyService } from '../services/valkey.service';

@Injectable()
export class RateLimiterGuard implements CanActivate {
  constructor(private readonly valkey: ValkeyService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const ip = request.ip || request.headers['x-forwarded-for'] || 'unknown';
    const path = request.route.path;
    const cacheKey = `ratelimit:${ip}:${path}`;

    // Get current request count
    const current = await this.valkey.get(cacheKey);
    const count = current ? parseInt(current, 10) : 0;

    const limit = 60; // 60 requests per minute limit
    if (count >= limit) {
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          message: 'Too many requests. Please try again after a minute.',
          error: 'Too Many Requests',
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // Increment count and set expiration if new
    await this.valkey.set(cacheKey, (count + 1).toString(), 60);

    return true;
  }
}
