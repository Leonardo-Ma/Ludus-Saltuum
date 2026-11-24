class_name PerceptionConfig
extends Resource

## General configuration for the perception system, holding multiple perception types

@export_category("General")
@export var update_interval: float = 0.1
@export var memory_duration: float = 10.0

@export_category("Visual")
@export var visual: VisualConfig = VisualConfig.new()

@export_category("Awareness")
@export_range(0.0, 100.0, 0.1, "suffix:m") var hearing_range: float = 15.0
## Seconds a place of interest stays searchable after its last report
@export_range(0.0, 120.0, 0.5, "suffix:s") var investigation_duration: float = 20.0
## Radius around reported position for local search waypoints
@export_range(0.0, 20.0, 0.5, "suffix:m") var investigation_radius: float = 8.0
## Allies recruited when NPC starts its own investigation
@export_range(0.0, 200.0, 1.0, "suffix:m") var investigation_alert_radius: float = 50.0
## Allies inside this radius are called to investigate on first sighting, attack or hit
@export_range(0.0, 100.0, 0.5, "suffix:m") var ally_alert_radius: float = 25.0
