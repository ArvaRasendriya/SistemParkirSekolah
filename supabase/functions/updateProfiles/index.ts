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

    // Fetch all profiles records
    const { data: profilesList, error: fetchError } = await supabaseClient
      .from('profiles')
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

    if (!profilesList) {
      return new Response(JSON.stringify({ message: 'No profiles records found' }), {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        status: 200,
      });
    }

    const updates = [];
    const deletions = [];

    for (const profile of profilesList) {
      const kelas = profile.kelas;
      if (!kelas) continue; // Skip if no kelas

      let newKelas = kelas;

      if (kelas.startsWith('X ')) {
        newKelas = kelas.replace('X ', 'XI ');
      } else if (kelas.startsWith('XI ')) {
        newKelas = kelas.replace('XI ', 'XII ');
      } else if (kelas.startsWith('XII ')) {
        // Mark for deletion if not admin
        if (profile.role !== 'admin') {
          deletions.push(profile);
        }
        continue;
      }

      if (newKelas !== kelas) {
        updates.push({ id: profile.id, kelas: newKelas });
      }
    }

    // Perform updates
    for (const update of updates) {
      const { error: updateError } = await supabaseClient
        .from('profiles')
        .update({ kelas: update.kelas })
        .eq('id', update.id);

      if (updateError) {
        console.error(`Update error for ${update.id}:`, updateError);
      }
    }

    // Perform deletions
    for (const profile of deletions) {
      // Delete from auth first
      const { error: authError } = await supabaseClient.auth.admin.deleteUser(profile.id);

      if (authError) {
        console.error(`Auth delete error for ${profile.id}:`, authError);
        continue;
      }

      // Then delete from profiles
      const { error: deleteError } = await supabaseClient
        .from('profiles')
        .delete()
        .eq('id', profile.id);

      if (deleteError) {
        console.error(`Delete error for ${profile.id}:`, deleteError);
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
    console.error("Update profiles error:", error);
    return new Response(JSON.stringify({ error: String(error) }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      status: 500,
    });
  }
});
