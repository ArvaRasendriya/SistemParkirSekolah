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

    // Fetch QR code image
    const qrResponse = await fetch(qr_url);
    const qrBlob = await qrResponse.blob();
    const qrArrayBuffer = await qrBlob.arrayBuffer();
    const qrUint8Array = new Uint8Array(qrArrayBuffer);
    const qrBase64 = btoa(String.fromCharCode(...qrUint8Array));

    // Kirim email
    await client.send({
      from: GMAIL_USER,
      to: email,
      subject: "QR Code Siswa",
      html: `
 <html>
  <body style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px; color: #333;">
    <div style="max-width: 600px; margin: auto; background: #ffffff; border-radius: 10px; padding: 20px; box-shadow: 0 2px 6px rgba(0,0,0,0.1);">
      <h2 style="color: #2C5364; text-align: center;">✅ Pendaftaran Berhasil</h2>
      <p>Halo <strong>${nama}</strong>,</p>
      <p>Selamat! Data pendaftaran kamu sudah <b>berhasil disetujui</b>. Berikut detail informasi kamu:</p>

      <table style="width:100%; border-collapse: collapse; margin: 20px 0;">
        <tr>
          <td style="padding: 8px; border: 1px solid #ddd;"><b>Nama</b></td>
          <td style="padding: 8px; border: 1px solid #ddd;">${nama}</td>
        </tr>
        <tr>
          <td style="padding: 8px; border: 1px solid #ddd;"><b>Kelas</b></td>
          <td style="padding: 8px; border: 1px solid #ddd;">${kelas}</td>
        </tr>
        <tr>
          <td style="padding: 8px; border: 1px solid #ddd;"><b>Jurusan</b></td>
          <td style="padding: 8px; border: 1px solid #ddd;">${jurusan}</td>
        </tr>
      </table>

      <p style="margin-top:20px;">Berikut QR Code kamu (juga terlampir dalam email ini):</p>
      <div style="text-align:center; margin:20px 0;">
        <img src="cid:qr_image" alt="QR Code" style="max-width: 250px; border:1px solid #ddd; padding:10px; border-radius: 8px;">
      </div>

      <p style="font-size:14px; color:#555;">
        Simpan QR Code ini baik-baik. QR Code akan digunakan sebagai identitas dan validasi data kamu.
      </p>

      <hr style="margin: 30px 0;">

      <p style="font-size:12px; color:#888; text-align:center;">
        Email ini dikirim otomatis, mohon tidak membalas.  
        Jika ada pertanyaan, silakan hubungi admin melalui kontak resmi sekolah.
      </p>
    </div>
  </body>
  </html>
      `,
      attachments: [
        {
          filename: "qr_code.png",
          content: qrBase64,
          encoding: "base64",
          contentType: "image/png",
          contentID: "qr_image",
        },
      ],
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
