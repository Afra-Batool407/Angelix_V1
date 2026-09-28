extends StaticBody3D
## Builds a procedural heightmap terrain mesh (plus matching collision) at runtime.

@export var size := Vector2(64.0, 64.0)
@export var subdivisions := 96
@export var height_scale := 6.0
@export var noise_frequency := 0.035
@export var noise_seed := 1337

## Deterministic flattened areas (hub, stations, future zones): terrain
## height blends to spot.y within flat_radius of each spot (x,z).
@export var flat_spots: Array[Vector3] = [
	Vector3(0, 1.5, 8),      # hub entrance / spawn
	Vector3(8, 1.5, 2),      # Real Numbers station
]
@export var flat_radius := 7.0


func _ready() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = noise_frequency
	noise.fractal_octaves = 4

	var mesh := _build_terrain_mesh(noise)
	$TerrainMesh.mesh = mesh
	$CollisionShape3D.shape = mesh.create_trimesh_shape()


func _blended_height(noise: FastNoiseLite, x: float, z: float) -> float:
	var h := noise.get_noise_2d(x, z) * height_scale
	for spot in flat_spots:
		var d := Vector2(x - spot.x, z - spot.z).length()
		if d < flat_radius:
			var t := smoothstep(0.0, 1.0, d / flat_radius)
			h = lerp(spot.y, h, t)
	return h


func _build_terrain_mesh(noise: FastNoiseLite) -> ArrayMesh:
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions

	# Displace the flat plane's vertices along Y using 2D noise.
	var arrays := plane.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var v := vertices[i]
		vertices[i] = Vector3(v.x, _blended_height(noise, v.x, v.z), v.z)
	arrays[Mesh.ARRAY_VERTEX] = vertices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Smooth normals so the hills shade correctly under the sun.
	var st := SurfaceTool.new()
	st.create_from(array_mesh, 0)
	st.generate_normals()
	return st.commit()
