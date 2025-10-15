import { createClient } from "@supabase/supabase-js";
import fs from "fs";

// Cloud project
const supabaseCloud = createClient(
  "https://rfpsfzbmhhxksisxciwx.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcHNmemJtaGh4a3Npc3hjaXd4Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTEzMzYzMywiZXhwIjoyMDcwNzA5NjMzfQ.Fov6h_mrHIZSMjv-kCMtGJbeAFBOZ-lm8A8FuCmxOoM"
);

// Local project
const supabaseLocal = createClient(
  "http://localhost:54321",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
);

async function migrateBucket(bucketName, prefix = "") {
  const { data: items, error } = await supabaseCloud.storage
    .from(bucketName)
    .list(prefix, { limit: 1000 });

  if (error) throw error;
  if (!items?.length) return;

  for (const item of items) {
    const fullPath = prefix ? `${prefix}/${item.name}` : item.name;

    if (item.metadata) {
      // FILE
      console.log(`🔍 Downloading file: ${fullPath}`);
      const { data: downloadData, error: dlError } = await supabaseCloud.storage
        .from(bucketName)
        .download(fullPath);

      if (dlError || !downloadData) {
        console.error(`❌ Failed to download ${fullPath}:`, dlError?.message);
        continue;
      }

      const buffer = Buffer.from(await downloadData.arrayBuffer());
      const { error: uploadError } = await supabaseLocal.storage
        .from(bucketName)
        .upload(fullPath, buffer, {
          contentType: "auto",
          upsert: true,
        });

      if (uploadError)
        console.error(`❌ Failed to upload ${fullPath}:`, uploadError.message);
      else console.log(`✅ Uploaded: ${fullPath}`);
    } else {
      // FOLDER
      console.log(`📁 Entering folder: ${fullPath}`);
      await migrateBucket(bucketName, fullPath);
    }
  }
}

(async () => {
  const bucketName = "siswa";
  console.log(`🚀 Starting migration for bucket: ${bucketName}`);
  await migrateBucket(bucketName);
  console.log("✅ Migration complete!");
})();
  