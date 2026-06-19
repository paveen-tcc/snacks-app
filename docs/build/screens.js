// Generates high-fidelity HTML mockups of the Snacks App screens,
// faithful to the real design tokens (app/lib/core/design/app_colors.dart).
const fs = require('fs');
const ASSETS = fs.readFileSync(__dirname + '/assets.css', 'utf8');

const C = {
  brand: '#FF5A33', brandPressed: '#E64A28', onBrand: '#fff',
  bg: '#FAFAF8', surface: '#FFFFFF', surfaceMuted: '#F2F2EF',
  textPrimary: '#1C1C1E', textSecondary: '#6B6B70', textTertiary: '#9A9AA0',
  border: '#E7E7E3', divider: '#EDEDEA',
  veg: '#18A957', nonVeg: '#E5484D', warning: '#E9920B', info: '#2EAADC',
};

const base = (body, opts = {}) => `<!doctype html><html><head><meta charset="utf8"><style>
${ASSETS}
*{margin:0;padding:0;box-sizing:border-box;-webkit-font-smoothing:antialiased;}
html,body{width:390px;height:844px;font-family:'Inter',sans-serif;color:${C.textPrimary};
  background:${opts.bg || C.bg};overflow:hidden;}
.h{font-family:'Jakarta',sans-serif;}
.statusbar{height:44px;display:flex;align-items:center;justify-content:space-between;
  padding:0 22px;font-size:13px;font-weight:600;color:${C.textPrimary};}
.statusbar .dots{display:flex;gap:5px;align-items:center;font-size:12px;}
.appbar{padding:6px 20px 14px;display:flex;align-items:center;justify-content:space-between;}
.appbar .title{font-size:26px;font-weight:700;letter-spacing:-.5px;}
.appbar .sub{font-size:13px;color:${C.textSecondary};margin-top:2px;}
.avatar{width:38px;height:38px;border-radius:50%;background:${C.surfaceMuted};
  display:flex;align-items:center;justify-content:center;font-weight:700;color:${C.brand};
  border:1px solid ${C.border};font-size:15px;}
.pill{display:inline-flex;align-items:center;gap:6px;padding:7px 13px;border-radius:999px;
  font-size:13px;font-weight:600;}
.bottomnav{position:absolute;left:16px;right:16px;bottom:18px;height:64px;border-radius:26px;
  background:rgba(255,255,255,.72);backdrop-filter:blur(24px);-webkit-backdrop-filter:blur(24px);
  border:1px solid rgba(255,255,255,.6);box-shadow:0 12px 40px rgba(28,28,30,.14);
  display:flex;align-items:center;justify-content:space-around;padding:0 8px;}
.navitem{display:flex;flex-direction:column;align-items:center;gap:3px;font-size:11px;
  font-weight:600;color:${C.textTertiary};}
.navitem.on{color:${C.brand};}
.navitem .ico{font-size:21px;}
.cartbar{position:absolute;left:16px;right:16px;bottom:92px;height:54px;border-radius:18px;
  background:${C.brand};box-shadow:0 10px 30px rgba(255,90,51,.36);
  display:flex;align-items:center;justify-content:space-between;padding:0 8px 0 18px;color:#fff;}
.cartbar.placed{background:${C.veg};box-shadow:0 10px 30px rgba(24,169,87,.32);}
.cartbar .lbl{font-weight:700;font-size:15px;}
.cartbar .go{background:rgba(255,255,255,.22);padding:11px 18px;border-radius:14px;
  font-weight:700;font-size:14px;}
.searchrow{display:flex;gap:10px;padding:0 20px 14px;}
.search{flex:1;height:44px;border-radius:14px;background:${C.surfaceMuted};border:1px solid ${C.border};
  display:flex;align-items:center;gap:9px;padding:0 14px;color:${C.textTertiary};font-size:14px;}
.vegtoggle{height:44px;padding:0 14px;border-radius:14px;background:${C.surface};border:1px solid ${C.border};
  display:flex;align-items:center;gap:8px;font-size:13px;font-weight:600;}
.vegdot{width:14px;height:14px;border-radius:4px;border:2px solid ${C.veg};position:relative;}
.vegdot:after{content:'';position:absolute;inset:2px;border-radius:50%;background:${C.veg};}
.chips{display:flex;gap:9px;padding:0 20px 16px;overflow:hidden;}
.chip{padding:8px 15px;border-radius:999px;background:${C.surface};border:1px solid ${C.border};
  font-size:13px;font-weight:600;color:${C.textSecondary};white-space:nowrap;}
.chip.on{background:${C.textPrimary};color:#fff;border-color:${C.textPrimary};}
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;padding:0 20px;}
.card{background:${C.surface};border:1px solid ${C.border};border-radius:20px;padding:14px 10px 12px;
  display:flex;flex-direction:column;align-items:center;text-align:center;position:relative;
  box-shadow:0 1px 3px rgba(28,28,30,.04);}
.card.sel{border-color:${C.brand};box-shadow:0 0 0 2px ${C.brand}, 0 8px 20px rgba(255,90,51,.18);}
.card .emoji{font-size:34px;line-height:1;margin:6px 0 9px;}
.card .nm{font-size:13px;font-weight:700;line-height:1.2;}
.card .ss{font-size:11px;color:${C.textTertiary};margin-top:3px;}
.card .vbadge{position:absolute;top:9px;left:9px;width:15px;height:15px;border-radius:4px;
  border:2px solid ${C.veg};}
.card .vbadge:after{content:'';position:absolute;inset:2px;border-radius:50%;background:${C.veg};}
.card .vbadge.nv{border-color:${C.nonVeg};}
.card .vbadge.nv:after{background:${C.nonVeg};}
.card .check{position:absolute;top:8px;right:8px;width:20px;height:20px;border-radius:50%;
  background:${C.brand};color:#fff;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;}
.section{padding:18px 20px 8px;font-size:13px;font-weight:700;color:${C.textSecondary};text-transform:uppercase;letter-spacing:.4px;}
</style></head><body>${body}</body></html>`;

const statusbar = `<div class="statusbar"><span>9:41</span><span class="dots">● ▮▮▮ &#x1F50B;</span></div>`;
const bottomnav = (active) => `<div class="bottomnav">
  ${[['Food','&#x1F36A;'],['Drinks','&#x2615;'],['Orders','&#x1F4CB;'],['Summary','&#x1F4CA;']]
    .map(([l,i],idx)=>`<div class="navitem ${idx===active?'on':''}"><span class="ico">${i}</span>${l}</div>`).join('')}
</div>`;

const foodCard = (emoji, nm, ss, veg = true, sel = false, isImg = false) => `
<div class="card ${sel?'sel':''}">
  <div class="vbadge ${veg?'':'nv'}"></div>
  ${sel?'<div class="check">&#10003;</div>':''}
  <div class="emoji">${emoji}</div>
  <div class="nm">${nm}</div>
  <div class="ss">${ss}</div>
</div>`;

// ---------------- Screens ----------------
const logo = fs.readFileSync(__dirname + '/logo.txt', 'utf8');

const screens = {};

screens.onboarding = base(`
${statusbar}
<div style="height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:0 36px;text-align:center;margin-top:-60px;">
  <img src="${logo}" style="width:104px;height:104px;border-radius:28px;box-shadow:0 18px 50px rgba(255,90,51,.28);">
  <div class="h" style="font-size:34px;font-weight:800;margin-top:30px;letter-spacing:-1px;">TCC Pantry</div>
  <div style="font-size:16px;color:${C.textSecondary};margin-top:12px;line-height:1.5;">Order office snacks, vote on drinks,<br>and never miss the daily round.</div>
  <div style="margin-top:48px;width:100%;height:54px;border-radius:16px;background:${C.textPrimary};color:#fff;
    display:flex;align-items:center;justify-content:center;gap:11px;font-weight:700;font-size:15px;box-shadow:0 10px 30px rgba(28,28,30,.2);">
    <span style="font-size:18px;">&#x1F5D7;</span> Sign in with Microsoft</div>
  <div style="font-size:12px;color:${C.textTertiary};margin-top:22px;">Secured by Microsoft Entra ID &bull; v1.5.2</div>
</div>`, { bg: '#fff' });

screens.food = base(`
${statusbar}
<div class="appbar"><div><div class="title h">Today&#39;s snacks</div><div class="sub">Order closes at 12:00 &bull; Fri, 19 Jun</div></div><div class="avatar">CU</div></div>
<div class="searchrow"><div class="search">&#x1F50D; Search snacks</div><div class="vegtoggle"><span class="vegdot"></span>Veg</div></div>
<div class="chips"><div class="chip on">All</div><div class="chip">Savoury</div><div class="chip">Sweet</div><div class="chip">Fruit</div><div class="chip">Healthy</div></div>
<div class="grid">
  ${foodCard('&#x1F95F;','Samosa','2 pieces',true,true)}
  ${foodCard('&#x1F36A;','Cookies','1 pack',true)}
  ${foodCard('&#x1F34C;','Banana','1 piece',true)}
  ${foodCard('&#x1F32F;','Veg Roll','1 roll',true)}
  ${foodCard('&#x1F357;','Chicken Puff','1 piece',false,true)}
  ${foodCard('&#x1F95C;','Peanuts','1 bowl',true)}
  ${foodCard('&#x1F9C0;','Cheese Sand.','2 halves',true)}
  ${foodCard('&#x1F353;','Fruit Cup','1 cup',true)}
  ${foodCard('&#x1F36B;','Brownie','1 piece',true)}
</div>
<div class="cartbar"><span class="lbl">2 items selected</span><span class="go">View cart &rarr;</span></div>
${bottomnav(0)}`);

screens.drinks = base(`
${statusbar}
<div class="appbar"><div><div class="title h">Pick your drink</div><div class="sub">One vote per person &bull; closes 12:00</div></div><div class="avatar">CU</div></div>
<div class="searchrow"><div class="search">&#x1F50D; Search drinks</div></div>
<div class="grid">
  ${foodCard('&#x2615;','Filter Coffee','1 cup',true)}
  ${foodCard('&#x1F375;','Masala Chai','1 cup',true,true)}
  ${foodCard('&#x1F9CB;','Cold Coffee','1 glass',true)}
  ${foodCard('&#x1F34B;','Lemon Tea','1 cup',true)}
  ${foodCard('&#x1F95B;','Badam Milk','1 glass',true)}
  ${foodCard('&#x1F375;','Green Tea','1 cup',true)}
  ${foodCard('&#x1F9C3;','Buttermilk','1 glass',true)}
  ${foodCard('&#x1F36F;','Hot Choc','1 cup',true)}
  ${foodCard('&#x1F9CA;','Iced Water','1 bottle',true)}
</div>
<div style="position:absolute;left:36px;right:36px;bottom:170px;display:flex;align-items:center;gap:10px;justify-content:center;color:${C.textSecondary};font-size:13px;">
  <span class="pill" style="background:${C.surfaceMuted};color:${C.textPrimary};border:1px solid ${C.border};">&#x1F36C; Sugar-free</span>
</div>
<div class="cartbar placed"><span class="lbl">&#10003; Masala Chai &mdash; vote saved</span><span class="go">Change</span></div>
${bottomnav(1)}`);

screens.cart = base(`
${statusbar}
<div style="height:240px;"></div>
<div style="position:absolute;left:0;right:0;bottom:0;background:${C.surface};border-radius:28px 28px 0 0;
  box-shadow:0 -10px 40px rgba(28,28,30,.16);padding:14px 22px 30px;height:600px;">
  <div style="width:42px;height:5px;border-radius:3px;background:${C.border};margin:0 auto 18px;"></div>
  <div class="h" style="font-size:23px;font-weight:800;">Your order</div>
  <div style="font-size:13px;color:${C.textSecondary};margin-top:3px;margin-bottom:18px;">For Fri, 19 Jun &bull; 3 items</div>
  ${[['&#x1F95F;','Samosa','2 pieces &bull; Veg',C.veg],['&#x1F357;','Chicken Puff','1 piece &bull; Non-veg',C.nonVeg],['&#x1F375;','Masala Chai','1 cup &bull; Sugar-free',C.veg]]
    .map(([e,n,s,col])=>`<div style="display:flex;align-items:center;gap:14px;padding:13px 0;border-bottom:1px solid ${C.divider};">
      <div style="width:48px;height:48px;border-radius:14px;background:${C.surfaceMuted};display:flex;align-items:center;justify-content:center;font-size:26px;">${e}</div>
      <div style="flex:1;"><div style="font-weight:700;font-size:15px;">${n}</div><div style="font-size:12px;color:${C.textSecondary};margin-top:2px;"><span style="color:${col};">&#9679;</span> ${s}</div></div>
      <div style="color:${C.textTertiary};font-size:20px;">&times;</div></div>`).join('')}
  <div style="position:absolute;left:22px;right:22px;bottom:30px;">
    <div style="height:56px;border-radius:16px;background:${C.brand};color:#fff;display:flex;align-items:center;justify-content:center;
      font-weight:700;font-size:16px;box-shadow:0 10px 30px rgba(255,90,51,.34);">Confirm order</div>
  </div>
</div>`, { bg: 'rgba(28,28,30,.35)' });

screens.orders = base(`
${statusbar}
<div class="appbar"><div><div class="title h">Your history</div><div class="sub">Last 7 days</div></div><div class="avatar">CU</div></div>
${[['Today &bull; Fri 19 Jun',[['&#x1F95F;','Samosa'],['&#x1F375;','Masala Chai']],true],
   ['Thu 18 Jun',[['&#x1F36A;','Cookies'],['&#x2615;','Filter Coffee']],false],
   ['Wed 17 Jun',[['&#x1F34C;','Banana'],['&#x1F34B;','Lemon Tea']],false]]
  .map(([d,items,today])=>`
  <div style="padding:6px 20px 4px;display:flex;align-items:center;justify-content:between;">
    <div style="flex:1;font-size:13px;font-weight:700;color:${C.textSecondary};text-transform:uppercase;letter-spacing:.4px;">${d}</div>
    <div class="pill" style="background:${C.surfaceMuted};color:${C.brand};border:1px solid ${C.border};font-size:12px;">&#x21BB; Re-order</div>
  </div>
  <div style="margin:8px 20px 16px;background:${C.surface};border:1px solid ${C.border};border-radius:18px;padding:6px 16px;">
    ${items.map(([e,n],i)=>`<div style="display:flex;align-items:center;gap:12px;padding:12px 0;${i<items.length-1?`border-bottom:1px solid ${C.divider};`:''}">
      <div style="font-size:22px;">${e}</div><div style="flex:1;font-weight:600;font-size:14px;">${n}</div>
      ${today?`<span style="font-size:11px;color:${C.veg};font-weight:700;">&#10003; Placed</span>`:''}</div>`).join('')}
  </div>`).join('')}
${bottomnav(2)}`);

screens.admin = base(`
${statusbar}
<div class="appbar"><div><div class="title h">Today&#39;s summary</div><div class="sub">Admin &bull; Fri, 19 Jun</div></div><div class="avatar" style="color:${C.brand};">A</div></div>
<div style="display:flex;gap:12px;padding:0 20px 6px;">
  ${[['18','Ordered',C.brand],['4','Pending',C.warning],['22','Team',C.info]].map(([n,l,col])=>`
    <div style="flex:1;background:${C.surface};border:1px solid ${C.border};border-radius:18px;padding:16px 12px;text-align:center;">
      <div class="h" style="font-size:30px;font-weight:800;color:${col};">${n}</div>
      <div style="font-size:12px;color:${C.textSecondary};margin-top:2px;">${l}</div></div>`).join('')}
</div>
<div class="section">Top picks today</div>
<div style="margin:0 20px;background:${C.surface};border:1px solid ${C.border};border-radius:18px;padding:6px 16px;">
  ${[['&#x1F95F;','Samosa','7'],['&#x1F36A;','Cookies','5'],['&#x1F375;','Masala Chai','9'],['&#x2615;','Filter Coffee','6']]
    .map(([e,n,c],i)=>`<div style="display:flex;align-items:center;gap:12px;padding:12px 0;${i<3?`border-bottom:1px solid ${C.divider};`:''}">
      <div style="font-size:20px;">${e}</div><div style="flex:1;font-weight:600;font-size:14px;">${n}</div>
      <div class="pill" style="background:${C.surfaceMuted};color:${C.textPrimary};font-size:12px;">&times;${c}</div></div>`).join('')}
</div>
<div class="section">Not ordered yet</div>
<div style="padding:0 20px;display:flex;flex-wrap:wrap;gap:8px;">
  ${['Priya','Arjun','Meera','Sam'].map(n=>`<span class="pill" style="background:${C.surface};border:1px solid ${C.border};color:${C.textSecondary};font-size:12px;">${n}</span>`).join('')}
</div>
<div style="position:absolute;left:16px;right:16px;bottom:92px;height:52px;border-radius:16px;background:#25D366;
  display:flex;align-items:center;justify-content:center;gap:10px;color:#fff;font-weight:700;font-size:15px;box-shadow:0 10px 30px rgba(37,211,102,.3);">
  &#x1F4F2; Share summary to WhatsApp</div>
${bottomnav(3)}`);

// write files
const dir = __dirname;
for (const [k, html] of Object.entries(screens)) {
  fs.writeFileSync(`${dir}/screen_${k}.html`, html);
}
console.log('wrote', Object.keys(screens).length, 'screen html files:', Object.keys(screens).join(', '));
