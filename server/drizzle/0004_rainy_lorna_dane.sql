ALTER TABLE "app_settings" ADD COLUMN "advance_order_mode" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "app_settings" ADD COLUMN "advance_window_start" varchar(5) DEFAULT '06:00' NOT NULL;--> statement-breakpoint
ALTER TABLE "app_settings" ADD COLUMN "advance_window_end" varchar(5) DEFAULT '22:00' NOT NULL;--> statement-breakpoint
