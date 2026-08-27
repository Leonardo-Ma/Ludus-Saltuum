# Global files (autoloads in Godot)

#### Before creating one, ask:
- Do I need an instance of this?
- Does it needs _ready or _process, physics, signals, call_deferred, child management?
- Does it needs to exist in the scene tree?

If you answered 'No' to everything, you probably want a static class extending RefCounted instead. With static variables and methods.

Usually when driven by another system instead of it being a system itself.
