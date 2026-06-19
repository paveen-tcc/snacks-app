const fs = require('fs');
const dir = __dirname;
const ASSETS = fs.readFileSync(dir + '/assets.css', 'utf8');
const logo = fs.readFileSync(dir + '/logo.txt', 'utf8');
const shot = (n) => 'data:image/png;base64,' + fs.readFileSync(dir + '/shots/' + n + '.png').toString('base64');

const C = {
  brand: '#FF5A33', ink: '#1C1C1E', sec: '#5b5b62', ter: '#9A9AA0',
  bg: '#FAFAF8', line: '#E7E7E3', soft: '#F4F4F1', veg: '#18A957', info: '#2EAADC', warn: '#E9920B',
};

const phone = (img, cap) => `<figure class="phone"><img src="${shot(img)}"><figcaption>${cap}</figcaption></figure>`;

const html = `<!doctype html><html><head><meta charset="utf8"><style>
${ASSETS}
@page{size:A4;margin:0;}
*{margin:0;padding:0;box-sizing:border-box;-webkit-font-smoothing:antialiased;}
body{font-family:'Inter',sans-serif;color:${C.ink};font-size:10.5px;line-height:1.6;}
h1,h2,h3,.h{font-family:'Jakarta',sans-serif;}
.page{width:210mm;min-height:297mm;padding:22mm 20mm;position:relative;page-break-after:always;background:#fff;}
.page:last-child{page-break-after:auto;}
a{color:${C.brand};text-decoration:none;}
code{font-family:'SF Mono',ui-monospace,Menlo,monospace;background:${C.soft};padding:1px 5px;border-radius:5px;font-size:9.5px;color:#b0431f;}
h2{font-size:21px;font-weight:800;letter-spacing:-.4px;margin-bottom:4px;color:${C.ink};}
h2 .num{color:${C.brand};margin-right:10px;}
.lead{color:${C.sec};font-size:11px;margin-bottom:18px;}
h3{font-size:13px;font-weight:700;margin:20px 0 7px;}
p{margin-bottom:9px;color:#2c2c30;}
ul{margin:0 0 10px 0;padding-left:0;list-style:none;}
li{position:relative;padding-left:18px;margin-bottom:5px;color:#2c2c30;}
li:before{content:'';position:absolute;left:2px;top:7px;width:6px;height:6px;border-radius:2px;background:${C.brand};}
.kicker{font-size:10px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:${C.brand};}
.rule{height:3px;width:48px;background:${C.brand};border-radius:3px;margin:10px 0 16px;}
table{width:100%;border-collapse:collapse;margin:6px 0 14px;font-size:9.3px;}
th{text-align:left;background:${C.ink};color:#fff;padding:7px 9px;font-weight:600;font-family:'Jakarta';}
th:first-child{border-radius:8px 0 0 8px;}th:last-child{border-radius:0 8px 8px 0;}
td{padding:6px 9px;border-bottom:1px solid ${C.line};vertical-align:top;color:#34343a;}
tr:nth-child(even) td{background:#fbfbfa;}
.tag{display:inline-block;padding:1px 7px;border-radius:6px;font-size:8.5px;font-weight:700;}
.tag.g{background:#e6f6ee;color:${C.veg};}
.tag.b{background:#e6f5fb;color:#1684a8;}
.tag.o{background:#fdeee4;color:#c0531f;}
.tag.gy{background:#eee;color:#666;}
/* cover */
.cover{background:linear-gradient(160deg,#fff 0%, ${C.bg} 55%, #fdece6 100%);
  display:flex;flex-direction:column;justify-content:center;padding:0 22mm;}
.cover .logo{width:96px;height:96px;border-radius:26px;box-shadow:0 20px 55px rgba(255,90,51,.28);}
.cover h1{font-size:58px;font-weight:800;letter-spacing:-2px;margin:34px 0 0;line-height:1;}
.cover .tagline{font-size:19px;color:${C.sec};margin-top:18px;max-width:135mm;line-height:1.45;}
.cover .meta{margin-top:54px;display:flex;gap:38px;}
.cover .meta .k{font-size:9px;letter-spacing:1.5px;text-transform:uppercase;color:${C.ter};font-weight:700;}
.cover .meta .v{font-size:15px;font-weight:700;margin-top:4px;font-family:'Jakarta';}
.cover .strip{position:absolute;left:0;right:0;bottom:0;height:14px;background:${C.brand};}
.cover .foot{position:absolute;bottom:42px;left:22mm;font-size:10px;color:${C.ter};}
/* gallery */
.gallery{display:flex;flex-wrap:wrap;gap:14px 18px;justify-content:center;margin-top:8px;}
.phone{width:48mm;text-align:center;}
.phone img{width:100%;border-radius:16px;border:1px solid ${C.line};box-shadow:0 10px 30px rgba(28,28,30,.12);display:block;}
.phone figcaption{font-size:9px;color:${C.sec};margin-top:7px;font-weight:600;}
/* cards */
.cardrow{display:flex;gap:12px;margin:6px 0 14px;}
.box{flex:1;border:1px solid ${C.line};border-radius:14px;padding:13px 15px;background:#fff;}
.box .t{font-weight:700;font-family:'Jakarta';font-size:12px;margin-bottom:5px;}
.box .t .dot{display:inline-block;width:8px;height:8px;border-radius:2px;margin-right:7px;}
.box p{font-size:9.5px;color:${C.sec};margin:0;}
/* flow diagram */
.flow{display:flex;align-items:stretch;gap:0;margin:10px 0 16px;}
.node{flex:1;background:${C.soft};border:1px solid ${C.line};border-radius:12px;padding:11px 10px;text-align:center;position:relative;}
.node .n{font-size:9px;font-weight:800;color:${C.brand};font-family:'Jakarta';}
.node .d{font-size:9px;color:${C.sec};margin-top:3px;line-height:1.35;}
.arrow{display:flex;align-items:center;justify-content:center;width:24px;color:${C.ter};font-size:16px;font-weight:700;flex:0 0 24px;}
/* arch */
.arch{border:1px solid ${C.line};border-radius:16px;overflow:hidden;margin:8px 0 14px;}
.layer{padding:12px 16px;border-bottom:1px solid ${C.line};}
.layer:last-child{border-bottom:none;}
.layer .lt{font-weight:800;font-family:'Jakarta';font-size:11px;display:flex;align-items:center;gap:9px;}
.layer .lt .chip{font-size:8px;background:${C.ink};color:#fff;padding:2px 8px;border-radius:6px;font-weight:700;letter-spacing:.5px;}
.layer .row{display:flex;gap:8px;margin-top:9px;flex-wrap:wrap;}
.mod{font-size:9px;background:#fff;border:1px solid ${C.line};border-radius:8px;padding:6px 10px;color:#3a3a40;}
.mod b{color:${C.ink};}
.conn{text-align:center;color:${C.ter};font-size:10px;padding:5px;font-weight:700;letter-spacing:1px;}
.callout{background:#fff7f3;border:1px solid #ffd9c9;border-left:4px solid ${C.brand};border-radius:10px;padding:11px 15px;margin:12px 0;font-size:10px;color:#5a3322;}
.callout b{color:${C.brand};}
.foot-num{position:absolute;bottom:12mm;right:20mm;font-size:9px;color:${C.ter};font-weight:600;}
.foot-brand{position:absolute;bottom:12mm;left:20mm;font-size:9px;color:${C.ter};}
.two{display:flex;gap:22px;}
.two>div{flex:1;}
.stat{display:flex;gap:14px;margin:4px 0 16px;}
.stat .s{flex:1;border:1px solid ${C.line};border-radius:14px;padding:14px;text-align:center;}
.stat .s .big{font-family:'Jakarta';font-size:26px;font-weight:800;color:${C.brand};}
.stat .s .lbl{font-size:9px;color:${C.sec};margin-top:2px;}
</style></head><body>

<!-- COVER -->
<div class="page cover">
  <img class="logo" src="${logo}">
  <h1>TCC Pantry</h1>
  <div class="tagline">An offline-first office snacks &amp; drinks ordering app &mdash; Flutter on every screen, Cloudflare Workers at the edge.</div>
  <div class="meta">
    <div><div class="k">Client</div><div class="v">Flutter &bull; Dart 3.11</div></div>
    <div><div class="k">Backend</div><div class="v">Hono + Workers</div></div>
    <div><div class="k">Database</div><div class="v">Neon Postgres</div></div>
    <div><div class="k">Version</div><div class="v">1.5.2</div></div>
  </div>
  <div class="foot">Project Documentation &bull; Generated 19 June 2026</div>
  <div class="strip"></div>
</div>

<!-- OVERVIEW -->
<div class="page">
  <div class="kicker">Overview</div>
  <h2><span class="num">01</span>What is TCC Pantry?</h2>
  <div class="rule"></div>
  <p><b>TCC Pantry</b> is a cross-platform application that runs the daily office snack round. Employees order snacks, vote on the drink of the day, and review their history; admins manage the catalogue, user roles, holidays, and get a live order summary they can share straight to WhatsApp. It ships from a single Flutter codebase to iOS, Android, web, and desktop, backed by a serverless API deployed to Cloudflare's edge.</p>

  <div class="stat">
    <div class="s"><div class="big">4</div><div class="lbl">Target platforms</div></div>
    <div class="s"><div class="big">5</div><div class="lbl">API route groups</div></div>
    <div class="s"><div class="big">100%</div><div class="lbl">Offline-capable orders</div></div>
    <div class="s"><div class="big">SSO</div><div class="lbl">Microsoft Entra ID</div></div>
  </div>

  <h3>What it does</h3>
  <div class="cardrow">
    <div class="box"><div class="t"><span class="dot" style="background:${C.brand}"></span>Order snacks</div><p>Browse a live catalogue in a tactile 3-column grid with search, veg filter, and categories. Selections are confirmed against a daily cutoff time.</p></div>
    <div class="box"><div class="t"><span class="dot" style="background:${C.info}"></span>Vote on drinks</div><p>A dedicated drinks tab for the day's beverage vote, including a per-drink sugar-free preference that is snapshotted into history.</p></div>
  </div>
  <div class="cardrow">
    <div class="box"><div class="t"><span class="dot" style="background:${C.veg}"></span>Review &amp; re-order</div><p>The last seven days of orders, grouped by date, with one-tap re-ordering that resolves items by id and falls back to name.</p></div>
    <div class="box"><div class="t"><span class="dot" style="background:${C.warn}"></span>Admin &amp; summary</div><p>Manage snacks, users, holidays and shutdown days; see a live count of who has ordered and export the summary to WhatsApp.</p></div>
  </div>

  <div class="callout"><b>Design principle &mdash; offline first.</b> Placing an order or voting never blocks on the network. Mutations are written to a local SQLite queue and optimistically reflected in the UI; a sync engine replays them when connectivity returns and drops anything the server rejects with a 4xx.</div>

  <div class="foot-brand">TCC Pantry &bull; Project Documentation</div>
  <div class="foot-num">01</div>
</div>

<!-- SCREENS -->
<div class="page">
  <div class="kicker">Product tour</div>
  <h2><span class="num">02</span>The app, screen by screen</h2>
  <div class="rule"></div>
  <p>High-fidelity renders of the core flows, built from the app's own design tokens &mdash; the coral <code>#FF5A33</code> brand accent, Plus&nbsp;Jakarta&nbsp;Sans / Inter type pairing, and the frosted-glass navigation that defines the Notion-inspired theme.</p>
  <div class="gallery">
    ${phone('onboarding','Onboarding &mdash; Microsoft sign-in')}
    ${phone('food','Food tab &mdash; snack grid &amp; cart')}
    ${phone('drinks','Drinks tab &mdash; daily vote')}
    ${phone('cart','Cart sheet &mdash; confirm order')}
    ${phone('orders','History &mdash; last 7 days')}
    ${phone('admin','Admin &mdash; live summary')}
  </div>
  <div class="foot-brand">TCC Pantry &bull; Project Documentation</div>
  <div class="foot-num">02</div>
</div>

<!-- ARCHITECTURE -->
<div class="page">
  <div class="kicker">Architecture</div>
  <h2><span class="num">03</span>How it fits together</h2>
  <div class="rule"></div>
  <p>A layered Flutter client wired through <code>get_it</code> talks to a single Hono app on Cloudflare Workers over HTTPS. The client owns a local SQLite database (Drift) for offline reads and a sync queue for offline writes; the server owns a Neon Postgres database accessed through Drizzle.</p>

  <div class="arch">
    <div class="layer">
      <div class="lt"><span class="chip">FLUTTER CLIENT</span> Presentation &middot; Data &middot; Core</div>
      <div class="row">
        <div class="mod"><b>presentation/</b> &mdash; flutter_bloc screens (home, orders, admin, onboarding)</div>
        <div class="mod"><b>data/repositories/</b> &mdash; the only layer screens touch</div>
        <div class="mod"><b>data/local/</b> &mdash; Drift SQLite (snacks, orders, settings, queue)</div>
        <div class="mod"><b>data/sync/</b> &mdash; SyncEngine replays the queue</div>
        <div class="mod"><b>core/</b> &mdash; DI, MSAL auth, Dio ApiClient, design system</div>
      </div>
    </div>
  </div>
  <div class="conn">&#8645;&nbsp;&nbsp; HTTPS &bull; Authorization: Bearer &lt;JWT&gt; &nbsp;&nbsp;&#8645;</div>
  <div class="arch">
    <div class="layer">
      <div class="lt"><span class="chip">CLOUDFLARE WORKER</span> Hono app</div>
      <div class="row">
        <div class="mod"><b>middleware</b> &mdash; injects Drizzle db + jwtSecret per request; auth &amp; admin guards</div>
        <div class="mod"><b>routes/</b> &mdash; /api/{auth, snacks, orders, admin}</div>
        <div class="mod"><b>utils/</b> &mdash; JWT sign/verify, Microsoft JWKS verification</div>
      </div>
    </div>
    <div class="layer">
      <div class="lt"><span class="chip">DATA</span> Neon Serverless Postgres &middot; Drizzle ORM</div>
      <div class="row">
        <div class="mod">users</div><div class="mod">snacks</div><div class="mod">orders</div>
        <div class="mod">holidays</div><div class="mod">shutdownDays</div><div class="mod">appSettings</div>
      </div>
    </div>
  </div>

  <h3>Authentication flow</h3>
  <div class="flow">
    <div class="node"><div class="n">1 &middot; MSAL</div><div class="d">App acquires an Azure token via Microsoft Entra ID</div></div>
    <div class="arrow">&rarr;</div>
    <div class="node"><div class="n">2 &middot; Verify</div><div class="d">Server checks it against Entra JWKS</div></div>
    <div class="arrow">&rarr;</div>
    <div class="node"><div class="n">3 &middot; Mint JWT</div><div class="d">Signs an app JWT with isAdmin claim</div></div>
    <div class="arrow">&rarr;</div>
    <div class="node"><div class="n">4 &middot; Store</div><div class="d">Saved to prefs; sent as Bearer on every call</div></div>
  </div>
  <p style="font-size:9.5px;color:${C.sec}">The router redirect gates the whole app behind the stored token &mdash; no token routes to onboarding, a valid token to home. A 401 from the API triggers a silent MSAL re-auth to refresh the JWT.</p>

  <div class="foot-brand">TCC Pantry &bull; Project Documentation</div>
  <div class="foot-num">03</div>
</div>

<!-- DATA + SYNC -->
<div class="page">
  <div class="kicker">Data model</div>
  <h2><span class="num">04</span>Data &amp; the offline engine</h2>
  <div class="rule"></div>
  <div class="two">
    <div>
      <h3>Server &mdash; Postgres (Drizzle)</h3>
      <table>
        <tr><th>Table</th><th>Purpose</th></tr>
        <tr><td><code>users</code></td><td>Identity, Microsoft id, isAdmin</td></tr>
        <tr><td><code>snacks</code></td><td>Catalogue: veg, default, active, serving</td></tr>
        <tr><td><code>orders</code></td><td>Per-user, per-date items + snapshots</td></tr>
        <tr><td><code>holidays</code></td><td>Manual / auto no-order days</td></tr>
        <tr><td><code>shutdownDays</code></td><td>Kitchen-closed days</td></tr>
        <tr><td><code>appSettings</code></td><td>Cutoff time, advance-order window</td></tr>
      </table>
    </div>
    <div>
      <h3>Client &mdash; SQLite (Drift)</h3>
      <table>
        <tr><th>Table</th><th>Purpose</th></tr>
        <tr><td><code>LocalSnacks</code></td><td>Cached catalogue for offline browse</td></tr>
        <tr><td><code>LocalOrders</code></td><td>Optimistic orders w/ name snapshot</td></tr>
        <tr><td><code>LocalSettings</code></td><td>Cutoff &amp; advance-order config</td></tr>
        <tr><td><code>SyncQueue</code></td><td>Pending mutations to replay</td></tr>
      </table>
    </div>
  </div>

  <h3>The offline-first write path</h3>
  <div class="flow">
    <div class="node"><div class="n">Tap order</div><div class="d">Write to LocalOrders immediately</div></div>
    <div class="arrow">&rarr;</div>
    <div class="node"><div class="n">Online?</div><div class="d">POST /api/orders, swap in server ids</div></div>
    <div class="arrow">&rarr;</div>
    <div class="node"><div class="n">Offline?</div><div class="d">Enqueue into SyncQueue, return success</div></div>
    <div class="arrow">&rarr;</div>
    <div class="node"><div class="n">Reconnect</div><div class="d">SyncEngine drains queue; drops 4xx</div></div>
  </div>
  <div class="callout"><b>Why snapshots?</b> Each order stores the snack's name and emoji at the time it was placed (<code>snackNameSnapshot</code>). History stays correct even if an admin later renames or deletes the snack, and re-order can still resolve items by name.</div>

  <h3>Smart behaviours</h3>
  <ul>
    <li><b>Advance-order mode</b> &mdash; admins can shift ordering to the next day within a configurable time window; the effective order date becomes tomorrow.</li>
    <li><b>Share counts</b> &mdash; a snack can &ldquo;serve 2&rdquo;, and the admin summary adjusts its counts accordingly.</li>
    <li><b>Holiday / shutdown gating</b> &mdash; on load the app checks <code>/api/orders/status</code>; on a holiday the ordering UI is replaced with a friendly closed state.</li>
  </ul>

  <div class="foot-brand">TCC Pantry &bull; Project Documentation</div>
  <div class="foot-num">04</div>
</div>

<!-- API + STACK -->
<div class="page">
  <div class="kicker">Reference</div>
  <h2><span class="num">05</span>API &amp; technology</h2>
  <div class="rule"></div>
  <h3>HTTP API</h3>
  <table>
    <tr><th>Method &amp; path</th><th>Auth</th><th>Purpose</th></tr>
    <tr><td><code>POST /api/auth/microsoft</code></td><td><span class="tag gy">public</span></td><td>Verify MSAL token, mint app JWT</td></tr>
    <tr><td><code>GET /api/auth/session</code></td><td><span class="tag b">jwt</span></td><td>Refresh session &amp; token</td></tr>
    <tr><td><code>GET /api/snacks</code></td><td><span class="tag gy">public</span></td><td>Active snack catalogue</td></tr>
    <tr><td><code>GET /api/snacks/settings</code></td><td><span class="tag gy">public</span></td><td>Cutoff time &amp; advance-order config</td></tr>
    <tr><td><code>GET /api/orders/status</code></td><td><span class="tag b">jwt</span></td><td>Is today a holiday / shutdown?</td></tr>
    <tr><td><code>GET /api/orders/today</code></td><td><span class="tag b">jwt</span></td><td>The user's order for today</td></tr>
    <tr><td><code>POST /api/orders</code></td><td><span class="tag b">jwt</span></td><td>Place or update today's order</td></tr>
    <tr><td><code>DELETE /api/orders</code></td><td><span class="tag b">jwt</span></td><td>Clear today's order</td></tr>
    <tr><td><code>GET /api/orders/history</code></td><td><span class="tag b">jwt</span></td><td>Last 7 days of orders</td></tr>
    <tr><td><code>GET/POST/PUT/DELETE /api/admin/snacks</code></td><td><span class="tag o">admin</span></td><td>Catalogue CRUD + bulk import</td></tr>
    <tr><td><code>GET /api/admin/summary</code></td><td><span class="tag o">admin</span></td><td>Today's counts &amp; who has ordered</td></tr>
    <tr><td><code>GET/POST /api/admin/users</code></td><td><span class="tag o">admin</span></td><td>List users, toggle admin flag</td></tr>
    <tr><td><code>GET/POST/DELETE /api/admin/holidays</code></td><td><span class="tag o">admin</span></td><td>Manage holidays &amp; shutdown days</td></tr>
  </table>

  <div class="two" style="margin-top:14px;">
    <div>
      <h3>Client stack</h3>
      <table>
        <tr><th>Package</th><th>Role</th></tr>
        <tr><td>flutter_bloc</td><td>State management</td></tr>
        <tr><td>drift + sqlite3</td><td>Local database</td></tr>
        <tr><td>dio</td><td>HTTP client</td></tr>
        <tr><td>go_router</td><td>Routing &amp; auth gate</td></tr>
        <tr><td>msal_auth</td><td>Microsoft Entra sign-in</td></tr>
        <tr><td>get_it</td><td>Dependency injection</td></tr>
        <tr><td>connectivity_plus</td><td>Reconnect detection</td></tr>
        <tr><td>freezed</td><td>Immutable models</td></tr>
      </table>
    </div>
    <div>
      <h3>Server stack</h3>
      <table>
        <tr><th>Package</th><th>Role</th></tr>
        <tr><td>hono</td><td>Web framework</td></tr>
        <tr><td>drizzle-orm</td><td>Type-safe ORM</td></tr>
        <tr><td>@neondatabase/serverless</td><td>Postgres driver</td></tr>
        <tr><td>jose</td><td>JWT sign / verify</td></tr>
        <tr><td>wrangler</td><td>Workers tooling</td></tr>
        <tr><td>Bun</td><td>Runtime &amp; test runner</td></tr>
      </table>
      <div class="callout" style="margin-top:8px;font-size:9px;"><b>Secrets</b> &mdash; <code>DATABASE_URL</code>, <code>JWT_SECRET</code>, <code>AZURE_TENANT_ID</code>, <code>AZURE_CLIENT_ID</code> via wrangler.</div>
    </div>
  </div>

  <div class="foot-brand">TCC Pantry &bull; Project Documentation</div>
  <div class="foot-num">05</div>
</div>

</body></html>`;

fs.writeFileSync(dir + '/doc.html', html);
console.log('wrote doc.html', html.length, 'chars');
