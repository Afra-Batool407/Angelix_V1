extends Node
class_name DayNightCycle
## Very cheap day/night cycle: rotates one directional light and lerps a few
## environment/sky colors on a slow period. Designed to be stopped entirely
## in Performance Mode (start() / stop()) and never uses per-frame expensive
## effects (no shadows changes, no particles, no post-processing).

signal hour_changed(hour: float)

const DAY_LENGTH_SEC := 240.0     ## one full day in 4 minutes
const START_HOUR := 9.0

## Key colors sampled by hour: [hour, sun_color, ambient, sky_top, sky_horizon]
const KEYS := [
	[0.0, Color(0.55, 0.6, 0.9), Color(0.25, 0.28, 0.45), Color(0.07, 0.09, 0.2), Color(0.14, 0.16, 0.3)],
	[6.0, Color(1.0, 0.75, 0.5), Color(0.45, 0.4, 0.42), Color(0.35, 0.3, 0.5), Color(0.8, 0.55, 0.45)],
	[12.0, Color(1.0, 0.97, 0.9), Color(0.62, 0.66, 0.75), Color(0.29, 0.5, 0.82), Color(0.72, 0.81, 0.91)],
	[18.0, Color(1.0, 0.6, 0.35), Color(0.5, 0.38, 0.38), Color(0.3, 0.25, 0.5), Color(0.85, 0.5, 0.4)],
	[24.0, Color(0.55, 0.6, 0.9), Color(0.25, 0.28, 0.45), Color(0.07, 0.09, 0.2), Color(0.14, 0.16, 0.3)],
]

var enabled := true
var _hour := START_HOUR
var _sun: DirectionalLight3D
var _env: Environment
var _sky: ProceduralSkyMaterial


func setup(sun: DirectionalLight3D, env: Environment) -> void:
	_sun = sun
	_env = env
	if _env != null and _env.sky != null and _env.sky.sky_material is ProceduralSkyMaterial:
		_sky = _env.sky.sky_material as ProceduralSkyMaterial
	apply_hour()


func start() -> void:
	enabled = true
	set_process(true)


func stop() -> void:
	enabled = false
	set_process(false)


func is_enabled() -> bool:
	return enabled


func _process(delta: float) -> void:
	if not enabled:
		return
	_hour = fmod(_hour + delta * 24.0 / DAY_LENGTH_SEC, 24.0)
	apply_hour()


func apply_hour() -> void:
	var c := _sample(_hour)
	if _sun != null:
		_sun.light_color = c[0]
		var t := _hour
		# Sun elevation: high at noon, below horizon at night.
		var elev := sin((t - 6.0) / 24.0 * TAU) * 0.9 + 0.25
		_sun.rotation = Vector3(-clampf(elev, -0.4, 1.2), -0.6, 0)
		_sun.light_energy = clampf(elev + 0.35, 0.15, 1.2)
	if _env != null:
		_env.ambient_light_color = c[1]
	if _sky != null:
		_sky.sky_top_color = c[2]
		_sky.sky_horizon_color = c[3]
	hour_changed.emit(_hour)


func _sample(hour: float) -> Array:
	for i in range(KEYS.size() - 1):
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if hour >= float(a[0]) and hour <= float(b[0]):
			var t := (hour - float(a[0])) / max(float(b[0]) - float(a[0]), 0.001)
			return [
				(a[1] as Color).lerp(b[1], t),
				(a[2] as Color).lerp(b[2], t),
				(a[3] as Color).lerp(b[3], t),
				(a[4] as Color).lerp(b[4], t),
			]
	return [Color(1, 1, 1), Color(0.6, 0.6, 0.6), Color(0.3, 0.5, 0.8), Color(0.7, 0.8, 0.9)]
