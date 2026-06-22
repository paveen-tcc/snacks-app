CREATE TABLE "push_tokens" (
	"token" varchar(512) PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"platform" varchar(20) DEFAULT 'android',
	"updated_at" timestamp with time zone DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "push_tokens" ADD CONSTRAINT "push_tokens_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "push_tokens_user_idx" ON "push_tokens" USING btree ("user_id");