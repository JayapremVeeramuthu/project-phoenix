import { Controller, Post, Get, Put, Body, HttpCode, HttpStatus, UseGuards, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { FirebaseTokenDto } from './dto/firebase-token.dto';
import { RefreshDto } from './dto/refresh.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { RateLimiterGuard } from '../common/guards/rate-limiter.guard';

@ApiTags('Authentication')
@Controller('auth')
@UseGuards(RateLimiterGuard)
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  @ApiOperation({ summary: 'Sync Firebase register account with PostgreSQL User profile' })
  @ApiResponse({ status: 201, description: 'User successfully created in database' })
  async register(@Body() dto: FirebaseTokenDto) {
    return this.authService.register(dto.idToken);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Sync Firebase login with PostgreSQL user details' })
  @ApiResponse({ status: 200, description: 'Tokens issued successfully' })
  async login(@Body() dto: FirebaseTokenDto) {
    return this.authService.login(dto.idToken);
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
  @ApiOperation({ summary: 'Authenticate user Google Sign-In profile verified by Firebase ID token' })
  async googleLogin(@Body() dto: FirebaseTokenDto) {
    return this.authService.googleLogin(dto.idToken);
  }

  @Post('otp-send')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request OTP verification code (handled on client SDK)' })
  async otpSend() {
    return { message: 'OTP dispatch is initialized directly on the client application.' };
  }

  @Post('otp-verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify OTP code and authenticate session via Firebase ID token' })
  async otpVerify(@Body() dto: FirebaseTokenDto) {
    return this.authService.otpVerify(dto.idToken);
  }

  @Post('otp-resend')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Resend OTP verification code (handled on client SDK)' })
  async otpResend() {
    return { message: 'OTP resend sequence is processed on the client application.' };
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Forgot password reset trigger (redirects to Firebase recovery console)' })
  async forgotPassword() {
    return { message: 'Password recovery dispatches are managed via the Firebase Authentication console.' };
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reset password credentials verification' })
  async resetPassword() {
    return { message: 'Password updates are directly committed on the Firebase Auth console.' };
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Invalidate user sessions and delete refresh tokens' })
  async logout(@Query('userId') userId: string) {
    return this.authService.logout(userId);
  }

  @Get('profile')
  @ApiOperation({ summary: 'Retrieve user profile statistics and properties' })
  async getProfile(@Query('userId') userId: string) {
    return this.authService.getProfile(userId);
  }

  @Put('profile')
  @ApiOperation({ summary: 'Update user profile details' })
  async updateProfile(@Body() dto: UpdateProfileDto) {
    return this.authService.updateProfile(dto);
  }
}
