import { Injectable, UnauthorizedException, BadRequestException, OnModuleInit, ForbiddenException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import * as fs from 'fs';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { TechnicianLoginDto } from './dto/technician-login.dto';
import { TechnicianAvailabilityDto } from './dto/technician-availability.dto';
import { AdminLoginDto } from './dto/admin-login.dto';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class AuthService implements OnModuleInit {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  onModuleInit() {
    try {
      if (!getApps().length) {
        const credentialsPath = process.env.FIREBASE_CREDENTIALS_PATH;
        console.log(`Credentials path: ${credentialsPath}`);
        if (credentialsPath) {
          const fileExists = fs.existsSync(credentialsPath);
          console.log(`Credentials file exists: ${fileExists}`);
          if (fileExists) {
            const serviceAccount = JSON.parse(
              fs.readFileSync(credentialsPath, 'utf8'),
            );
            initializeApp({
              credential: cert(serviceAccount),
            });
            console.log('Firebase Admin initialized successfully');
          } else {
            console.warn(`[Phoenix Auth] Credentials file does NOT exist at path: ${credentialsPath}`);
          }
        } else {
          console.warn('[Phoenix Auth] Awaiting Firebase credentials: FIREBASE_CREDENTIALS_PATH is NOT configured.');
        }
      }
    } catch (error) {
      console.error('Firebase Admin initialization error:', error);
    }
  }

  // --- Real Firebase ID Token Verification Strategy ---
  async verifyFirebaseToken(idToken: string) {
    if (!getApps().length) {
      throw new BadRequestException(
        '[Awaiting Firebase credentials] Firebase Admin SDK is not initialized. Please configure FIREBASE_CREDENTIALS_PATH in .env.',
      );
    }

    try {
      const decodedToken = await getAuth().verifyIdToken(idToken);
      return decodedToken;
    } catch (e: any) {
      throw new UnauthorizedException(`Invalid Firebase ID token: ${e.message}`);
    }
  }

  // --- Sync Firebase User profile with PostgreSQL User record ---
  async syncFirebaseUser(idToken: string) {
    const decodedToken = await this.verifyFirebaseToken(idToken);
    const uid = decodedToken.uid;

    let firebaseName: string | null = null;
    let firebaseAvatar: string | null = null;
    let firebaseEmail: string | null = null;
    let firebasePhone: string | null = null;
    let firebaseProvider: string | null = null;

    try {
      const userRecord = await getAuth().getUser(uid);
      firebaseName = userRecord.displayName || null;
      firebaseAvatar = userRecord.photoURL || null;
      firebaseEmail = userRecord.email || null;
      firebasePhone = userRecord.phoneNumber || null;

      if (userRecord.providerData && userRecord.providerData.length > 0) {
        const googleProvider = userRecord.providerData.find(p => p.providerId === 'google.com');
        firebaseProvider = googleProvider ? googleProvider.providerId : userRecord.providerData[0].providerId;
      }
    } catch (err) {
      console.warn('Failed to fetch full UserRecord from Firebase Admin, falling back to ID Token claims:', err);
    }

    const email = firebaseEmail || decodedToken.email || null;
    const phone = firebasePhone || decodedToken.phone_number || null;
    const name = firebaseName || decodedToken.name || email?.split('@')[0] || phone || 'Firebase User';
    const avatarUrl = firebaseAvatar || decodedToken.picture || null;
    const provider = firebaseProvider || decodedToken.firebase?.sign_in_provider || 'unknown';

    let user = await this.prisma.user.findUnique({
      where: { firebaseUid: uid },
    });

    if (!user) {
      // Check if user already exists with this email or phone to link accounts
      if (email) {
        user = await this.prisma.user.findUnique({ where: { email } });
      }
      if (!user && phone) {
        user = await this.prisma.user.findUnique({ where: { phoneNumber: phone } });
      }

      if (user) {
        // Link existing account to this Firebase UID
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: {
            firebaseUid: uid,
            name: user.name || name,
            avatarUrl: user.avatarUrl || avatarUrl,
            provider,
            lastLoginAt: new Date(),
          },
        });
      } else {
        // Create a new user profile record in PostgreSQL
        const formattedPhone = phone || `fb_${uid}`;
        user = await this.prisma.user.create({
          data: {
            firebaseUid: uid,
            email,
            phoneNumber: formattedPhone,
            name,
            avatarUrl,
            provider,
            role: 'CUSTOMER',
            lastLoginAt: new Date(),
          },
        });

        await this.prisma.auditLog.create({
          data: {
            userId: user.id,
            action: 'FIREBASE_REGISTER',
            details: `Registered user via Firebase Auth UID: ${uid}`,
          },
        });
      }
    } else {
      // Update existing record profiles
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: {
          name: user.name || name,
          avatarUrl: user.avatarUrl || avatarUrl,
          provider,
          lastLoginAt: new Date(),
        },
      });

      await this.prisma.auditLog.create({
        data: {
          userId: user.id,
          action: 'FIREBASE_LOGIN',
          details: `Logged in user via Firebase Auth UID: ${uid}`,
        },
      });
    }

    const tokens = await this.generateTokens(user.id, user.role);
    return {
      ...tokens,
      user,
    };
  }

  // --- REST Routes Handlers mapped to Firebase Verification ---
  async register(idToken: string) {
    return this.syncFirebaseUser(idToken);
  }

  async login(idToken: string) {
    return this.syncFirebaseUser(idToken);
  }

  async googleLogin(idToken: string) {
    return this.syncFirebaseUser(idToken);
  }

  async otpVerify(idToken: string) {
    return this.syncFirebaseUser(idToken);
  }

  async refresh(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET || 'phoenix_jwt_refresh_secret_key_654321',
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });
      if (!user || user.refreshToken !== refreshToken) {
        throw new UnauthorizedException('Invalid or expired refresh token');
      }

      return this.generateTokens(user.id, user.role);
    } catch (_) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { refreshToken: null },
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: 'USER_LOGOUT',
        details: `User logged out: ${userId}`,
      },
    });

    return { message: 'Logout successful.' };
  }

  private async generateTokens(userId: string, role: string) {
    const payload = { sub: userId, role };
    const accessToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_ACCESS_SECRET || 'phoenix_jwt_access_secret_key_123456',
      expiresIn: process.env.JWT_ACCESS_EXPIRY || '15m',
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_REFRESH_SECRET || 'phoenix_jwt_refresh_secret_key_654321',
      expiresIn: process.env.JWT_REFRESH_EXPIRY || '7d',
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { refreshToken },
    });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
    };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new BadRequestException('User not found.');
    }
    return user;
  }

  async updateProfile(dto: UpdateProfileDto) {
    const { userId, ...fields } = dto;
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new BadRequestException('User not found.');
    }

    if (user.isFounder) {
      if (fields.email && fields.email !== user.email) {
        throw new ForbiddenException('The Founder Admin email cannot be changed.');
      }
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: fields,
    });

    await this.prisma.auditLog.create({
      data: {
        userId,
        action: 'UPDATE_PROFILE',
        details: `Updated profile details: ${Object.keys(fields).join(', ')}`,
      },
    });

    return updatedUser;
  }

  async technicianLogin(dto: TechnicianLoginDto) {
    const user = await this.prisma.user.findFirst({
      where: {
        technicianId: dto.technicianId.toUpperCase(),
        role: 'TECHNICIAN',
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.password || '');
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.generateTokens(user.id, user.role);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: user.id,
        action: 'TECHNICIAN_LOGIN',
        details: `Technician logged in with ID: ${dto.technicianId}`,
      },
    });

    return {
      ...tokens,
      user: {
        id: user.id,
        name: user.name,
        role: user.role,
        email: user.email,
        phoneNumber: user.phoneNumber,
        technicianId: user.technicianId,
        branch: user.branch,
        isOnline: user.isOnline,
        mustChangePassword: user.mustChangePassword,
      },
    };
  }

  async updateAvailability(dto: TechnicianAvailabilityDto) {
    const updatedUser = await this.prisma.user.update({
      where: { id: dto.userId },
      data: { isOnline: dto.isOnline },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: dto.userId,
        action: 'UPDATE_AVAILABILITY',
        details: `Technician availability updated to: ${dto.isOnline ? 'ONLINE' : 'OFFLINE'}`,
      },
    });

    return {
      userId: updatedUser.id,
      isOnline: updatedUser.isOnline,
    };
  }

  async adminLogin(dto: AdminLoginDto) {
    const user = await this.prisma.user.findFirst({
      where: {
        email: dto.email,
        role: 'FOUNDER_ADMIN',
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.password || '');
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.generateTokens(user.id, user.role);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: user.id,
        action: 'ADMIN_LOGIN',
        details: `Admin logged in with email: ${dto.email}`,
      },
    });

    return {
      ...tokens,
      user: {
        id: user.id,
        name: user.name,
        role: user.role,
        email: user.email,
        phoneNumber: user.phoneNumber,
      },
    };
  }

  async technicianChangePassword(dto: { userId: string; currentPassword?: string; newPassword: string }) {
    const user = await this.prisma.user.findUnique({
      where: { id: dto.userId },
    });
    if (!user || user.role !== 'TECHNICIAN') {
      throw new NotFoundException('Technician not found.');
    }

    const password = dto.newPassword;
    const hasMinLength = password.length >= 8;
    const hasUppercase = /[A-Z]/.test(password);
    const hasLowercase = /[a-z]/.test(password);
    const hasNumber = /\d/.test(password);
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>_~\-+=/[\]\\`';]/.test(password) || /[_\W]/.test(password);

    if (!hasMinLength || !hasUppercase || !hasLowercase || !hasNumber || !hasSpecial) {
      throw new BadRequestException(
        'Password must be at least 8 characters long, containing at least one uppercase letter, one lowercase letter, one number, and one special character.',
      );
    }

    const isSameAsOld = await bcrypt.compare(dto.newPassword, user.password || '');
    if (isSameAsOld) {
      throw new BadRequestException('New password cannot be the same as the current or temporary password.');
    }

    if (!user.mustChangePassword) {
      if (!dto.currentPassword) {
        throw new BadRequestException('Current password is required.');
      }
      const isPasswordValid = await bcrypt.compare(dto.currentPassword, user.password || '');
      if (!isPasswordValid) {
        throw new BadRequestException('Incorrect current password.');
      }
    }

    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);
    await this.prisma.user.update({
      where: { id: dto.userId },
      data: {
        password: hashedPassword,
        mustChangePassword: false,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: dto.userId,
        action: 'TECHNICIAN_PASSWORD_CHANGE',
        details: `Technician changed their password successfully.`,
      },
    });

    return { message: 'Password updated successfully.' };
  }
}
