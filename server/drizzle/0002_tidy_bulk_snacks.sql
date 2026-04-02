DROP INDEX IF EXISTS "orders_user_date_unique";
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "orders_user_date_idx" ON "orders" USING btree ("user_id","date");
