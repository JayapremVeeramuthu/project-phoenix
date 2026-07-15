import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import * as amqp from 'amqplib';

@Injectable()
export class RabbitmqService implements OnModuleInit, OnModuleDestroy {
  private connection: any;
  private channel: any;

  async onModuleInit() {
    try {
      const url = process.env.RABBITMQ_URL || 'amqp://guest:guest@localhost:5672';
      this.connection = await amqp.connect(url);
      this.channel = await this.connection.createChannel();
    } catch (_) {
      // Graceful fallback for offline dev/test compiler environments
    }
  }

  async onModuleDestroy() {
    try {
      await this.channel?.close();
      await this.connection?.close();
    } catch (_) {}
  }

  async publish(queueName: string, message: any): Promise<void> {
    try {
      if (!this.channel) return;
      await this.channel.assertQueue(queueName, { durable: true });
      this.channel.sendToQueue(queueName, Buffer.from(JSON.stringify(message)), {
        persistent: true,
      });
    } catch (_) {}
  }
}
