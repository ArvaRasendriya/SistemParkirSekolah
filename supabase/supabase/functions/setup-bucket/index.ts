import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const supabase = createClient(supabaseUrl, supabaseKey);

  const buckets = ["siswa", "foto-profil"];

  for (const name of buckets) {
    const { data, error } = await supabase.storage.createBucket(name, {
      public: true,
      fileSizeLimit: 5242880, // 5 MB per file (opsional)
    });

    if (error && !error.message.includes("already exists")) {
      console.error(`❌ Gagal membuat bucket ${name}:`, error.message);
    } else {
      console.log(`✅ Bucket '${name}' sudah siap`);
    }
  }

  return new Response("Bucket setup selesai ✅", { status: 200 });
});
