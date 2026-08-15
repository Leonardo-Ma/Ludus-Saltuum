# Code Style Guide
Inspired by [Thrive's Code Style](https://github.com/Revolutionary-Games/Thrive/blob/master/doc/style_guide.md)

Objectives [Godot's GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

---
This style guide is separated into three parts: code rules, other file rules, and guidelines for git.

The style rules are intended to increase readability of the source code for humans that will read the written code. The most important rule of all is: Use common sense.

## Code style rules

| Type          | Convention   | Example                      |
|---------------|--------------|------------------------------|
| File names    | snake_case   | yaml_parser.gd               |
| Class names   | PascalCase   | class_name YAMLParser        |
| Node names    | PascalCase   | Camera3D, Player             |
| Functions     | snake_case   | func load_level():           |
| Variables     | snake_case   | var particle_effect          |
| Signals       | snake_case   | signal door_opened           |
| Constants     | CONSTANT_CASE| const MAX_SPEED = 200        |
| Enum names    | PascalCase   | enum Element                 |
| Enum members  | CONSTANT_CASE| {EARTH, WATER, AIR, FIRE}    |

- Indentation is 4 spaces. Continued statements are indented one level
  higher.

### Naming
- Names (that includes variables, functions and classes) should be
  descriptive. Avoid abbreviations. Do not shorten variable names just
  to save key strokes, it will be read far more often than it will be
  written. Single character variable names can be used in for
  loops. They should be avoided everywhere else.

- Some common short names are accepted (and even preferred): i, k, a,
  b used in loops (x, y, z used in loops that deal with coordinates or
  math), e used in `catch` blocks as the exception name. Other
  variables in loops and elsewhere need to be named with actually
  descriptive variable names.

- Similarly, some very common abbreviations are used in the code,
  and can (and should) thus be used when naming variables. These are
  however *rare* exceptions, not the rule. The allowed abbreviations
  are listed below. No other abbreviation should be used.
  - `min` - `max` - `pos` - `rot` - `str`
  - `rect` (when related to class names and variables holding instances of those classes)
  - `tech` (short for technology)

#### File system
- Files inside `/scr` and Godot related are snake_case.
- - Only exception: [ScriptTemplates](https://docs.godotengine.org/en/stable/tutorials/scripting/creating_script_templates.html)
- -

- Comments start with a space and capital letter, unless it is a commented out
  code block or a keyword.

- Use preincrement (`++i`) in loops and other cases, unless you
  actually need post increment.

- Ternary operators (`condition ? exprIfTrue : exprIfFalse`) can be used instead of `if ... else`
  statements as long as they are kept readable.

- Single line variables (and properties) can be next to each other
  without a blank line. Other variables and class elements should have
  a blank line separating them.

- Don't declare multiple local variables on the same line.

- Properties should be very strongly preferred over getter or setter
  methods. Only when a parameter is needed, is a getter method a good
  idea.

- When setting things that might require validation going through a
  property should be preferred, even in the same class to avoid
  mistakes in skipping some logic by directly assigning a field.

- Unrelated uses should not share the same variable. Instead they
  should locally define their own variable instance.

- Avoid globals. Especially in object trees where you can easily
  enough pass the reference along.

- Do not use `string.Format` with a translated format string, as
  translation mistakes can crash the game in that case. Instead either
  use `LocalizedString`, `LocalizedStringBuilder`, or
  `StringUtils.FormatSafe`. Those ways will automatically catch
  exceptions from broken translations and return the format string
  un-formatted. `StringUtils` will likely want to be invoked as an
  extension method on the string (`"example".FormatSafe(...)`). If the
  format string is not user supplied, normal `string.Format` is allowed,
  but should be passed `CultureInfo.CurrentCulture` as the first
  parameter as we want text shown to the user in the user's selected
  locale.

- Prefer early returns in methods to avoid unnecessary
  indentation. Check assumptions about the parameters of a method at
  the start and return early with an error if the inputs are not
  valid.

- Use `TryGetValue` instead of first calling `Dictionary.ContainsKey`
  and then reading the value separate because `TryGetValue` is faster.

- Defensive programming is recommended. The idea is to write code that
  expects other parts of the codebase to mess up somewhere. For example,
  when checking for health, instead of checking
  `health == 0`, it is recommended to do `health <= 0` to guard
  against negative health bugs.

- Separation of concerns should be used.

- When writing conditions checking booleans, don't explicitly write
  out `true` or `false` (unless the variable is nullable in which case
  the explicit compare is required). So write code like this: `if
  (thing)` and not: `if (thing == true)`.

- Finally you should attempt to reach the abstract goal of clean
  code. Here are some concepts that are indicative of good code (and
  breaking these can be bad code): Liskov substitution principle,
  single purpose principle, logically putting same kind of code in the
  same place, avoid repetition, avoid expensive operations in a loop,
  prefer simpler code to understand. Avoid anti-patterns, for example
  God class.

## Godot usage

- Specific GUI: [gui_guide.md](gui_guide.md)

- **Mesh Deduplication**: When editing a map or scene, any unique mesh must be extracted and saved as an external `.tres` or `.res` resource file. Do not duplicate inline mesh data inside `.tscn` files. All nodes using the same mesh must load the exact same external resource file.

- **Group Names**: Use the `Groups` constants (e.g., `Groups.PLAYERS`) to access groups. Avoid using strings.

- **Signals strictly by code**: All signals must be connected dynamically by code. Never connect signals via the Godot Editor Inspector (the Node dock).
- - Always emit signals using `my_signal.emit()` syntax.

- **No Deprecated Methods**: Avoid using deprecated methods or paradigms from older Godot versions. Always use the latest equivalents.

- **Inheritance and `_ready()` (Template Method Pattern)**: Avoid requiring `super._ready()` (if you override in children's ready, it will ignore parent's ready). If you need strict control over initialization order, define an abstract virtual method like `@abstract func _entity_ready()` in the parent, and call it inside the parent's `_ready()`, and have the extended child override `_entity_ready()` instead of `_ready()`.

- **Code Regions**: Use Godot's `#region Region Name` and `#endregion` tags to logically group together long blocks of related functions or variables where it makes sense.

- **Component/Resource Icons**: Use `@icon("res://icons/16x16/x.png")` for components and resources to make them explicitly identifiable in Godot's Scene tree and FileSystem.

- **Scene Unique Nodes (`%`)**: For components that represent core functionality of a scene (like `Hitbox`, `Hurtbox`, `StatusManager`, or main UI containers), set and use them as unique.

- **UID Preloading**: When preloading assets, use `UID` with comment(`preload("uid://abcdef") # asset.wav`) instead of path. (You can also hover over uid to see path)

- **Strict Assertions over Silent Failures**: When a script depends on another, avoid silent validations like `if has_node("...")` or `if node:`. Use `assert(value != null, "Error message")` or `assert(has_node("..."))`.

Other recommended approaches
----------------------------

- When changing the meaning of a game setting in a major way that is
  incompatible with previous values, the updated setting should use a
  different name when saved in JSON to avoid problems. For example:
  `[JsonProperty(PropertyName = "MaxSpawnedEntitiesV2")]`. This way
  the options menu doesn't need complicated adapting logic as
  otherwise it would show misleading values to the player.

Other files
-----------

- Do not use `<br>` in markdown unless it is a table where line breaks
  need to be tightly controlled. Use two blank lines (spaces) instead of
  `<br>`. Also use `---` instead of `<hr>`.

Gameplay changes
----------------

When doing changes that impact existing gameplay or add new gameplay
additional considerations regarding playability and understandability
need to be taken into account.

- When changing an existing mechanic that has tutorials, tooltips, help
  menu entries or other explanations, you must also update those texts
  so that how we explain the game to the player doesn't get out of sync.
  This is because if a gameplay changing PR is accepted it may take multiple
  months for anyone to bother to update the help text meanwhile players don't
  know about the new mechanics.

- For new gameplay features it is recommended but not mandatory to write
  new help text or tutorials to explain them.
