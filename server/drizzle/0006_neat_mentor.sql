ALTER TABLE "drink_votes" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "hot_drinks" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
DROP TABLE "drink_votes" CASCADE;--> statement-breakpoint
DROP TABLE "hot_drinks" CASCADE;--> statement-breakpoint
ALTER TABLE "orders" ALTER COLUMN "snack_emoji_snapshot" SET DATA TYPE varchar(512);--> statement-breakpoint
ALTER TABLE "snacks" ALTER COLUMN "emoji" SET DATA TYPE varchar(512);--> statement-breakpoint
ALTER TABLE "snacks" DROP COLUMN "description";