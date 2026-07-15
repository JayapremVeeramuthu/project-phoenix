import { Controller, Post, Get, Delete, Query, Param, UseInterceptors, UploadedFile, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiQuery, ApiResponse } from '@nestjs/swagger';
import { MinioService } from '../common/services/minio.service';

@ApiTags('Media & Storage')
@Controller('media')
export class MediaController {
  constructor(private readonly minioService: MinioService) {}

  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload file to MinIO bucket' })
  @ApiResponse({ status: 201, description: 'File uploaded successfully' })
  async uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }
    const fileName = `${Date.now()}_${file.originalname.replace(/\s+/g, '_')}`;
    const url = await this.minioService.uploadFile(
      fileName,
      file.buffer,
      file.size,
      file.mimetype,
    );
    return {
      fileName,
      url,
    };
  }

  @Get('presign-upload')
  @ApiOperation({ summary: 'Generate a presigned PUT URL for direct file upload' })
  @ApiQuery({ name: 'fileName', required: true })
  async getPresignedUploadUrl(@Query('fileName') fileName: string) {
    if (!fileName) {
      throw new BadRequestException('fileName query parameter is required');
    }
    const cleanFileName = `${Date.now()}_${fileName.replace(/\s+/g, '_')}`;
    const uploadUrl = await this.minioService.getPresignedUploadUrl(cleanFileName);
    return {
      fileName: cleanFileName,
      uploadUrl,
    };
  }

  @Get('presign-download')
  @ApiOperation({ summary: 'Generate a presigned GET URL for viewing/downloading an object' })
  @ApiQuery({ name: 'fileName', required: true })
  async getPresignedDownloadUrl(@Query('fileName') fileName: string) {
    if (!fileName) {
      throw new BadRequestException('fileName query parameter is required');
    }
    const downloadUrl = await this.minioService.getSignedUrl(fileName);
    return {
      fileName,
      downloadUrl,
    };
  }

  @Delete(':fileName')
  @ApiOperation({ summary: 'Delete file from MinIO bucket' })
  async deleteFile(@Param('fileName') fileName: string) {
    await this.minioService.deleteFile(fileName);
    return {
      success: true,
      message: `Object ${fileName} deleted successfully.`,
    };
  }

  @Get('list')
  @ApiOperation({ summary: 'List all objects stored inside the MinIO bucket' })
  async listFiles() {
    const files = await this.minioService.listFiles();
    return {
      files,
    };
  }
}
