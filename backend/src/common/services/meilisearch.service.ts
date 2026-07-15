import { Injectable, OnModuleInit } from '@nestjs/common';
import { MeiliSearch } from 'meilisearch';

@Injectable()
export class MeilisearchService implements OnModuleInit {
  private client: MeiliSearch;

  onModuleInit() {
    this.client = new MeiliSearch({
      host: process.env.MEILISEARCH_HOST || 'http://localhost:7700',
      apiKey: process.env.MEILISEARCH_API_KEY || 'meilimasterkey123',
    });
  }

  async addDocuments(indexUid: string, documents: any[]): Promise<void> {
    try {
      const index = this.client.index(indexUid);
      await index.addDocuments(documents);
    } catch (_) {}
  }

  async search(indexUid: string, query: string): Promise<any[]> {
    try {
      const index = this.client.index(indexUid);
      const result = await index.search(query);
      return result.hits;
    } catch (_) {
      return [];
    }
  }
}
