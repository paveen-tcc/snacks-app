CREATE TABLE `daily_purchase_items` (
	`id` text PRIMARY KEY NOT NULL,
	`date` text NOT NULL,
	`source_key` text,
	`source_snack_id` text,
	`name` text(100) NOT NULL,
	`item_type` text NOT NULL,
	`quantity` integer NOT NULL,
	`unit_price_rupees` integer NOT NULL,
	`is_edited` integer DEFAULT false NOT NULL,
	`is_removed` integer DEFAULT false NOT NULL,
	`created_at` integer,
	`updated_at` integer
);
--> statement-breakpoint
CREATE INDEX `daily_purchase_items_date_idx` ON `daily_purchase_items` (`date`);--> statement-breakpoint
CREATE UNIQUE INDEX `daily_purchase_items_date_source_unique` ON `daily_purchase_items` (`date`,`source_key`);--> statement-breakpoint
ALTER TABLE `orders` ADD `snack_price_rupees_snapshot` integer;--> statement-breakpoint
ALTER TABLE `orders` ADD `snack_share_count_snapshot` integer;--> statement-breakpoint
ALTER TABLE `orders` ADD `snack_category_snapshot` text(100);--> statement-breakpoint
ALTER TABLE `snacks` ADD `price_rupees` integer DEFAULT 0 NOT NULL;