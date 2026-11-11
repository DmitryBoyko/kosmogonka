// REEBOO Loot & Pickup VFX - shared shader helpers: noise, color, billboards and glyph shapes.
// Everything is procedural (no textures), so it works the same in Forward+, Mobile and Compatibility.

float loot_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float loot_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(loot_hash(i), loot_hash(i + vec2(1.0, 0.0)), f.x),
			mix(loot_hash(i + vec2(0.0, 1.0)), loot_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Value noise that repeats every `period` units along x (cylinder UVs wrap around, so there is no seam).
float loot_pnoise(vec2 p, float period) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x0 = mod(i.x, period);
	float x1 = mod(i.x + 1.0, period);
	float a = loot_hash(vec2(x0, i.y));
	float b = loot_hash(vec2(x1, i.y));
	float c = loot_hash(vec2(x0, i.y + 1.0));
	float d = loot_hash(vec2(x1, i.y + 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Anti-aliased band of half width `w` around `center`.
float loot_band(float x, float center, float w) {
	float aa = max(fwidth(x), 0.0005) * 1.5;
	return 1.0 - smoothstep(w, w + aa, abs(x - center));
}

vec3 loot_to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

// Camera-facing quad, keeping the node (or particle) scale; `angle` turns it in screen space.
mat4 loot_billboard(mat4 model, mat4 inv_view, mat4 view, float angle) {
	mat4 m = mat4(normalize(inv_view[0]), normalize(inv_view[1]), normalize(inv_view[2]), model[3]);
	m = m * mat4(vec4(cos(angle), -sin(angle), 0.0, 0.0), vec4(sin(angle), cos(angle), 0.0, 0.0),
			vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	m = m * mat4(vec4(length(model[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(model[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(model[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	return view * m;
}

// ---- Glyph signed distances. p runs -1..1 with +y up. Negative = inside.
float loot_sd_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float loot_sd_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float loot_sd_triangle_up(vec2 p, vec2 q) {
	// Isosceles triangle, apex at (0, q.y), base at y = 0 with half width q.x.
	p.y = q.y - p.y;
	p.x = abs(p.x);
	vec2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
	vec2 b = p - q * vec2(clamp(p.x / q.x, 0.0, 1.0), 1.0);
	float s = -sign(q.y);
	vec2 d = min(vec2(dot(a, a), s * (p.x * q.y - p.y * q.x)), vec2(dot(b, b), s * (p.y - q.y)));
	return -sqrt(d.x) * sign(d.y);
}

float loot_sd_star5(vec2 p, float r, float rf) {
	const vec2 k1 = vec2(0.809016994375, -0.587785252292);
	const vec2 k2 = vec2(-0.809016994375, -0.587785252292);
	p.x = abs(p.x);
	p -= 2.0 * max(dot(k1, p), 0.0) * k1;
	p -= 2.0 * max(dot(k2, p), 0.0) * k2;
	p.x = abs(p.x);
	p.y -= r;
	vec2 ba = rf * vec2(-k1.y, k1.x) - vec2(0.0, 1.0);
	float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
	return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

float loot_sd_uneven_capsule(vec2 p, float r1, float r2, float h) {
	p.x = abs(p.x);
	float b = (r1 - r2) / h;
	float a = sqrt(1.0 - b * b);
	float k = dot(p, vec2(-b, a));
	if (k < 0.0) return length(p) - r1;
	if (k > a * h) return length(p - vec2(0.0, h)) - r2;
	return dot(p, vec2(a, b)) - r1;
}

// 0 Plus, 1 Droplet, 2 Diamond, 3 Star, 4 Arrow Down, 5 Exclamation, 6 Sparkle (4 points), 7 Coin
float loot_glyph(int g, vec2 p) {
	if (g == 0) {
		return min(loot_sd_box(p, vec2(0.22, 0.74)), loot_sd_box(p, vec2(0.74, 0.22))) - 0.1;
	} else if (g == 1) {
		return loot_sd_uneven_capsule(p - vec2(0.0, -0.38), 0.5, 0.05, 1.18);
	} else if (g == 2) {
		vec2 q = abs(p);
		return (q.x + q.y * 0.62 - 0.6) * 0.85;
	} else if (g == 3) {
		return loot_sd_star5(p + vec2(0.0, 0.06), 0.92, 0.45) - 0.04;
	} else if (g == 4) {
		vec2 q = vec2(p.x, -p.y);
		float head = loot_sd_triangle_up(q - vec2(0.0, 0.05), vec2(0.8, 0.85)) - 0.05;
		float shaft = loot_sd_box(q - vec2(0.0, -0.4), vec2(0.25, 0.46)) - 0.05;
		return min(head, shaft);
	} else if (g == 5) {
		float bar = loot_sd_uneven_capsule(p - vec2(0.0, -0.2), 0.11, 0.22, 0.96);
		return min(bar, length(p - vec2(0.0, -0.72)) - 0.17);
	} else if (g == 6) {
		vec2 q = abs(p);
		float d = pow(q.x, 0.55) + pow(q.y, 0.55) - 0.95;
		return d * 0.5;
	} else if (g == 7) {
		float outer = length(p) - 0.85;
		float inner = abs(length(p) - 0.58) - 0.05;
		return max(outer, -inner);
	}
	return length(p) - 0.8;
}
