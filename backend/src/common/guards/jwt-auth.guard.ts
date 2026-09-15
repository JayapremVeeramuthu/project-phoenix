import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);
    if (!token) {
      throw new UnauthorizedException('Authentication token required');
    }

    try {
      const payload = this.jwtService.verify(token, {
        secret:
          process.env.JWT_ACCESS_SECRET ||
          'phoenix_jwt_access_secret_key_123456',
      });
      request.user = {
        id: payload.sub,
        sub: payload.sub,
        role: payload.role,
      };
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired authentication token');
    }
  }

  private extractTokenFromHeader(request: any): string | undefined {
    const authHeader = request.headers?.authorization;
    if (!authHeader) return undefined;
    const [type, token] = authHeader.split(' ');
    return type === 'Bearer' ? token : undefined;
  }
}

@Injectable()
export class OptionalJwtAuthGuard implements CanActivate {
  constructor(private jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers?.authorization;
    if (!authHeader) {
      return true;
    }

    const [type, token] = authHeader.split(' ');
    if (type !== 'Bearer' || !token) {
      return true;
    }

    try {
      const payload = this.jwtService.verify(token, {
        secret:
          process.env.JWT_ACCESS_SECRET ||
          'phoenix_jwt_access_secret_key_123456',
      });
      request.user = {
        id: payload.sub,
        sub: payload.sub,
        role: payload.role,
      };
    } catch {
      // Optional token - ignore verification errors for anonymous access
    }

    return true;
  }
}
