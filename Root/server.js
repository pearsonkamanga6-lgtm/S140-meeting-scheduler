const http=require("http");
const fs=require("fs");
const path=require("path");
const {URL}=require("url");

const ROOT=__dirname;
const PORT=process.env.PORT||8080;
const MIME={".html":"text/html; charset=utf-8",".js":"application/javascript; charset=utf-8",".json":"application/json; charset=utf-8",".webmanifest":"application/manifest+json; charset=utf-8",".png":"image/png",".css":"text/css; charset=utf-8",".txt":"text/plain; charset=utf-8"};

function send(res,status,body,type="text/plain; charset=utf-8",headers={}){
 res.writeHead(status,{"Content-Type":type,"X-Content-Type-Options":"nosniff",...headers});res.end(body)
}
function safeFile(urlPath){
 let p=decodeURIComponent(urlPath.split("?")[0]);if(p==="/")p="/index.html";
 const f=path.normalize(path.join(ROOT,p));return f.startsWith(ROOT)?f:null
}
async function proxyJW(req,res,u){
 try{
  const raw=u.searchParams.get("url");if(!raw)return send(res,400,"Missing url");
  const target=new URL(raw);
  if(target.protocol!=="https:"||target.hostname!=="www.jw.org"||!target.pathname.startsWith("/nya/"))return send(res,403,"Only official Cinyanja pages on www.jw.org are allowed.");
  const r=await fetch(target,{redirect:"follow",headers:{
   "User-Agent":"Mozilla/5.0 (compatible; S140MeetingScheduler/4.0)",
   "Accept":"text/html,application/xhtml+xml",
   "Accept-Language":"ny,en;q=0.7"
  }});
  if(!r.ok)return send(res,r.status,`JW.org returned ${r.status}`);
  const text=await r.text();if(text.length>6_000_000)return send(res,413,"JW.org response was unexpectedly large.");
  send(res,200,text,"text/html; charset=utf-8",{"Cache-Control":"public, max-age=1800"})
 }catch(e){console.error(e);send(res,502,"Could not fetch the official JW.org page.")}
}
const server=http.createServer(async(req,res)=>{
 const u=new URL(req.url,`http://${req.headers.host||"localhost"}`);
 if(u.pathname==="/api/health")return send(res,200,JSON.stringify({ok:true,service:"s140-jw-importer"}),"application/json; charset=utf-8",{"Cache-Control":"no-store"});
 if(u.pathname==="/api/jw-proxy")return proxyJW(req,res,u);
 const file=safeFile(u.pathname);if(!file)return send(res,403,"Forbidden");
 fs.stat(file,(err,st)=>{
  if(err||!st.isFile())return send(res,404,"Not found");
  const ext=path.extname(file).toLowerCase();res.writeHead(200,{"Content-Type":MIME[ext]||"application/octet-stream","X-Content-Type-Options":"nosniff"});fs.createReadStream(file).pipe(res)
 })
});
server.listen(PORT,"0.0.0.0",()=>console.log(`S-140 Meeting Scheduler running on http://localhost:${PORT}`));
