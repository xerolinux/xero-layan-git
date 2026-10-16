.pragma library

var TAU = Math.PI * 2;
var HP = Math.PI / 2;
var LABELS = [0, 10, 50, 100, 250, 500, 1000];
var OVERLAY = {arc: 1, ring: 1, orbit: 1, liquid: 1, seg: 1, dualring: 1, spiral: 1, ripple: 1};

function fraction(mbps) {
    return Math.min(1, Math.log(1 + mbps / 12) / Math.log(1 + 1000 / 12));
}

function rgb(hex) {
    return [1, 3, 5].map(function (i) { return parseInt(hex.slice(i, i + 2), 16); });
}

function mix(a, b, t) {
    var A = rgb(a), B = rgb(b);
    return "rgb(" + A.map(function (v, i) { return Math.round(v + (B[i] - v) * t); }).join() + ")";
}

function alpha(hex, a) {
    return "rgba(" + rgb(hex).join() + "," + a + ")";
}

function gradient(x, x0, y0, x1, y1, c) {
    var g = x.createLinearGradient(x0, y0, x1, y1);
    g.addColorStop(0, c[0]);
    g.addColorStop(1, c[1]);
    return g;
}

function pick(s, th) {
    return s.ch === "down" ? th.d : s.ch === "up" ? th.u : th.p;
}

function circle(x, cx, cy, r, a0, a1) {
    x.beginPath();
    x.arc(cx, cy, r, a0, a1);
}

function box(x, a, b, c, d, r) {
    x.roundedRect(a, b, c, d, r, r);
}

function hexagon(x, cx, cy, r) {
    x.beginPath();
    for (var k = 0; k < 6; k++) {
        var a = Math.PI / 6 + k * Math.PI / 3;
        if (k)
            x.lineTo(cx + r * Math.cos(a), cy + r * Math.sin(a));
        else
            x.moveTo(cx + r * Math.cos(a), cy + r * Math.sin(a));
    }
    x.closePath();
}

function font(x, px, bold) {
    x.font = (bold ? "bold " : "") + px + "px sans-serif";
}

var V = {};

V.particles = {make: function () {
    var P = [];
    for (var i = 0; i < 150; i++) P.push({x: Math.random(), y: Math.random(), z: .4 + Math.random() * .6});
    return function (x, w, h, s, th) {
        var c = pick(s, th), dir = s.ch === "up" ? -1 : 1, n = Math.round(10 + s.f * 140), sp = .15 + s.f * 1.6, live = s.active || s.f > .01;
        x.lineCap = "round";
        for (var i = 0; i < n; i++) {
            var p = P[i]; p.y += dir * sp * p.z * s.dt * (live ? 1 : .15);
            if (p.y > 1.05) p.y = -.05; else if (p.y < -.05) p.y = 1.05;
            var len = h * (.02 + .055 * sp * p.z), px = w * (.06 + .88 * p.x), py = p.y * h;
            x.globalAlpha = .25 + .75 * p.z; x.lineWidth = 1 + 1.6 * p.z; x.strokeStyle = mix(c[0], c[1], p.x);
            x.beginPath(); x.moveTo(px, py - dir * len); x.lineTo(px, py); x.stroke();
        }
        x.globalAlpha = 1;
        var ey = dir > 0 ? h : 0, g = x.createLinearGradient(0, ey, 0, ey - dir * 34); g.addColorStop(0, alpha(c[0], .45)); g.addColorStop(1, alpha(c[0], 0));
        x.fillStyle = g; x.fillRect(0, dir > 0 ? h - 34 : 0, w, 34);
        x.fillStyle = gradient(x, 0, 0, w, 0, c); x.fillRect(0, dir > 0 ? h - 3 : 0, w, 3);
    };
}};

V.eq = {make: function () { var hs = [], pk = []; return function (x, w, h, s, th) {
    var c = pick(s, th), N = Math.max(12, Math.round(w / 12)), gap = w * .008, bw = w * .92 / N - gap, by = h * .92, mh = h * .84, k = Math.min(1, s.dt * 14);
    var g = gradient(x, 0, by - mh, 0, by, c);
    for (var i = 0; i < N; i++) {
        var tg = s.f * (s.active ? .35 + .65 * Math.abs(Math.sin(s.t * (3 + i * .29) + i * 1.7) * Math.cos(s.t * 1.3 + i)) : .4);
        hs[i] = (hs[i] || 0) + (tg - (hs[i] || 0)) * k;
        pk[i] = Math.max((pk[i] || 0) - s.dt * .25, hs[i]);
        var bx = w * .04 + i * (bw + gap), bh = Math.max(bw, hs[i] * mh);
        x.fillStyle = g; x.beginPath(); box(x, bx, by - bh, bw, bh, bw / 2); x.fill();
        if (pk[i] > .02) { x.fillStyle = alpha(th.fg, .7); x.fillRect(bx, by - pk[i] * mh - bw - 3, bw, 2); }
    }
}; }};

V.spark = {make: function () { return function (x, w, h, s, th) {
    var c = pick(s, th), x0 = 34, x1 = w - 12, y0 = 12, y1 = h - 14, N = 70, H = s.hist;
    font(x, 10, false); x.textAlign = "right"; x.textBaseline = "middle"; x.lineWidth = 1;
    [10, 100, 1000].forEach(function (v) {
        var y = y1 - (y1 - y0) * fraction(v); x.strokeStyle = th.track; x.beginPath();
        for (var dx = x0; dx < x1; dx += 7) { x.moveTo(dx, y); x.lineTo(Math.min(dx + 3, x1), y); }
        x.stroke();
        x.fillStyle = th.dim; x.fillText(String(v), x0 - 6, y);
    });
    x.strokeStyle = th.track; x.beginPath(); x.moveTo(x0, y1); x.lineTo(x1, y1); x.stroke();
    if (H.length < 2) return;
    var px = function (i) { return x0 + (x1 - x0) * i / (N - 1); }, py = function (f) { return y1 - (y1 - y0) * f; };
    x.beginPath(); x.moveTo(px(0), y1);
    for (var i = 0; i < H.length; i++) x.lineTo(px(i), py(H[i]));
    x.lineTo(px(H.length - 1), y1); x.closePath();
    var g = x.createLinearGradient(0, y0, 0, y1); g.addColorStop(0, alpha(c[0], .5)); g.addColorStop(1, alpha(c[1], 0)); x.fillStyle = g; x.fill();
    x.beginPath();
    for (var j = 0; j < H.length; j++) { if (j) x.lineTo(px(j), py(H[j])); else x.moveTo(px(j), py(H[j])); }
    x.lineWidth = 2.4; x.lineJoin = "round"; x.strokeStyle = gradient(x, x0, 0, x1, 0, c); x.shadowColor = c[0]; x.shadowBlur = 8; x.stroke(); x.shadowBlur = 0;
    var ex = px(H.length - 1), ey = py(H[H.length - 1]);
    x.fillStyle = alpha(c[0], .25); circle(x, ex, ey, 6 + 2 * Math.sin(s.t * 7), 0, TAU); x.fill(); x.fillStyle = th.fg; circle(x, ex, ey, 3, 0, TAU); x.fill();
}; }};

V.pipe = {make: function () {
    var pk = [], cd = 0;
    return function (x, w, h, s, th) {
        var c = pick(s, th), dir = s.ch === "up" ? -1 : 1, cy = h * .46, tt = Math.min(h * .2, 34), pad = Math.max(tt * .8 + 6, 26), x0 = pad + tt * .7 + 4, x1 = w - x0, sp = .25 + s.f * 1.5;
        x.fillStyle = th.track; x.beginPath(); box(x, x0, cy - tt / 2, x1 - x0, tt, tt / 2); x.fill();
        cd -= s.dt; if (s.f > .01 && cd <= 0) { pk.push(dir > 0 ? 0 : 1); cd = .35 / (1 + s.f * 9); }
        pk = pk.map(function (p) { return p + dir * sp * s.dt; }).filter(function (p) { return p > 0 && p < 1; });
        x.save(); x.beginPath(); box(x, x0, cy - tt / 2, x1 - x0, tt, tt / 2); x.clip();
        pk.forEach(function (p) { var pw = (x1 - x0) * .06; x.fillStyle = mix(c[0], c[1], p); x.beginPath(); box(x, x0 + (x1 - x0) * p - pw / 2, cy - tt * .3, pw, tt * .6, tt * .3); x.fill(); });
        x.restore();
        font(x, 11, false); x.textAlign = "center"; x.textBaseline = "alphabetic";
        [[pad, "Server", dir > 0], [w - pad, "You", dir < 0]].forEach(function (n) {
            var nx = n[0], recv = !n[2];
            if (recv && s.f > .01) { x.fillStyle = alpha(c[0], .25 * (.5 + .5 * Math.sin(s.t * 8))); circle(x, nx, cy, tt * .75 + 6, 0, TAU); x.fill(); }
            x.fillStyle = th.track; circle(x, nx, cy, tt * .7, 0, TAU); x.fill();
            x.lineWidth = 2; x.strokeStyle = recv && s.f > .01 ? c[0] : th.dim; circle(x, nx, cy, tt * .7, 0, TAU); x.stroke();
            x.fillStyle = th.dim; x.fillText(n[1], nx, cy + tt * .7 + 16);
        });
        var py = h * .82; x.fillStyle = th.track; x.beginPath(); box(x, x0, py, x1 - x0, 4, 2); x.fill();
        if (s.p > .002) { x.fillStyle = c[1]; x.beginPath(); box(x, x0, py, (x1 - x0) * s.p, 4, 2); x.fill(); }
    };
}};

V.dots = {make: function () { return function (x, w, h, s, th) {
    var c = pick(s, th), cols = Math.max(16, Math.round(w / 14)), rows = 8, gx = w * .9 / cols, gy = Math.min(gx, h * .8 / rows), r = Math.min(gx, gy) * .34;
    var ox = w * .05 + gx / 2, oy = h / 2 - gy * (rows - 1) / 2, pc = s.p * cols;
    for (var i = 0; i < cols; i++) {
        var lit = i < pc ? Math.round(rows * s.f * (.65 + .35 * Math.sin(s.t * 3 + i * .8))) : 0;
        for (var j = 0; j < rows; j++) {
            var fb = rows - 1 - j; x.fillStyle = fb < lit ? mix(c[0], c[1], fb / rows) : th.track;
            circle(x, ox + i * gx, oy + j * gy, r, 0, TAU); x.fill();
        }
    }
}; }};

V.bars = {make: function () { return function (x, w, h, s, th) {
    var c = pick(s, th), N = 70, x0 = w * .05, pw = w * .9, by = h * .9, mh = h * .78, bw = pw / N;
    x.fillStyle = th.track; x.fillRect(x0, by + 2, pw, 2);
    for (var i = 0; i < s.hist.length; i++) {
        var f = s.hist[i], bh = Math.max(2, f * mh); x.fillStyle = mix(c[0], c[1], f);
        x.beginPath(); box(x, x0 + i * bw + bw * .15, by - bh, bw * .7, bh, bw * .3); x.fill();
    }
    if (s.hist.length && s.active) {
        var j = s.hist.length - 1; x.shadowColor = c[0]; x.shadowBlur = 12; x.fillStyle = th.fg;
        x.beginPath(); box(x, x0 + j * bw + bw * .15, by - Math.max(2, s.hist[j] * mh), bw * .7, 3, 1); x.fill(); x.shadowBlur = 0;
    }
}; }};

V.ribbon = {make: function () { var ph = 0; return function (x, w, h, s, th) {
    var c = pick(s, th); ph += s.dt * (.8 + s.f * 3); x.lineCap = "round"; x.lineWidth = h * .06; x.strokeStyle = gradient(x, 0, 0, w, 0, c);
    for (var k = 0; k < 4; k++) {
        var amp = h * (.04 + .3 * s.f) * (1 - k * .15), off = k * .9;
        x.beginPath();
        for (var i = 0; i <= w; i += 5) {
            var u = i / w, env = Math.sin(Math.PI * u), y = h * .5 + (Math.sin(u * TAU * 1.3 + ph + off) * amp + Math.sin(u * TAU * 2.7 - ph * 1.4 + off) * amp * .35) * env;
            if (i) x.lineTo(i, y); else x.moveTo(i, y);
        }
        x.globalAlpha = .6 - k * .13; x.stroke();
    }
    x.globalAlpha = 1;
    var py = h - 8; x.fillStyle = th.track; x.fillRect(w * .05, py, w * .9, 3);
    if (s.p > .002) { x.fillStyle = c[1]; x.fillRect(w * .05, py, w * .9 * s.p, 3); }
}; }};

V.arc = {make: function () { return function (x, w, h, s, th) {
    var c = pick(s, th), cx = w / 2, cy = h / 2, r = Math.min(w, h) * .4, lw = r * .16, a0 = .75 * Math.PI, sw = 1.5 * Math.PI, a = a0 + sw * s.f;
    x.lineCap = "round"; x.lineWidth = lw; x.strokeStyle = th.track; circle(x, cx, cy, r, a0, a0 + sw); x.stroke();
    if (s.f > .003) {
        x.strokeStyle = gradient(x, cx - r, cy - r, cx + r, cy + r, c); x.shadowColor = c[0]; x.shadowBlur = lw;
        circle(x, cx, cy, r, a0, a); x.stroke(); x.shadowBlur = 0;
    }
    x.fillStyle = th.fg; x.beginPath(); x.arc(cx + Math.cos(a) * r, cy + Math.sin(a) * r, lw * .2, 0, TAU); x.fill();
    var ri = r - lw * 1.15; x.lineWidth = 2; x.strokeStyle = th.track; circle(x, cx, cy, ri, 0, TAU); x.stroke();
    if (s.p > .002) { x.strokeStyle = c[1]; circle(x, cx, cy, ri, -HP, -HP + TAU * s.p); x.stroke(); }
}; }};

V.ring = {make: function () { return function (x, w, h, s, th) {
    var c = pick(s, th), cx = w / 2, cy = h / 2, r = Math.min(w, h) * .42, lw = r * .07;
    x.lineWidth = lw; x.lineCap = "round"; x.strokeStyle = th.track; circle(x, cx, cy, r, 0, TAU); x.stroke();
    if (s.p > .002) {
        x.strokeStyle = gradient(x, cx - r, cy, cx + r, cy, c); x.shadowColor = c[0]; x.shadowBlur = lw * 1.5;
        circle(x, cx, cy, r, -HP, -HP + TAU * s.p); x.stroke(); x.shadowBlur = 0;
    }
    var r2 = r - lw * 3; x.lineWidth = lw * .5; x.strokeStyle = th.track; circle(x, cx, cy, r2, 0, TAU); x.stroke();
    if (s.f > .003) { x.strokeStyle = c[1]; circle(x, cx, cy, r2, -HP, -HP + TAU * s.f); x.stroke(); }
    var spin = s.t * (s.active ? .6 : .1);
    x.fillStyle = alpha(th.fg, .3);
    for (var d = 0; d < 28; d++) { var da = spin + d * TAU / 28; circle(x, cx + Math.cos(da) * (r2 - lw * 2.2), cy + Math.sin(da) * (r2 - lw * 2.2), 1.6, 0, TAU); x.fill(); }
}; }};

V.ticks = {make: function () { return function (x, w, h, s, th) {
    var c = pick(s, th), cx = w / 2, cy = h * .54, R = Math.min(w * .5, h * .52) * .92, a0 = .75 * Math.PI, sw = 1.5 * Math.PI, N = 55;
    x.lineCap = "round";
    for (var i = 0; i < N; i++) {
        var f = i / (N - 1), a = a0 + sw * f, maj = i % 9 === 0, r1 = R * (maj ? .78 : .86), co = Math.cos(a), si = Math.sin(a);
        x.lineWidth = maj ? 3 : 1.6; x.strokeStyle = f <= s.f + .001 && s.f > .003 ? mix(c[0], c[1], f) : th.track;
        x.beginPath(); x.moveTo(cx + co * r1, cy + si * r1); x.lineTo(cx + co * R, cy + si * R); x.stroke();
    }
    x.fillStyle = th.dim; font(x, R * .09, false); x.textAlign = "center"; x.textBaseline = "middle";
    LABELS.forEach(function (v) { var a = a0 + sw * fraction(v); x.fillText(String(v), cx + Math.cos(a) * R * .64, cy + Math.sin(a) * R * .64); });
    var an = a0 + sw * s.f, cn = Math.cos(an), sn = Math.sin(an);
    x.lineWidth = 3; x.strokeStyle = th.fg; x.beginPath(); x.moveTo(cx - cn * R * .12, cy - sn * R * .12); x.lineTo(cx + cn * R * .56, cy + sn * R * .56); x.stroke();
    x.fillStyle = c[0]; circle(x, cx, cy, R * .07, 0, TAU); x.fill(); x.fillStyle = th.fg; circle(x, cx, cy, R * .03, 0, TAU); x.fill();
}; }};

V.bar = {make: function () { return function (x, w, h, s, th) {
    var c = pick(s, th), bx = w * .05, bw = w * .9, bh = Math.min(h * .22, 28), by = h * .14, py = h - 10;
    x.fillStyle = th.track; x.beginPath(); box(x, bx, by, bw, bh, bh / 2); x.fill();
    if (s.f > .003 || s.active) {
        var fw = Math.max(bh, bw * s.f);
        x.save(); x.beginPath(); box(x, bx, by, fw, bh, bh / 2); x.clip();
        x.fillStyle = gradient(x, bx, 0, bx + bw, 0, c); x.fillRect(bx, by, fw, bh);
        var sx = bx + ((s.t * bw * .6) % (fw + bw * .3)) - bw * .15, g = x.createLinearGradient(sx, 0, sx + bw * .15, 0);
        g.addColorStop(0, "rgba(255,255,255,0)"); g.addColorStop(.5, "rgba(255,255,255,.4)"); g.addColorStop(1, "rgba(255,255,255,0)");
        x.fillStyle = g; x.fillRect(bx, by, fw, bh); x.restore();
    }
    font(x, 10.5, false); x.textAlign = "center"; x.textBaseline = "alphabetic";
    LABELS.forEach(function (v) { var px = bx + bw * fraction(v); x.fillStyle = th.track; x.fillRect(px - .75, by + bh + 5, 1.5, 6); x.fillStyle = th.dim; x.fillText(String(v), px, by + bh + 26); });
    x.fillStyle = th.track; x.beginPath(); box(x, bx, py, bw, 4, 2); x.fill();
    if (s.p > .002) { x.fillStyle = c[1]; x.beginPath(); box(x, bx, py, bw * s.p, 4, 2); x.fill(); }
}; }};

V.wave = {make: function () { var ph = 0; return function (x, w, h, s, th) {
    var c = pick(s, th), bx = w * .06, bw = w * .88, by = h * .06, bh = h * .88, rad = Math.min(24, bh * .2);
    ph += s.dt * (1.5 + s.f * 5);
    x.save(); x.beginPath(); box(x, bx, by, bw, bh, rad); x.clip();
    x.fillStyle = th.track; x.fillRect(bx, by, bw, bh);
    var lvl = by + bh - bh * (.04 + .9 * s.f), amp = 3 + s.f * 11;
    [[0, .9], [1.7, .5]].forEach(function (p, k) {
        x.beginPath(); x.moveTo(bx, by + bh);
        for (var i = 0; i <= bw; i += 4)
            x.lineTo(bx + i, lvl + Math.sin(i / bw * TAU * 1.6 + ph * (k ? -1.3 : 1) + p[0]) * amp);
        x.lineTo(bx + bw, by + bh); x.closePath(); x.globalAlpha = p[1]; x.fillStyle = gradient(x, 0, lvl - amp, 0, by + bh, c); x.fill();
    });
    x.globalAlpha = 1; x.restore();
    x.lineWidth = 2; x.strokeStyle = th.track; x.beginPath(); box(x, bx, by, bw, bh, rad); x.stroke();
}; }};

V.orbit = {make: function () { var an = [0, 0, 0]; return function (x, w, h, s, th) {
    var c = pick(s, th), cx = w / 2, cy = h / 2, R = Math.min(w, h) * .42;
    x.lineWidth = 1.5;
    for (var i = 0; i < 3; i++) {
        var r = R * (.52 + .24 * i), dir = i % 2 ? -1 : 1, n = 3 + i * 2;
        x.strokeStyle = th.track; circle(x, cx, cy, r, 0, TAU); x.stroke();
        an[i] += s.dt * (.5 + s.f * (4 + i * 1.6)) * dir;
        for (var k = 0; k < n; k++) {
            var a = an[i] + k * TAU / n;
            for (var j = 0; j < 6; j++) {
                var aa = a - dir * j * .07 * (.4 + s.f); x.globalAlpha = 1 - j / 6; x.fillStyle = c[k % 2];
                circle(x, cx + Math.cos(aa) * r, cy + Math.sin(aa) * r, 4.5 - j * .55, 0, TAU); x.fill();
            }
        }
    }
    x.globalAlpha = 1; x.lineWidth = 3; x.lineCap = "round"; x.strokeStyle = c[1];
    if (s.p > .002) { circle(x, cx, cy, R * 1.09, -HP, -HP + TAU * s.p); x.stroke(); }
}; }};

V.liquid = {make: function () { var ph = 0, bub = []; return function (x, w, h, s, th) {
    var c = pick(s, th), cx = w / 2, cy = h / 2, R = Math.min(w, h) * .42;
    ph += s.dt * (1.2 + s.f * 4);
    x.save(); circle(x, cx, cy, R, 0, TAU); x.clip(); x.fillStyle = th.track; x.fillRect(0, 0, w, h);
    var lvl = cy + R - 2 * R * (.05 + .9 * s.f), amp = 2 + s.f * 7;
    [[0, .9], [2, .5]].forEach(function (p, k) {
        x.beginPath(); x.moveTo(cx - R, cy + R);
        for (var i = 0; i <= 2 * R; i += 4) x.lineTo(cx - R + i, lvl + Math.sin(i / R * 2.2 + ph * (k ? -1.2 : 1) + p[0]) * amp);
        x.lineTo(cx + R, cy + R); x.closePath(); x.globalAlpha = p[1]; x.fillStyle = gradient(x, 0, lvl - amp, 0, cy + R, c); x.fill();
    });
    x.globalAlpha = 1;
    if (s.active && Math.random() < s.dt * (4 + s.f * 10)) bub.push({x: cx + (Math.random() - .5) * R * 1.2, y: cy + R, v: 20 + Math.random() * 40, r: 1.5 + Math.random() * 3});
    bub = bub.filter(function (b) { b.y -= b.v * s.dt; return b.y > lvl; });
    x.fillStyle = "rgba(255,255,255,.55)"; bub.forEach(function (b) { circle(x, b.x, b.y, b.r, 0, TAU); x.fill(); });
    x.restore();
    x.lineWidth = 3; x.strokeStyle = th.track; circle(x, cx, cy, R, 0, TAU); x.stroke();
    if (s.p > .002) { x.lineCap = "round"; x.strokeStyle = c[1]; circle(x, cx, cy, R + 7, -HP, -HP + TAU * s.p); x.stroke(); }
}; }};

V.seg = {make: function () { return function (x, w, h, s, th) {
    var c = pick(s, th), cx = w / 2, cy = h / 2, r = Math.min(w, h) * .4, N = 40, a0 = .75 * Math.PI, st = 1.5 * Math.PI / N, lit = s.f * N, fl = Math.floor(lit);
    x.lineWidth = r * .2; x.lineCap = "butt";
    for (var i = 0; i < N; i++) {
        var a = a0 + i * st, al = i < fl ? 1 : i < lit ? lit - i : 0;
        if (i === fl && s.active) al *= .6 + .4 * Math.sin(s.t * 20);
        x.strokeStyle = th.track; circle(x, cx, cy, r, a + st * .1, a + st * .9); x.stroke();
        if (al > 0) { x.globalAlpha = al; x.strokeStyle = mix(c[0], c[1], i / N); circle(x, cx, cy, r, a + st * .1, a + st * .9); x.stroke(); x.globalAlpha = 1; }
    }
}; }};

V.dualring = {make: function () { return function (x, w, h, s, th) {
    var cx = w / 2, cy = h * .46, R = Math.min(w, h * .92) * .4, lw = R * .13;
    x.lineCap = "round"; x.lineWidth = lw;
    [[R, s.pd, th.d], [R - lw * 1.9, s.pu, th.u]].forEach(function (ring) {
        var r = ring[0], p = ring[1], c = ring[2];
        x.strokeStyle = th.track; circle(x, cx, cy, r, 0, TAU); x.stroke();
        if (p > .003) {
            x.strokeStyle = gradient(x, cx - r, cy, cx + r, cy, c); x.shadowColor = c[0]; x.shadowBlur = lw;
            circle(x, cx, cy, r, -HP, -HP + TAU * p); x.stroke(); x.shadowBlur = 0;
        }
    });
    font(x, 11, false); x.textAlign = "left"; x.textBaseline = "middle";
    [["Download", th.d[0], w / 2 - 78], ["Upload", th.u[0], w / 2 + 8]].forEach(function (l) {
        x.fillStyle = l[1]; circle(x, l[2], h - 10, 4, 0, TAU); x.fill(); x.fillStyle = th.dim; x.fillText(l[0], l[2] + 9, h - 10);
    });
}; }};

V.radar = {make: function () {
    var sw = 0, bl = [];
    for (var i = 0; i < 26; i++) bl.push({a: (i * 2.399) % TAU, r: .2 + ((i * .37) % .75)});
    return function (x, w, h, s, th) {
        var c = pick(s, th), cx = w / 2, cy = h / 2, R = Math.min(w, h) * .42; sw += s.dt * (1.6 + s.f * 3.4);
        x.lineWidth = 1.2; x.strokeStyle = th.track; [.33, .66, 1].forEach(function (k) { circle(x, cx, cy, R * k, 0, TAU); x.stroke(); });
        x.beginPath(); x.moveTo(cx - R, cy); x.lineTo(cx + R, cy); x.moveTo(cx, cy - R); x.lineTo(cx, cy + R); x.stroke();
        if (x.createConicalGradient) {
            var g = x.createConicalGradient(cx, cy, sw - 1.1);
            g.addColorStop(0, alpha(c[0], 0)); g.addColorStop(.175, alpha(c[0], .5)); g.addColorStop(.1751, alpha(c[0], 0)); g.addColorStop(1, alpha(c[0], 0));
            x.fillStyle = g; circle(x, cx, cy, R, 0, TAU); x.fill();
        }
        x.lineWidth = 2; x.strokeStyle = c[0]; x.beginPath(); x.moveTo(cx, cy); x.lineTo(cx + Math.cos(sw) * R, cy + Math.sin(sw) * R); x.stroke();
        var n = Math.floor(s.f * 26) + (s.active ? 2 : 0);
        for (var k = 0; k < n && k < 26; k++) {
            var b = bl[k], d = ((sw - b.a) % TAU + TAU) % TAU, al = Math.max(0, 1 - d / (TAU * .8));
            x.globalAlpha = al; x.fillStyle = c[1]; circle(x, cx + Math.cos(b.a) * R * b.r, cy + Math.sin(b.a) * R * b.r, 3 + 2.5 * al, 0, TAU); x.fill();
        }
        x.globalAlpha = 1; x.lineWidth = 3; x.lineCap = "round"; x.strokeStyle = c[1];
        if (s.p > .002) { circle(x, cx, cy, R * 1.07, -HP, -HP + TAU * s.p); x.stroke(); }
    };
}};

V.dial = {make: function () { var na = 0, nv = 0; return function (x, w, h, s, th) {
    var c = pick(s, th), R = Math.min(w * .44, h * .78), cx = w / 2, cy = (h + R) / 2, lw = R * .12, a0 = Math.PI, sw = Math.PI;
    nv += ((s.f - na) * 90 - nv * 11) * s.dt; na += nv * s.dt;
    x.lineCap = "round"; x.lineWidth = lw; x.strokeStyle = th.track; circle(x, cx, cy, R, a0, a0 + sw); x.stroke();
    if (s.f > .003) { x.strokeStyle = gradient(x, cx - R, 0, cx + R, 0, c); circle(x, cx, cy, R, a0, a0 + sw * s.f); x.stroke(); }
    x.fillStyle = th.dim; font(x, Math.max(9, R * .085), false); x.textAlign = "center"; x.textBaseline = "middle";
    LABELS.forEach(function (v) { var a = a0 + sw * fraction(v); x.fillText(String(v), cx + Math.cos(a) * R * .74, cy + Math.sin(a) * R * .74); });
    var an = a0 + sw * Math.max(0, na), co = Math.cos(an), si = Math.sin(an);
    x.lineWidth = 3; x.strokeStyle = th.fg; x.beginPath(); x.moveTo(cx, cy); x.lineTo(cx + co * R * .62, cy + si * R * .62); x.stroke();
    x.fillStyle = c[0]; circle(x, cx, cy, R * .07, 0, TAU); x.fill(); x.fillStyle = th.fg; circle(x, cx, cy, R * .03, 0, TAU); x.fill();
}; }};

V.hex = {make: function () {
    var key = "", cells = [];
    return function (x, w, h, s, th) {
        var k = w + "x" + h;
        if (k !== key) {
            key = k; cells = []; var sz = Math.min(w, h) / 13, cx = w / 2, cy = h / 2, R = Math.min(w, h) * .43;
            for (var q = -8; q <= 8; q++) for (var r = -8; r <= 8; r++) {
                var px = cx + sz * Math.sqrt(3) * (q + r / 2), py = cy + sz * 1.5 * r, d = Math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
                if (d <= R) cells.push({px: px, py: py, d: d, sz: sz});
            }
            cells.sort(function (a, b) { return a.d - b.d; });
        }
        var c = pick(s, th), n = cells.length, lit = s.p * n, md = n ? cells[n - 1].d || 1 : 1;
        for (var i = 0; i < n; i++) {
            var cell = cells[i]; hexagon(x, cell.px, cell.py, cell.sz * .92);
            if (i < lit) { x.globalAlpha = .25 + .75 * (.55 + .45 * Math.sin(s.t * 3 + i * .9)) * (.35 + .65 * s.f); x.fillStyle = mix(c[0], c[1], cell.d / md); }
            else { x.globalAlpha = 1; x.fillStyle = th.track; }
            x.fill();
        }
        x.globalAlpha = 1;
    };
}};

V.spiral = {make: function () { var rot = 0; return function (x, w, h, s, th) {
    var c = pick(s, th), cx = w / 2, cy = h / 2, R = Math.min(w, h) * .46, N = 72, r0 = R * .56;
    rot += s.dt * (.15 + s.f * .9); x.lineCap = "round"; x.lineWidth = Math.max(2, R * .045);
    for (var i = 0; i < N; i++) {
        var f = i / N, a = rot + f * TAU - HP, on = f < s.p, co = Math.cos(a), si = Math.sin(a);
        var ln = R * (.06 + (on ? .14 + .24 * s.f * (.55 + .45 * Math.sin(s.t * 4 + i * .7)) : 0));
        x.strokeStyle = on ? mix(c[0], c[1], f) : th.track;
        x.beginPath(); x.moveTo(cx + co * r0, cy + si * r0); x.lineTo(cx + co * (r0 + ln), cy + si * (r0 + ln)); x.stroke();
    }
}; }};

V.ripple = {make: function () { var rp = [], cd = 0; return function (x, w, h, s, th) {
    var c = pick(s, th), cx = w / 2, cy = h / 2, R = Math.min(w, h) * .46, inward = s.ch === "down";
    cd -= s.dt; if (s.active && cd <= 0) { rp.push(0); cd = .9 / (1 + s.f * 5); }
    var sp = .35 + s.f * .9; rp = rp.map(function (t) { return t + s.dt * sp; }).filter(function (t) { return t < 1; });
    x.lineWidth = 2;
    rp.forEach(function (t) { x.globalAlpha = Math.sin(Math.PI * t) * .85; x.strokeStyle = mix(c[0], c[1], t); circle(x, cx, cy, R * (.42 + .58 * (inward ? 1 - t : t)), 0, TAU); x.stroke(); });
    x.globalAlpha = 1; x.strokeStyle = th.track; circle(x, cx, cy, R * .42, 0, TAU); x.stroke();
    if (s.p > .002) { x.lineCap = "round"; x.strokeStyle = c[1]; circle(x, cx, cy, R * 1.03, -HP, -HP + TAU * s.p); x.stroke(); }
}; }};

function known(name) {
    return V.hasOwnProperty(name);
}

function overlay(name) {
    return OVERLAY.hasOwnProperty(name);
}

function create(name) {
    return V[known(name) ? name : "particles"].make();
}
