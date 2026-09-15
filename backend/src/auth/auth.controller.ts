import {
  Controller,
  Post,
  Get,
  Put,
  Delete,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
  Query,
  Req,
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { CustomerRegisterDto } from './dto/customer-register.dto';
import { CustomerLoginDto } from './dto/customer-login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { TechnicianLoginDto } from './dto/technician-login.dto';
import { TechnicianAvailabilityDto } from './dto/technician-availability.dto';
import { AdminLoginDto } from './dto/admin-login.dto';
import { RateLimiterGuard } from '../common/guards/rate-limiter.guard';
import { OptionalJwtAuthGuard } from '../common/guards/jwt-auth.guard';

@ApiTags('Authentication')
@Controller('auth')
@UseGuards(RateLimiterGuard)
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  @ApiOperation({ summary: 'Register customer account with email, phone, name and password' })
  @ApiResponse({ status: 201, description: 'User successfully created in database' })
  async register(@Body() dto: CustomerRegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate customer with email and password' })
  @ApiResponse({ status: 200, description: 'Tokens issued successfully' })
  async login(@Body() dto: CustomerLoginDto) {
    return this.authService.login(dto);
  }

  @Post('technician/login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate a technician using ID and password' })
  @ApiResponse({ status: 200, description: 'Technician authenticated successfully' })
  async technicianLogin(@Body() dto: TechnicianLoginDto) {
    return this.authService.technicianLogin(dto);
  }

  @Put('technician/availability')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Toggle technician availability (online/offline)' })
  @ApiResponse({ status: 200, description: 'Availability updated successfully' })
  async updateAvailability(@Body() dto: TechnicianAvailabilityDto) {
    return this.authService.updateAvailability(dto);
  }

  @Post('admin/login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate an admin user' })
  @ApiResponse({ status: 200, description: 'Admin authenticated successfully' })
  async adminLogin(@Body() dto: AdminLoginDto) {
    return this.authService.adminLogin(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh access tokens using a valid refresh token' })
  @ApiResponse({ status: 200, description: 'Tokens rotated successfully' })
  async refresh(@Body() dto: RefreshDto) {
    return this.authService.refresh(dto.refresh_token);
  }

  @Post('google')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Authenticate user Google Sign-In' })
  async googleLogin(@Body() dto: any) {
    return this.authService.googleLogin(dto.idToken);
  }

  @Post('otp-send')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request OTP verification code' })
  async otpSend() {
    return { message: 'Phone OTP verification requires an active SMS gateway or client provider.' };
  }

  @Post('otp-verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify OTP code' })
  async otpVerify(@Body() dto: any) {
    return this.authService.otpVerify(dto.idToken);
  }

  @Post('otp-resend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Resend OTP verification code' })
  async otpResend() {
    return { message: 'Phone OTP resend requires an active SMS gateway or client provider.' };
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Password recovery trigger' })
  async forgotPassword() {
    return { message: 'Password recovery dispatches are managed via email or SMS gateway.' };
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reset password credentials verification' })
  async resetPassword() {
    return { message: 'Password updates are managed via backend authentication credentials.' };
  }

  @Post('logout')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Invalidate user sessions and delete refresh tokens' })
  async logout(@Req() req: any, @Query('userId') userId?: string) {
    const effectiveUserId = req.user?.sub || req.user?.id || userId;
    if (!effectiveUserId) {
      return { message: 'Logout completed.' };
    }
    return this.authService.logout(effectiveUserId);
  }

  @Get('profile')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Retrieve user profile statistics and properties' })
  async getProfile(@Req() req: any, @Query('userId') userId?: string) {
    const effectiveUserId = req.user?.sub || req.user?.id || userId;
    if (!effectiveUserId) {
      throw new BadRequestException('User ID or Bearer token is required.');
    }
    return this.authService.getProfile(effectiveUserId);
  }

  @Put('profile')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update user profile details' })
  async updateProfile(@Req() req: any, @Body() dto: UpdateProfileDto) {
    if (!dto.userId && (req.user?.sub || req.user?.id)) {
      dto.userId = req.user?.sub || req.user?.id;
    }
    return this.authService.updateProfile(dto);
  }

  @Delete('address')
  @UseGuards(OptionalJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete user address' })
  async deleteAddress(@Req() req: any, @Query('userId') userId?: string) {
    const effectiveUserId = req.user?.sub || req.user?.id || userId;
    if (!effectiveUserId) {
      throw new BadRequestException('User ID or Bearer token is required.');
    }
    return this.authService.deleteAddress(effectiveUserId);
  }

  @Post('technician/change-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Change password for a technician' })
  @ApiResponse({ status: 200, description: 'Password updated successfully' })
  async technicianChangePassword(
    @Body('userId') userId: string,
    @Body('newPassword') newPassword: string,
    @Body('currentPassword') currentPassword?: string,
  ) {
    return this.authService.technicianChangePassword({ userId, currentPassword, newPassword });
  }
}
