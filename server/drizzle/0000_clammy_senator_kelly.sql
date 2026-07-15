CREATE TABLE `app_settings` (
	`key` text(50) PRIMARY KEY NOT NULL,
	`value` text NOT NULL,
	`advance_order_mode` integer DEFAULT false NOT NULL,
	`advance_window_start` text(5) DEFAULT '06:00' NOT NULL,
	`advance_window_end` text(5) DEFAULT '22:00' NOT NULL
);
--> statement-breakpoint
CREATE TABLE `holidays` (
	`id` text PRIMARY KEY NOT NULL,
	`date` text NOT NULL,
	`name` text(100),
	`source` text(20) DEFAULT 'manual',
	`created_by` text,
	FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `holidays_date_unique` ON `holidays` (`date`);--> statement-breakpoint
CREATE TABLE `orders` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`date` text NOT NULL,
	`snack_id` text NOT NULL,
	`snack_name_snapshot` text(100),
	`snack_emoji_snapshot` text(512),
	`is_default_assigned` integer DEFAULT false,
	`ordered_at` integer,
	`updated_at` integer,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `orders_user_date_idx` ON `orders` (`user_id`,`date`);--> statement-breakpoint
CREATE TABLE `push_tokens` (
	`token` text(512) PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`platform` text(20) DEFAULT 'android',
	`updated_at` integer,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `push_tokens_user_idx` ON `push_tokens` (`user_id`);--> statement-breakpoint
CREATE TABLE `shutdown_days` (
	`id` text PRIMARY KEY NOT NULL,
	`date` text NOT NULL,
	`reason` text(255),
	`created_by` text,
	FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `shutdown_days_date_unique` ON `shutdown_days` (`date`);--> statement-breakpoint
CREATE TABLE `snacks` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text(100) NOT NULL,
	`category` text(100),
	`emoji` text(512),
	`is_veg` integer DEFAULT true,
	`is_default` integer DEFAULT false,
	`is_active` integer DEFAULT true,
	`serving_size` text(50),
	`share_count` integer DEFAULT 1 NOT NULL,
	`sort_order` integer DEFAULT 0,
	`created_at` integer
);
--> statement-breakpoint
CREATE TABLE `sync_queue` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`table_name` text(50) NOT NULL,
	`record_id` text NOT NULL,
	`action` text(10) NOT NULL,
	`payload` text,
	`created_at` integer,
	`synced_at` integer,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `users` (
	`id` text PRIMARY KEY NOT NULL,
	`username` text(100) NOT NULL,
	`email` text(255) NOT NULL,
	`microsoft_id` text(255),
	`device_id` text(255),
	`is_admin` integer DEFAULT false,
	`created_at` integer
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_username_unique` ON `users` (`username`);--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);--> statement-breakpoint
CREATE UNIQUE INDEX `users_microsoft_id_unique` ON `users` (`microsoft_id`);