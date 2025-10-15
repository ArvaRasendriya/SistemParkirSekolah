

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."cleanup_old_parkir"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
  DELETE FROM public.parkir
  WHERE created_at < NOW() - INTERVAL '30 days';
$$;


ALTER FUNCTION "public"."cleanup_old_parkir"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  -- Insert data baru ke tabel profiles setiap kali ada user baru di auth.users
  insert into public.profiles (id, full_name, role, status, created_at)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name', -- ambil nama dari metadata saat register
    'satgas',                            -- default role satgas
    'pending',                           -- default status pending (butuh approve admin)
    now()
  );
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."parkir" (
    "id" integer NOT NULL,
    "siswa_id" "uuid" NOT NULL,
    "waktu" time without time zone DEFAULT CURRENT_TIME,
    "tanggal" "date" DEFAULT CURRENT_DATE,
    "status" "text" DEFAULT 'Sudah Parkir'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "scanned_by" "text"
);


ALTER TABLE "public"."parkir" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."parkir_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."parkir_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."parkir_id_seq" OWNED BY "public"."parkir"."id";



CREATE TABLE IF NOT EXISTS "public"."pending_siswa" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nama" "text" NOT NULL,
    "kelas" "text" NOT NULL,
    "jurusan" "text" NOT NULL,
    "email" "text" NOT NULL,
    "sim_url" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."pending_siswa" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "full_name" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "role" "text" DEFAULT 'satgas'::"text",
    "status" "text" DEFAULT 'pending'::"text",
    "approved_by" "uuid",
    "email" "text",
    "kelas" "text",
    "jadwal_piket" "text",
    "jurusan" "text"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."siswa" (
    "id" "uuid" NOT NULL,
    "nama" "text" NOT NULL,
    "kelas" "text" NOT NULL,
    "jurusan" "text" NOT NULL,
    "sim_url" "text",
    "qr_url" "text",
    "created_at" timestamp without time zone DEFAULT "now"(),
    "email" "text" DEFAULT 'NULL'::"text" NOT NULL,
    "status" "text"
);


ALTER TABLE "public"."siswa" OWNER TO "postgres";


ALTER TABLE ONLY "public"."parkir" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."parkir_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."parkir"
    ADD CONSTRAINT "parkir_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pending_siswa"
    ADD CONSTRAINT "pending_siswa_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."pending_siswa"
    ADD CONSTRAINT "pending_siswa_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."siswa"
    ADD CONSTRAINT "siswa_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "unique_email" UNIQUE ("email");



CREATE INDEX "idx_parkir_created_at" ON "public"."parkir" USING "btree" ("created_at");



ALTER TABLE ONLY "public"."parkir"
    ADD CONSTRAINT "parkir_siswa_id_fkey" FOREIGN KEY ("siswa_id") REFERENCES "public"."siswa"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "public"."profiles"("id");



CREATE POLICY "Admin bisa akses semua" ON "public"."profiles" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "profiles_1"
  WHERE (("profiles_1"."id" = "auth"."uid"()) AND ("profiles_1"."role" = 'admin'::"text")))));



CREATE POLICY "Allow authenticated users to insert siswa" ON "public"."siswa" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Allow authenticated users to select siswa" ON "public"."siswa" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Hanya user approved yang bisa akses" ON "public"."profiles" FOR SELECT USING ((("auth"."uid"() = "id") AND ("status" = 'approved'::"text")));



CREATE POLICY "Semua user login bisa lihat semua siswa" ON "public"."siswa" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "User bisa hapus datanya sendiri" ON "public"."siswa" FOR DELETE TO "authenticated" USING (("id" = "auth"."uid"()));



CREATE POLICY "User bisa update datanya sendiri" ON "public"."siswa" FOR UPDATE TO "authenticated" USING (("id" = "auth"."uid"()));



CREATE POLICY "User hanya bisa insert datanya sendiri" ON "public"."siswa" FOR INSERT TO "authenticated" WITH CHECK (("id" = "auth"."uid"()));



CREATE POLICY "User hanya bisa lihat profile sendiri" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "allow_insert_authenticated" ON "public"."parkir" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "allow_select_authenticated" ON "public"."parkir" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";









GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";














































































































































































GRANT ALL ON FUNCTION "public"."cleanup_old_parkir"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_old_parkir"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_old_parkir"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";
























GRANT ALL ON TABLE "public"."parkir" TO "anon";
GRANT ALL ON TABLE "public"."parkir" TO "authenticated";
GRANT ALL ON TABLE "public"."parkir" TO "service_role";



GRANT ALL ON SEQUENCE "public"."parkir_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."parkir_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."parkir_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."pending_siswa" TO "anon";
GRANT ALL ON TABLE "public"."pending_siswa" TO "authenticated";
GRANT ALL ON TABLE "public"."pending_siswa" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."siswa" TO "anon";
GRANT ALL ON TABLE "public"."siswa" TO "authenticated";
GRANT ALL ON TABLE "public"."siswa" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






























RESET ALL;
