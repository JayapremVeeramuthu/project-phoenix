const mockVerifyIdToken = jest.fn();
jest.mock('google-auth-library', () => ({
  OAuth2Client: jest.fn().mockImplementation(() => ({
    verifyIdToken: mockVerifyIdToken,
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

  describe('googleLogin', () => {
    it('should throw BadRequestException if idToken is missing', async () => {
      await expect(service.googleLogin('')).rejects.toThrow(BadRequestException);
    });

    it('should successfully authenticate existing user via Google OAuth and return JWT tokens', async () => {
      mockVerifyIdToken.mockResolvedValueOnce({
        getPayload: () => ({
          sub: 'google-sub-123',
          email: 'google.user@example.com',
          name: 'Google User',
          picture: 'https://example.com/avatar.png',
        }),
      });

      const existingUser = {
        id: 'cust-google-uuid',
        googleId: 'google-sub-123',
        email: 'google.user@example.com',
        name: 'Google User',
        role: 'CUSTOMER',
        avatarUrl: 'https://example.com/avatar.png',
      };
      mockPrismaService.user.findUnique.mockResolvedValueOnce(existingUser);
      mockPrismaService.user.update.mockResolvedValueOnce(existingUser);

      const result = await service.googleLogin('valid-google-id-token');

      expect(result).toHaveProperty('access_token');
      expect(result).toHaveProperty('refresh_token');
      expect(result.user.id).toBe('cust-google-uuid');
      expect(result.user.email).toBe('google.user@example.com');
    });

    it('should provision new customer in PostgreSQL when signing in with Google for the first time', async () => {
      mockVerifyIdToken.mockResolvedValueOnce({
        getPayload: () => ({
          sub: 'google-sub-new',
          email: 'new.google@example.com',
          name: 'New Google Customer',
          picture: 'https://example.com/new-avatar.png',
        }),
      });

      mockPrismaService.user.findUnique.mockResolvedValue(null);
      const newUser = {
        id: 'new-google-user-uuid',
        googleId: 'google-sub-new',
        email: 'new.google@example.com',
        name: 'New Google Customer',
        role: 'CUSTOMER',
        avatarUrl: 'https://example.com/new-avatar.png',
      };
      mockPrismaService.user.create.mockResolvedValueOnce(newUser);
      mockPrismaService.user.update.mockResolvedValueOnce(newUser);

      const result = await service.googleLogin('valid-google-id-token');

      expect(result).toHaveProperty('access_token');
      expect(result).toHaveProperty('refresh_token');
      expect(result.user.id).toBe('new-google-user-uuid');
      expect(mockPrismaService.user.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            googleId: 'google-sub-new',
            email: 'new.google@example.com',
            role: 'CUSTOMER',
            provider: 'google',
          }),
        }),
      );
    });
  });

  describe('getProfile, updateProfile, deleteAddress, deleteAccount', () => {
    it('should retrieve user profile successfully', async () => {
      const validUuid = '11111111-1111-1111-1111-111111111111';
      const user = {
        id: validUuid,
        name: 'Test Customer',
        email: 'test@customer.com',
        role: 'CUSTOMER',
      };
      mockPrismaService.user.findUnique.mockResolvedValueOnce(user);

      const result = await service.getProfile(validUuid);
      expect(result.id).toBe(validUuid);
      expect(result.name).toBe('Test Customer');
    });

    it('should soft delete account on deleteAccount', async () => {
      const validUuid = '11111111-1111-1111-1111-111111111111';
      const user = {
        id: validUuid,
        role: 'CUSTOMER',
        isFounder: false,
      };
      mockPrismaService.user.findUnique.mockResolvedValueOnce(user);
      mockPrismaService.user.update.mockResolvedValueOnce({ ...user, isActive: false });

      const result = await service.deleteAccount(validUuid);
      expect(result.message).toBe('Account successfully deleted.');
      expect(mockPrismaService.user.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: validUuid },
          data: expect.objectContaining({
            isActive: false,
            refreshToken: null,
          }),
        }),
      );
    });
  });
});
