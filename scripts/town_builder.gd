extends Node3D
class_name TownBuilder
## Builds the AngelTown hub zones: Math Meadows, Science Springs and
## Language Lagoon, connecting stone paths, the central Fountain of
## Knowledge, zone signs, and honestly-locked future stations.
## All geometry is low-poly Godot primitives; layout is deterministic.
## Tree/rock scatter lives in town_scatter.gd (MultiMesh, 2 draw calls).

const HUB := Vector3(0, 1.5, 8)
const ZONE_CENTERS := {
	"Math Meadows": Vector3(8, 1.5, 2),
	"Science Springs": Vector3(-16, 1.5, -12),
	"Language Lagoon": Vector3(14, 1.5, -14),
}
const ZONE_COLORS := {
	"Math Meadows": Color(0.45, 0.75, 0.4),
	"Science Springs": Color(0.35, 0.6, 0.8),
	"Language Lagoon": Color(0.35, 0.55, 0.65),
}
const FOUNTAIN_POS := Vector3(0, 1.5, 0)

@onready var _terrain: StaticBody3D = $"../Terrain"


func _ready() -> void:
	_build_zone_grounds()
	_build_fountain()
	_build_paths()
	_build_locked_stations()
	_build_zone_signs()
	var scatter := TownScatter.new()
	scatter.terrain_provider = Callable(self, "_terrain_y")
	scatter.blocked_provider = Callable(self, "_blocks_gameplay")
	add_child(scatter)


## Ground height at (x, z) from the procedural terrain script when available.
func _terrain_y(x: float, z: float) -> float:
	if _terrain != null and _terrain.has_method("get_ground_height"):
		return _terrain.get_ground_height(x, z)
	return 1.5  # flattened-spot fallback


## True when scatter at (x, z) would obstruct hub, fountain, zones, stations
## or the hub-to-zone path corridors.
func _blocks_gameplay(x: float, z: float) -> bool:
	var p := Vector2(x, z)
	var keep_clear: Array[Vector2] = [
		Vector2(HUB.x, HUB.z),
		Vector2(FOUNTAIN_POS.x, FOUNTAIN_POS.z),
	]
	for zone_name in ZONE_CENTERS:
		var c: Vector3 = ZONE_CENTERS[zone_name]
		keep_clear.append(Vector2(c.x, c.z))
	for c in keep_clear:
		if p.distance_to(c) < 9.0:
			return true
	for zone_name in ZONE_CENTERS:
		var a := Vector2(HUB.x, HUB.z)
		var b3: Vector3 = ZONE_CENTERS[zone_name]
		var b := Vector2(b3.x, b3.z)
		var ab := b - a
		var t := clampf((p - a).dot(ab) / max(ab.length_squared(), 0.001), 0.0, 1.0)
		if p.distance_to(a + ab * t) < 2.4:
			return true
	return false


func _build_zone_grounds() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 7.0
	disc.bottom_radius = 7.0
	disc.height = 0.06
	for zone_name in ZONE_CENTERS:
		var center: Vector3 = ZONE_CENTERS[zone_name]
		var mesh := MeshInstance3D.new()
		mesh.mesh = disc
		mesh.position = Vector3(center.x, 1.56, center.z)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ZONE_COLORS.get(zone_name, Color(0.5, 0.5, 0.5))
		mesh.material_override = mat
		add_child(mesh)


func _build_fountain() -> void:
	var root := Node3D.new()
	root.name = "FountainOfKnowledge"
	root.position = Vector3(FOUNTAIN_POS.x, _terrain_y(FOUNTAIN_POS.x, FOUNTAIN_POS.z) + 0.05, FOUNTAIN_POS.z)
	add_child(root)

	var pool := MeshInstance3D.new()
	var pool_mesh := CylinderMesh.new()
	pool_mesh.top_radius = 2.6
	pool_mesh.bottom_radius = 3.0
	pool_mesh.height = 0.5
	pool.mesh = pool_mesh
	pool.position.y = 0.25
	var pool_mat := StandardMaterial3D.new()
	pool_mat.albedo_color = Color(0.45, 0.5, 0.6)
	pool.material_override = pool_mat
	root.add_child(pool)

	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 2.45
	water_mesh.bottom_radius = 2.45
	water_mesh.height = 0.1
	water.mesh = water_mesh
	water.position.y = 0.52
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.4, 0.6, 0.9)
	water_mat.emission_enabled = true
	water_mat.emission = Color(0.3, 0.5, 0.8)
	water_mat.emission_energy_multiplier = 0.4
	water.material_override = water_mat
	root.add_child(water)

	var column := MeshInstance3D.new()
	var col_mesh := CylinderMesh.new()
	col_mesh.top_radius = 0.22
	col_mesh.bottom_radius = 0.34
	col_mesh.height = 2.6
	column.mesh = col_mesh
	column.position.y = 1.55
	var col_mat := StandardMaterial3D.new()
	col_mat.albedo_color = Color(0.7, 0.74, 0.85)
	column.material_override = col_mat
	root.add_child(column)

	var bowl := MeshInstance3D.new()
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = 1.1
	bowl_mesh.bottom_radius = 0.4
	bowl_mesh.height = 0.4
	bowl.mesh = bowl_mesh
	bowl.position.y = 2.95
	var bowl_mat := StandardMaterial3D.new()
	bowl_mat.albedo_color = Color(0.78, 0.82, 0.95)
	bowl.material_override = bowl_mat
	root.add_child(bowl)

	var book := Label3D.new()
	book.text = "Fountain of Knowledge"
	book.font_size = 72
	book.pixel_size = 0.005
	book.billboard = 1
	book.position.y = 3.9
	book.modulate = Color(0.98, 0.9, 0.6)
	book.outline_size = 14
	root.add_child(book)


func _build_paths() -> void:
	var slab := BoxMesh.new()
	slab.size = Vector3(1.6, 0.08, 1.6)
	var slab_mat := StandardMaterial3D.new()
	slab_mat.albedo_color = Color(0.62, 0.6, 0.55)
	for zone_name in ZONE_CENTERS:
		var a := Vector2(HUB.x, HUB.z)
		var b3: Vector3 = ZONE_CENTERS[zone_name]
		var b := Vector2(b3.x, b3.z)
		var steps := int(a.distance_to(b) / 2.2)
		for i in steps + 1:
			var t: float = float(i) / max(steps, 1)
			var p := a.lerp(b, t)
			var slab_node := MeshInstance3D.new()
			slab_node.mesh = slab
			slab_node.position = Vector3(p.x, _terrain_y(p.x, p.y) + 0.12, p.y)
			slab_node.material_override = slab_mat
			add_child(slab_node)


## Future-zone anchors: honestly locked, no invented curriculum titles.
func _build_locked_stations() -> void:
	var scene: PackedScene = load("res://scenes/learning_station.tscn")
	var specs := [
		{"title": "Coming soon", "zone": "Science Springs",
			"pos": Vector3(-16, 1.5, -12)},
		{"title": "Coming soon", "zone": "Language Lagoon",
			"pos": Vector3(14, 1.5, -14)},
	]
	for spec in specs:
		var st := scene.instantiate() as LearningStation
		st.topic_id = ""  # locked: no content exists yet
		st.display_title = spec["title"]
		st.zone = spec["zone"]
		st.available = false
		st.position = spec["pos"]
		st.add_to_group("learning_station")
		add_child(st)


func _build_zone_signs() -> void:
	for zone_name in ZONE_CENTERS:
		var center: Vector3 = ZONE_CENTERS[zone_name]
		var sign := Label3D.new()
		sign.text = zone_name
		sign.font_size = 96
		sign.pixel_size = 0.006
		sign.billboard = 1
		sign.position = Vector3(center.x, 5.2, center.z)
		sign.modulate = Color(0.95, 0.97, 1)
		sign.outline_size = 16
		add_child(sign)
