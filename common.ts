import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { keccak256, stringToBytes, verifyMessage, getAddress } from 'https://esm.sh/viem@2.21.54';

export const cors = { 'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS' };
export const db = createClient(Deno.env.get('SUPABASE_URL')!, (Deno.env.get('SUPABASE_SECRET_KEY') || Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'))!);
export const json=(data:any,status=200)=>new Response(JSON.stringify(data),{status,headers:{...cors,'Content-Type':'application/json'}});
export const body=async(req:Request)=>await req.json().catch(()=>({}));
export const norm=(a:string)=>getAddress(a).toLowerCase();
export const tokenHash=(t:string)=>keccak256(stringToBytes(t));
export const randomHex=(n=32)=>{const b=new Uint8Array(n);crypto.getRandomValues(b);return [...b].map(x=>x.toString(16).padStart(2,'0')).join('')};
export const challengeMessage=(wallet:string,nonce:string)=>`NAZU Testnet wallet verification\n\nWallet: ${wallet}\nNonce: ${nonce}\nPurpose: Prove wallet ownership. No transaction will be sent.\nExpires: 5 minutes`;
export { verifyMessage };
