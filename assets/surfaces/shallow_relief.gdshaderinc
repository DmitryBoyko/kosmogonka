// Reconstruct a shallow slope at the texture's actual world-space scale.
vec3 shallow_relief(vec3 normal, vec3 at, float detail, float depth) {
	vec3 dx = dFdx(at);
	vec3 dy = dFdy(at);
	vec3 tangent_x = cross(dy, normal);
	vec3 tangent_y = cross(normal, dx);
	float det = dot(dx, tangent_x);
	if (abs(det) < 0.00000001) {
		return normal;
	}
	vec3 gradient = (dFdx(detail) * tangent_x + dFdy(detail) * tangent_y) / det;
	return normalize(normal - clamp(gradient * depth, vec3(-.30), vec3(.30)));
}
