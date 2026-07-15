import { Injectable, BadRequestException } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class SmsService {
  async sendSms(phoneNumber: string, code: string): Promise<void> {
    const provider = process.env.SMS_PROVIDER;
    if (!provider) {
      throw new BadRequestException(
        '[Awaiting SMS credentials] SMS_PROVIDER is not configured. Supported: twilio, fast2sms, msg91.',
      );
    }

    const cleanPhone = phoneNumber.replaceAll(' ', '').replaceAll('-', '');

    if (provider.toLowerCase() === 'twilio') {
      const accountSid = process.env.TWILIO_ACCOUNT_SID;
      const authToken = process.env.TWILIO_AUTH_TOKEN;
      const fromNumber = process.env.TWILIO_FROM_NUMBER;

      if (!accountSid || !authToken || !fromNumber) {
        throw new BadRequestException(
          '[Awaiting Twilio credentials] Twilio integration requires TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_FROM_NUMBER.',
        );
      }

      try {
        const authHeader = Buffer.from(`${accountSid}:${authToken}`).toString('base64');
        await axios.post(
          `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
          new URLSearchParams({
            To: cleanPhone,
            From: fromNumber,
            Body: `Your Project Phoenix verification code is: ${code}. Valid for 5 minutes.`,
          }),
          {
            headers: {
              Authorization: `Basic ${authHeader}`,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          },
        );
      } catch (e: any) {
        throw new BadRequestException(`Twilio dispatch failed: ${e.response?.data?.message || e.message}`);
      }
    } else if (provider.toLowerCase() === 'fast2sms') {
      const apiKey = process.env.FAST2SMS_API_KEY;
      if (!apiKey) {
        throw new BadRequestException(
          '[Awaiting Fast2SMS credentials] Fast2SMS integration requires FAST2SMS_API_KEY.',
        );
      }

      try {
        await axios.post(
          'https://www.fast2sms.com/dev/bulkV2',
          {
            route: 'otp',
            variables_values: code,
            numbers: cleanPhone,
          },
          {
            headers: {
              authorization: apiKey,
              'Content-Type': 'application/json',
            },
          },
        );
      } catch (e: any) {
        throw new BadRequestException(`Fast2SMS dispatch failed: ${e.response?.data?.message || e.message}`);
      }
    } else if (provider.toLowerCase() === 'msg91') {
      const authKey = process.env.MSG91_AUTH_KEY;
      const senderId = process.env.MSG91_SENDER_ID || 'PHOENX';
      const templateId = process.env.MSG91_TEMPLATE_ID;

      if (!authKey || !templateId) {
        throw new BadRequestException(
          '[Awaiting MSG91 credentials] MSG91 integration requires MSG91_AUTH_KEY and MSG91_TEMPLATE_ID.',
        );
      }

      try {
        await axios.post(
          'https://api.msg91.com/api/v5/otp',
          {
            template_id: templateId,
            mobile: cleanPhone,
            authkey: authKey,
            otp: code,
          },
          {
            headers: {
              'Content-Type': 'application/json',
            },
          },
        );
      } catch (e: any) {
        throw new BadRequestException(`MSG91 dispatch failed: ${e.response?.data?.message || e.message}`);
      }
    } else {
      throw new BadRequestException(`Unsupported SMS provider: ${provider}`);
    }
  }
}
