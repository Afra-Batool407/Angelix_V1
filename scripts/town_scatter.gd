extends Node3D
class_name TownScatter
## Deterministic low-poly tree/rock scatter for AngelTown using MultiMesh
## (two draw calls total). Placement comes from a fixed seed and skips spots
## provided by the town builder (paths, hub, fountain, zones, stations).

const COUNT := 220
const SEED := 20260928
const RANGE_X := Vector2(-30.0, 30.0)
const RANGE_Z := Vector2(-34.0, 30.0)

## Callable(x: float, z: float) -> float: ground height provider.
var terrain_provider := Callable()
## Callable(x: float, z: float) -> bool: true when the spot must stay clear.
var blocked_provider := Callable()


func _ready() -> void:
	if not terrain_provider.is_valid() or not blocked_provider.is_valid():
		push_error("TownScatter: providers not set; skipping scatter (safe fallback).")
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var candidates: Array = []
	for i in COUNT:
		var x := rng.randf_range(RANGE_X.x, RANGE_X.y)
		var z := rng.randf_range(RANGE_Z.x, RANGE_Z.y)
		var s := rng.randf_range(0.7, 1.3)
		if blocked_provider.call(x, z):
			continue
		var y: float = terrain_provider.call(x, z)
		candidates.append({"x": x, "y": y - 0.05, "z": z, "s": s, "tree": i % 2 == 0})
	_add_multimesh(candidates, true)
	_add_multimesh(candidates, false)


func _add_multimesh(candidates: Array, trees: bool) -> void:
	var chosen: Array = candidates.filter(func(c): return bool(c["tree"]) == trees)
	if chosen.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _make_tree_mesh() if trees else _make_rock_mesh()
	mm.instance_count = chosen.size()
	for i in chosen.size():
		var c: Dictionary = chosen[i]
		var basis := Basis.IDENTITY.scaled(Vector3.ONE * float(c["s"]))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(c["x"], c["y"], c["z"])))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _tree_material() if trees else _rock_material()
	add_child(mmi)


func _make_tree_mesh() -> Mesh:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.9
	cone.height = 2.6
	return cone


func _make_rock_mesh() -> Mesh:
	var rock := SphereMesh.new()
	rock.radius = 0.5
	rock.height = 0.7
	return rock


func _tree_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.62, 0.35)
	return m


func _rock_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.52, 0.52, 0.55)
	return m
