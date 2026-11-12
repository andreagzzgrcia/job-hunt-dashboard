const KEYS=["choices","spont","edits"];
const H={"X-Robots-Tag":"noindex, nofollow","Cache-Control":"no-store","Referrer-Policy":"no-referrer"};
function merge(a,b){const o={};for(const k of KEYS){o[k]=Object.assign({},a[k]||{});for(const id in (b[k]||{})){const x=b[k][id];if(x&&typeof x.t==="number"&&(!o[k][id]||x.t>o[k][id].t))o[k][id]={t:x.t,v:x.v===undefined?null:x.v}}}return o}
const html=(b)=>new Response(b,{headers:{...H,"Content-Type":"text/html; charset=utf-8","Cache-Control":"no-store, no-cache, must-revalidate, max-age=0","Pragma":"no-cache","Expires":"0","X-LSGB-Version":"20261104-counters"}});
const PLACE='<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>Business</title></head><body style="font-family:-apple-system,sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:90vh;text-align:center;padding:20px"><h2>💼 Le tableau Business arrive bientôt</h2><p><a href="../" style="font-size:18px;color:#1f7a4d">← Accueil</a></p></body></html>';
export async function route(req,env){const u=new URL(req.url),base="/"+env.SECRET;
 if(u.pathname===base)return Response.redirect(u.origin+base+"/",301);
 if(!u.pathname.startsWith(base+"/"))return new Response("Not found",{status:404,headers:H});
 const p=u.pathname.slice(base.length);
 if(p==="/legal"||p==="/business")return Response.redirect(u.origin+base+p+"/",301);
 if(p==="/"||p==="/index.html")return html(HOME);
 if(p==="/legal/"||p==="/legal/index.html")return html(HTML);
 if(p==="/business/"||p==="/business/index.html"){const b=await env.KV.get("business_html");return html(b||PLACE)}
 if(/^\/((legal|business)\/)?manifest\.webmanifest$/.test(p))return new Response(JSON.stringify({name:"Recherche d'emploi – Andrea",short_name:"Candidatures",start_url:base+"/",scope:base+"/",display:"standalone",background_color:"#F4F2ED",theme_color:"#363D1F",icons:[{src:base+"/apple-touch-icon.png",sizes:"180x180",type:"image/png"}]}),{headers:{...H,"Content-Type":"application/manifest+json"}});
 if(/^\/((legal|business)\/)?apple-touch-icon\.png$/.test(p))return new Response(Uint8Array.from(atob(ICON),c=>c.charCodeAt(0)),{headers:{...H,"Content-Type":"image/png"}});
 if(p==="/api/state"||p==="/legal/api/state"||p==="/business/api/state"){const SK=p.startsWith("/business/")?"bd_state":"state";let cur=(await env.KV.get(SK,"json"))||{};
  if(req.method==="GET")return Response.json(merge(cur,{}),{headers:H});
  if(req.method==="POST"){let b;try{b=await req.json()}catch(e){return new Response("bad json",{status:400,headers:H})}
   const m=merge(cur,b);if(JSON.stringify(m)!==JSON.stringify(merge(cur,{})))await env.KV.put(SK,JSON.stringify(m));return Response.json(m,{headers:H})}
  return new Response("method",{status:405,headers:H})}
 return new Response("Not found",{status:404,headers:H})}
export default{fetch:route};
