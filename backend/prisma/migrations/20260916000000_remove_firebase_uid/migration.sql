-- DropIndex
DROP INDEX IF EXISTS "User_firebaseUid_key";

-- AlterTable
ALTER TABLE "User" DROP COLUMN IF EXISTS "firebaseUid";
