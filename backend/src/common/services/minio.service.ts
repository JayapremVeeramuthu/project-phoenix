import { Injectable, OnModuleInit } from '@nestjs/common';
import * as Minio from 'minio';

@Injectable()
export class MinioService implements OnModuleInit {
  private minioClient: Minio.Client;
  private readonly bucketName = process.env.MINIO_BUCKET_NAME || 'project-phoenix';

  async onModuleInit() {
    this.minioClient = new Minio.Client({
      endPoint: process.env.MINIO_ENDPOINT || 'localhost',
      port: parseInt(process.env.MINIO_PORT || '9000', 10),
      useSSL: false,
      accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
      secretKey: process.env.MINIO_SECRET_KEY || 'minioadminpassword',
    });

    // Create bucket automatically during startup with retry logic
    await this.ensureBucketExistsWithRetry(5, 2000);
  }

  private async ensureBucketExistsWithRetry(retries: number, delayMs: number): Promise<void> {
    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        const exists = await this.minioClient.bucketExists(this.bucketName);
        if (!exists) {
          await this.minioClient.makeBucket(this.bucketName, 'us-east-1');
          console.log(`Bucket "${this.bucketName}" created successfully.`);
        } else {
          console.log(`Bucket "${this.bucketName}" already exists.`);
        }
        
        // Apply anonymous read-only policy for objects in the bucket
        const policy = {
          Version: '2012-10-17',
          Statement: [
            {
              Effect: 'Allow',
              Principal: { AWS: ['*'] },
              Action: ['s3:GetObject'],
              Resource: [`arn:aws:s3:::${this.bucketName}/*`],
            },
          ],
        };
        await this.minioClient.setBucketPolicy(this.bucketName, JSON.stringify(policy));
        console.log(`Public read policy applied successfully to bucket "${this.bucketName}".`);
        return; // Success
      } catch (err) {
        console.error(`MinIO connection attempt ${attempt} failed: ${err.message}`);
        if (attempt === retries) {
          throw new Error(`Failed to initialize MinIO bucket after ${retries} attempts`);
        }
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }
  }

  // Helper with retry logic
  async runWithRetry<T>(fn: () => Promise<T>, retries = 3, delayMs = 1000): Promise<T> {
    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        return await fn();
      } catch (err) {
        if (attempt === retries) throw err;
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }
    throw new Error('Unreachable code');
  }

  async uploadFile(fileName: string, buffer: Buffer, size: number, contentType: string): Promise<string> {
    return this.runWithRetry(async () => {
      await this.minioClient.putObject(this.bucketName, fileName, buffer, size, {
        'Content-Type': contentType,
      });
      const publicUrl = process.env.MINIO_PUBLIC_URL || 'http://localhost:9005';
      return `${publicUrl}/${this.bucketName}/${fileName}`;
    });
  }

  async getPresignedUploadUrl(fileName: string, expirySeconds = 3600): Promise<string> {
    return this.runWithRetry(async () => {
      return await this.minioClient.presignedPutObject(this.bucketName, fileName, expirySeconds);
    });
  }

  async getSignedUrl(fileName: string, expirySeconds = 3600): Promise<string> {
    return this.runWithRetry(async () => {
      return await this.minioClient.presignedGetObject(this.bucketName, fileName, expirySeconds);
    });
  }

  async deleteFile(fileName: string): Promise<void> {
    return this.runWithRetry(async () => {
      await this.minioClient.removeObject(this.bucketName, fileName);
    });
  }

  async listFiles(): Promise<any[]> {
    return this.runWithRetry(async () => {
      return new Promise((resolve, reject) => {
        const stream = this.minioClient.listObjectsV2(this.bucketName, '', true);
        const files: any[] = [];
        stream.on('data', (obj) => files.push(obj));
        stream.on('error', (err) => reject(err));
        stream.on('end', () => resolve(files));
      });
    });
  }
}
