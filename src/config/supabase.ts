import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SECRET_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error("Configure SUPABASE_URL e SUPABASE_SECRET_KEY no arquivo .env antes de iniciar a API.");
}

// Client usado somente no servidor. Nunca envie SUPABASE_SECRET_KEY ao frontend.
const supabase = createClient(supabaseUrl, supabaseKey);

export default supabase;
