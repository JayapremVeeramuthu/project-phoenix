jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(),
  cert: jest.fn(),
  getApps: jest.fn(() => []),
}));
jest.mock('firebase-admin/auth', () => ({
  getAuth: jest.fn(() => ({
    verifyIdToken: jest.fn(),
  })),
}));

import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException, ConflictException, BadRequestException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';

describe('AuthService', () => {
  let service: AuthService;

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    auditLog: {
      create: jest.fn().mockResolvedValue({ id: 'audit-1' }),
    },
  };

  const mockJwtService = {
    sign: jest.fn().mockReturnValue('mock_jwt_token'),
    verify: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: JwtService, useValue: mockJwtService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('registerCustomer', () => {
    it('should throw BadRequestException if required fields are missing', async () => {
      await expect(
        service.registerCustomer({ email: 'test@example.com' } as any),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw ConflictException if email is already registered', async () => {
      mockPrismaService.user.findUnique.mockResolvedValueOnce({ id: 'existing-id' });

      await expect(
        service.registerCustomer({
          name: 'Jane Doe',
          email: 'jane@example.com',
          phoneNumber: '+919988776655',
          password: 'Password123!',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('should throw ConflictException if phone number is already registered', async () => {
      mockPrismaService.user.findUnique
        .mockResolvedValueOnce(null) // email not taken
        .mockResolvedValueOnce({ id: 'existing-phone-id' }); // phone taken

      await expect(
        service.registerCustomer({
          name: 'Jane Doe',
          email: 'jane@example.com',
          phoneNumber: '+919988776655',
          password: 'Password123!',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('should successfully register a new customer and return JWT tokens and sanitized user', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);
      const createdUser = {
        id: 'new-cust-uuid',
        name: 'Jane Doe',
        email: 'jane@example.com',
        phoneNumber: '+919988776655',
        password: 'hashed_password',
        refreshToken: 'hashed_refresh',
        role: 'CUSTOMER',
        isActive: true,
      };
      mockPrismaService.user.create.mockResolvedValue(createdUser);
      mockPrismaService.user.update.mockResolvedValue(createdUser);

      const result = await service.registerCustomer({
        name: 'Jane Doe',
        email: 'jane@example.com',
        phoneNumber: '+919988776655',
        password: 'Password123!',
      });

      expect(result).toHaveProperty('access_token');
      expect(result).toHaveProperty('refresh_token');
      expect(result.user.id).toBe('new-cust-uuid');
      expect(result.user).not.toHaveProperty('password');
      expect(result.user).not.toHaveProperty('refreshToken');
    });
  });

  describe('loginCustomer', () => {
    it('should throw UnauthorizedException for unknown email', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      await expect(
        service.loginCustomer({
          email: 'unknown@example.com',
          password: 'password',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for incorrect password', async () => {
      const hashedPassword = await bcrypt.hash('CorrectPassword123!', 10);
      mockPrismaService.user.findUnique.mockResolvedValue({
        id: 'user-id',
        email: 'test@example.com',
        password: hashedPassword,
        isActive: true,
        role: 'CUSTOMER',
      });

      await expect(
        service.loginCustomer({
          email: 'test@example.com',
          password: 'WrongPassword!',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should successfully log in and return tokens with valid password', async () => {
      const plainPassword = 'CorrectPassword123!';
      const hashedPassword = await bcrypt.hash(plainPassword, 10);
      const user = {
        id: 'cust-uuid-valid',
        email: 'test@example.com',
        password: hashedPassword,
        isActive: true,
        role: 'CUSTOMER',
      };
      mockPrismaService.user.findUnique.mockResolvedValue(user);
      mockPrismaService.user.update.mockResolvedValue(user);

      const result = await service.loginCustomer({
        email: 'test@example.com',
        password: plainPassword,
      });

      expect(result).toHaveProperty('access_token');
      expect(result).toHaveProperty('refresh_token');
      expect(result.user.id).toBe('cust-uuid-valid');
      expect(result.user).not.toHaveProperty('password');
    });
  });

  describe('technicianLogin', () => {
    it('should authenticate a technician with correct technicianId and password', async () => {
      const plainPassword = 'TechPassword123!';
      const hashedPassword = await bcrypt.hash(plainPassword, 10);
      const techUser = {
        id: 'tech-uuid-1',
        technicianId: 'TECH-001',
        name: 'Suresh Kumar',
        role: 'TECHNICIAN',
        password: hashedPassword,
        isOnline: false,
        mustChangePassword: false,
        branch: 'Anna Nagar',
      };
      mockPrismaService.user.findFirst.mockResolvedValue(techUser);
      mockPrismaService.user.update.mockResolvedValue(techUser);

      const result = await service.technicianLogin({
        technicianId: 'TECH-001',
        password: plainPassword,
      });

      expect(result).toHaveProperty('access_token');
      expect(result.user.technicianId).toBe('TECH-001');
    });
  });
});
