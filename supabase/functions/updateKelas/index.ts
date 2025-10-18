import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

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
    // Create a Supabase client with the service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Fetch all siswa records
    const { data: siswaList, error: fetchError } = await supabaseClient
      .from('siswa')
      .select('*');

    if (fetchError) {
      return new Response(JSON.stringify({ error: fetchError.message }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        status: 500,
      });
    }

    if (!siswaList) {
      return new Response(JSON.stringify({ message: 'No siswa records found' }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        status: 200,
      });
    }

    const updates = [];
    const deletions = [];

    for (const siswa of siswaList) {
      const kelas = siswa.kelas;
      let newKelas = kelas;

      if (kelas.startsWith('X ')) {
        newKelas = kelas.replace('X ', 'XI ');
      } else if (kelas.startsWith('XI ')) {
        newKelas = kelas.replace('XI ', 'XII ');
      } else if (kelas.startsWith('XII ')) {
        // Mark for deletion
        deletions.push(siswa);
        continue;
      }

      if (newKelas !== kelas) {
        updates.push({ id: siswa.id, kelas: newKelas });
      }
    }

    // Perform updates
    for (const update of updates) {
      const { error: updateError } = await supabaseClient
        .from('siswa')
        .update({ kelas: update.kelas })
        .eq('id', update.id);

      if (updateError) {
        console.error(`Update error for ${update.id}:`, updateError);
      }
    }

    // Perform deletions
    for (const siswa of deletions) {
      // Delete from siswa table
      const { error: deleteError } = await supabaseClient
        .from('siswa')
        .delete()
        .eq('id', siswa.id);

      if (deleteError) {
        console.error(`Delete error for ${siswa.id}:`, deleteError);
        continue;
      }

      // Delete images from storage
      if (siswa.sim_url) {
        const simPath = siswa.sim_url.replace('https://rfpsfzbmhhxksisxciwx.supabase.co/storage/v1/object/public/siswa/', '');
        const { error: simDeleteError } = await supabaseClient.storage
          .from('siswa')
          .remove([simPath]);
        if (simDeleteError) {
          console.error(`Sim delete error for ${siswa.id}:`, simDeleteError);
        }
      }

      if (siswa.qr_url) {
        const qrPath = siswa.qr_url.replace('https://rfpsfzbmhhxksisxciwx.supabase.co/storage/v1/object/public/siswa/', '');
        const { error: qrDeleteError } = await supabaseClient.storage
          .from('siswa')
          .remove([qrPath]);
        if (qrDeleteError) {
          console.error(`QR delete error for ${siswa.id}:`, qrDeleteError);
        }
      }
    }

    return new Response(JSON.stringify({
      success: true,
      updated: updates.length,
      deleted: deletions.length
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      status: 200,
    });
  } catch (error) {
    console.error("Update kelas error:", error);
    return new Response(JSON.stringify({ error: String(error) }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      status: 500,
    });
  }
});
