// supabase/functions/sendEmailQr/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization, x-client-info, apikey",
      },
    });
  }

  try {
    const { email, nama, kelas, jurusan, qr_url } = await req.json();

    const GMAIL_USER = Deno.env.get("GMAIL_USER")!;
    const GMAIL_PASS = Deno.env.get("GMAIL_PASS")!;

    // Setup client SMTP
    const client = new SMTPClient({
      connection: {
        hostname: "smtp.gmail.com",
        port: 465,
        tls: true,
        auth: {
          username: GMAIL_USER,
          password: GMAIL_PASS,
        },
      },
    });

    // Kirim email
    await client.send({
      from: GMAIL_USER,
      to: email,
      subject: "QR Code Siswa",
      content: `
Halo ${nama},

Data pendaftaran kamu berhasil disimpan:
- Kelas: ${kelas}
- Jurusan: ${jurusan}

Berikut QR Code kamu:
${qr_url}
      `,
    });

    await client.close();

    return new Response(JSON.stringify({ success: true }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (e) {
    console.error("Send email error:", e);
    return new Response(JSON.stringify({ error: String(e) }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      status: 500,
    });
  }
});
