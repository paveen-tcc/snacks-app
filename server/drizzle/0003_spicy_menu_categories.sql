ALTER TABLE "snacks" ADD COLUMN "category" varchar(100);
--> statement-breakpoint
ALTER TABLE "orders" ADD COLUMN "snack_name_snapshot" varchar(100);
--> statement-breakpoint
ALTER TABLE "orders" ADD COLUMN "snack_emoji_snapshot" varchar(10);
--> statement-breakpoint
UPDATE "orders"
SET
  "snack_name_snapshot" = "snacks"."name",
  "snack_emoji_snapshot" = "snacks"."emoji"
FROM "snacks"
WHERE "orders"."snack_id" = "snacks"."id";
--> statement-breakpoint
ALTER TABLE "orders" DROP CONSTRAINT IF EXISTS "orders_snack_id_snacks_id_fk";
