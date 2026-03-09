ALTER TABLE "users" ADD COLUMN "microsoft_id" varchar(255);--> statement-breakpoint
CREATE UNIQUE INDEX "drink_votes_user_date_unique" ON "drink_votes" USING btree ("user_id","date");--> statement-breakpoint
CREATE UNIQUE INDEX "orders_user_date_unique" ON "orders" USING btree ("user_id","date");--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_microsoft_id_unique" UNIQUE("microsoft_id");