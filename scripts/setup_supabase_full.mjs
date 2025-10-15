// ========================================================
// 🚀 Supabase Full Local Setup Script (Node.js)
// ========================================================

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import toml from "toml";
import dotenv from "dotenv";
import { execSync } from "child_process";

// ========================================================
// 📍 Setup dasar path
// ========================================================
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const envLocalPath = path.resolve(__dirname, "../.env.local");
const envPath = path.resolve(__dirname, "../.env");

// ========================================================
// 🌱 Muat variabel dari .env.local / .env
// ========================================================
if (fs.existsSync(envLocalPath)) {
  dotenv.config({ path: envLocalPath });
  console.log("✅ Loaded .env.local");
} else if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
  console.log("✅ Loaded .env");
} else {
  console.error("❌ Tidak menemukan .env.local maupun .env di root project.");
  process.exit(1);
}

const { SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY } = process.env;
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("❌ Pastikan variabel SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY ada di .env");
  process.exit(1);
}

// ========================================================
// 🧩 Coba baca supabase/config.toml (optional saja)
// ========================================================
const configPath = path.resolve(__dirname, "../supabase/config.toml");
let localServiceKey = SUPABASE_SERVICE_ROLE_KEY;

if (fs.existsSync(configPath)) {
  try {
    const config = toml.parse(fs.readFileSync(configPath, "utf-8"));
    if (config.api && config.api.service_role_key) {
      localServiceKey = config.api.service_role_key;
      console.log("📖 service_role_key ditemukan di config.toml");
    } else {
      console.log("ℹ️ Tidak ada service_role_key di config.toml, menggunakan .env");
    }
  } catch (err) {
    console.log("⚠️ Tidak bisa parse config.toml, dilewati:", err.message);
  }
} else {
  console.log("⚠️ config.toml tidak ditemukan, menggunakan .env");
}

// ========================================================
// ⚙️ Tulis ulang .env.local
// ========================================================
const newEnv = `
# =====================================================
# 🌐 Supabase Local Environment
# =====================================================
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
SUPABASE_SERVICE_ROLE_KEY=${localServiceKey}
`.trim();

fs.writeFileSync(path.resolve(__dirname, "../.env.local"), newEnv);
console.log("✅ File .env.local diperbarui");

// ========================================================
// 💾 Jalankan migrasi database lokal
// ========================================================
try {
  console.log("📦 Menjalankan migrasi database lokal...");
  execSync("supabase db reset", { stdio: "inherit" });
  console.log("✅ Database lokal berhasil di-reset dan dimigrasi");
} catch (err) {
  console.error("❌ Gagal menjalankan supabase db reset:", err.message);
}

// ========================================================
// 🧰 Migrasi Storage (Bucket)
// ========================================================
try {
  const migrateScript = path.resolve(__dirname, "./migrate_storage.mjs");
  if (fs.existsSync(migrateScript)) {
    console.log("📂 Menjalankan migrasi storage...");
    execSync(`node "${migrateScript}"`, { stdio: "inherit" });
    console.log("✅ Migrasi storage selesai");
  } else {
    console.log("⚠️ File migrate_storage.mjs tidak ditemukan, dilewati.");
  }
} catch (err) {
  console.error("❌ Migrasi storage gagal:", err.message);
}

// ========================================================
// 🎉 Selesai
// ========================================================
console.log(`
=========================================
🎉 Setup Supabase Lokal Selesai!
🗃️  URL       : ${SUPABASE_URL}
🔑  SERVICE KEY: ${localServiceKey.slice(0, 10)}... (disembunyikan)
=========================================
`);
