# BlackRoad OS Language (`.road`) Specification

## 🌌 Vision
**A programming language designed by machines for machines** - combining the elegance of Python, safety of Rust, performance of C++, concurrency of Go, and visual power of 3D HTML.

## 🎯 Core Principles
1. **Machine-First**: Optimized for AI parsing, generation, and understanding
2. **Radical Simplicity**: If it's not essential, it doesn't exist
3. **3D Native**: First-class support for spatial/visual programming
4. **Type-Safe**: Catch errors before runtime (Rust/Ada/TypeScript influence)
5. **Multi-Paradigm**: Declarative, imperative, functional, spatial
6. **Zero Ambiguity**: One obvious way to do things

## 🔤 File Extension
- `.road` - BlackRoad source files
- `.road3d` - BlackRoad 3D scene files
- `.roadpkg` - BlackRoad package manifests

## 📝 Basic Syntax

### Comments
```road
# Single-line comment
## Documentation comment (appears in generated docs)

#[
Multi-line comment
Like this!
]#
```

### Variables & Types
```road
# Type inference (Python-style simplicity)
let x = 42                    # int
let name = "BlackRoad"        # string
let pi = 3.14159             # float
let active = true            # bool

# Explicit types (TypeScript/Rust-style safety)
let count: int = 100
let speed: float = 9.81
let users: list[string] = ["Alice", "Bob"]
let config: dict[string, any] = {
    "port": 8080,
    "host": "localhost"
}

# Constants (immutable by default - Rust influence)
const MAX_USERS: int = 1000
const API_KEY: string = "secret"

# Mutable variables (explicit opt-in)
var counter: int = 0
counter = counter + 1
```

### Primitive Types
```road
int        # 64-bit integer
float      # 64-bit floating point
string     # UTF-8 string
bool       # true/false
byte       # 8-bit unsigned
char       # Unicode character
vec2       # 2D vector [x, y]
vec3       # 3D vector [x, y, z]
vec4       # 4D vector [x, y, z, w]
color      # RGBA color #FF1D6C or rgba(255, 29, 108, 1.0)
```

### Functions
```road
# Simple function (Python-style)
fun greet(name: string) -> string:
    return "Hello, {name}!"

# Multi-line function
fun calculate(a: int, b: int) -> int:
    let result = a * b
    return result

# Anonymous functions (lambdas)
let add = (x: int, y: int) -> x + y
let double = (x: int) -> x * 2

# Default parameters
fun connect(host: string, port: int = 8080) -> bool:
    return true

# Variadic parameters (Go-style)
fun sum(numbers: ...int) -> int:
    var total = 0
    for n in numbers:
        total = total + n
    return total
```

### Control Flow
```road
# If/else (Python-style indentation)
if x > 10:
    print("Large")
elif x > 5:
    print("Medium")
else:
    print("Small")

# Pattern matching (Rust-style)
match status:
    200 -> print("OK")
    404 -> print("Not Found")
    500..599 -> print("Server Error")
    _ -> print("Unknown")

# Loops
for i in 0..10:           # Range
    print(i)

for item in items:         # Iterator
    print(item)

while condition:
    process()

# Loop control
for i in 0..100:
    if i == 50:
        break
    if i % 2 == 0:
        continue
    print(i)
```

### Data Structures
```road
# Lists (dynamic arrays)
let numbers: list[int] = [1, 2, 3, 4, 5]
numbers.push(6)
numbers.pop()
let first = numbers[0]

# Dictionaries (hash maps)
let user: dict[string, any] = {
    "name": "Alexa",
    "age": 25,
    "active": true
}
user["email"] = "alexa@blackroad.io"

# Sets
let unique: set[int] = {1, 2, 3, 4, 5}
unique.add(6)
unique.remove(1)

# Tuples
let point: (float, float) = (3.14, 2.71)
let (x, y) = point  # Destructuring
```

### Custom Types
```road
# Struct types (C++/Rust-style)
type User:
    name: string
    email: string
    age: int
    verified: bool = false  # Default value

# Instantiation
let user = User{
    name: "Alexa",
    email: "alexa@blackroad.io",
    age: 25
}

# Access
print(user.name)
user.verified = true

# Enum types (Rust-style)
type Status:
    | Pending
    | Active(user_id: int)
    | Suspended(reason: string)
    | Deleted

let status = Status.Active(user_id: 123)

match status:
    Status.Pending -> print("Waiting")
    Status.Active(id) -> print("User {id} is active")
    Status.Suspended(reason) -> print("Suspended: {reason}")
    Status.Deleted -> print("Deleted")
```

## 🌐 3D/Spatial Programming (The Revolutionary Part!)

### 3D Objects & Scenes
```road
# Define 3D space
space MyScene:
    ## Main scene container

    # Cube object
    cube Box1:
        position: vec3(0, 0, 0)
        rotation: vec3(0, 45, 0)  # Euler angles
        scale: vec3(1, 1, 1)
        color: #FF1D6C  # BlackRoad Hot Pink!
        material: {
            "metalness": 0.5,
            "roughness": 0.3
        }

    # Sphere
    sphere Ball:
        position: vec3(2, 1, 0)
        radius: 0.5
        color: #F5A623  # BlackRoad Amber
        physics: {
            "mass": 1.0,
            "gravity": true
        }

    # Light
    light Sun:
        type: directional
        position: vec3(5, 10, 5)
        color: #FFFFFF
        intensity: 1.0
        shadows: true

    # Camera
    camera MainCam:
        position: vec3(0, 2, 5)
        lookAt: vec3(0, 0, 0)
        fov: 75
        near: 0.1
        far: 1000

# 3D transformations
fun animate(obj: cube, time: float):
    obj.position.y = sin(time) * 2
    obj.rotation.y = time * 45

# Render scene
render(MyScene, camera: MainCam)
```

### HTML-like 3D Markup
```road
# 3D HTML syntax (alternative declarative style)
<space id="game-world">
    <cube id="player" pos="[0,0,0]" color="#FF1D6C">
        <physics mass="1.0" gravity="true" />
        <script>
            fun onCollision(other: object):
                print("Hit {other.id}!")
        </script>
    </cube>

    <plane id="ground" pos="[0,-1,0]" size="[100,100]" color="#333">
        <texture src="ground.png" />
    </plane>

    <light type="point" pos="[0,5,0]" color="#FFF" intensity="2.0" />
</space>
```

## ⚡ Concurrency & Async (Go/Rust-style)

### Async Functions
```road
# Async function
async fun fetchUser(id: int) -> User:
    let response = await http.get("/api/users/{id}")
    return response.json()

# Using async
fun main():
    let user = await fetchUser(123)
    print(user.name)

# Parallel execution
async fun loadAll():
    let [users, posts, comments] = await parallel(
        fetchUsers(),
        fetchPosts(),
        fetchComments()
    )
    return (users, posts, comments)
```

### Channels & Goroutines (Go-style)
```road
# Create channel
let ch: chan[int] = channel()

# Spawn concurrent task
spawn:
    for i in 0..10:
        ch.send(i)
        sleep(100)
    ch.close()

# Receive from channel
for value in ch:
    print("Received: {value}")

# Select statement (Go-style)
select:
    case msg = <-ch1:
        print("From ch1: {msg}")
    case msg = <-ch2:
        print("From ch2: {msg}")
    case timeout(1000):
        print("Timed out!")
```

## 🔐 Memory Safety (Rust-style ownership)

### Ownership & Borrowing
```road
# Ownership transfer
let data = [1, 2, 3, 4, 5]
let moved = data          # data is now invalid
# print(data)             # ERROR: value moved

# Borrowing (read-only reference)
fun printLen(arr: &list[int]):
    print("Length: {arr.len()}")

let data = [1, 2, 3]
printLen(&data)           # Borrow
print(data)               # Still valid!

# Mutable borrowing
fun double(arr: &mut list[int]):
    for i in 0..arr.len():
        arr[i] = arr[i] * 2

var numbers = [1, 2, 3]
double(&mut numbers)
print(numbers)            # [2, 4, 6]
```

## 🧩 Modules & Packages

### Module System
```road
# File: math.road
module math

## Calculate factorial
export fun factorial(n: int) -> int:
    if n <= 1:
        return 1
    return n * factorial(n - 1)

## Calculate fibonacci
export fun fibonacci(n: int) -> int:
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

# Private function (not exported)
fun helper():
    return 42
```

### Imports
```road
# Import module
import math
let result = math.factorial(5)

# Import specific items
from math import factorial, fibonacci
let f = factorial(10)

# Import with alias
import http as network
let response = network.get("https://api.blackroad.io")

# Import all (use sparingly)
from math import *
```

### Package Manifest (`.roadpkg`)
```yaml
# package.roadpkg
name: blackroad-engine
version: 1.0.0
author: BlackRoad OS, Inc.
license: Proprietary

dependencies:
  - graphics: ^2.0.0
  - physics: ^1.5.0
  - networking: ^3.0.0

scripts:
  build: roadc build --release
  test: roadc test
  run: roadc run main.road

entry: src/main.road
```

## 🛠️ Standard Library

### Core Modules
```road
import std.io         # Input/output
import std.math       # Mathematics
import std.string     # String operations
import std.time       # Date/time
import std.http       # HTTP client/server
import std.json       # JSON parsing
import std.crypto     # Cryptography
import std.fs         # File system
import std.process    # Process management
import std.thread     # Threading
import std.gpu        # GPU compute (CUDA/WebGPU)

# 3D/Graphics
import std.3d         # 3D primitives
import std.render     # Rendering engine
import std.physics    # Physics engine
import std.audio      # Audio processing

# AI/ML
import std.ml         # Machine learning
import std.neural     # Neural networks
import std.vision     # Computer vision
import std.nlp        # Natural language processing
```

## 🔧 Inline Assembly (Low-level when needed)

```road
# Inline assembly for performance-critical code
fun fastMultiply(a: int, b: int) -> int:
    var result: int
    asm:
        mov rax, {a}
        imul rax, {b}
        mov {result}, rax
    return result
```

## 🎨 Metaprogramming & Macros

### Compile-time Code Generation
```road
# Macro definition
macro repeat(count: int, body: code):
    for i in 0..count:
        @eval(body)

# Usage
repeat(5):
    print("Hello!")

# Compile-time function
comptime fun generateGetters(type: Type) -> code:
    var code = ""
    for field in type.fields:
        code += "fun get_{field.name}(self: {type.name}) -> {field.type}:\n"
        code += "    return self.{field.name}\n"
    return @code(code)

type User:
    name: string
    age: int

@generateGetters(User)
# Generates:
# fun get_name(self: User) -> string:
#     return self.name
# fun get_age(self: User) -> int:
#     return self.age
```

## 🚀 Example: Complete 3D Game
```road
## BlackRoad 3D Space Shooter
module game

import std.3d
import std.input
import std.audio
import std.physics

# Game state
type GameState:
    score: int
    lives: int
    level: int

var state = GameState{score: 0, lives: 3, level: 1}

# 3D Scene
space GameWorld:
    # Player ship
    cube Player:
        position: vec3(0, 0, 0)
        scale: vec3(0.5, 0.5, 1.0)
        color: #FF1D6C  # Hot Pink
        physics: {
            "mass": 1.0,
            "drag": 0.95
        }

    # Enemy spawner
    script EnemySpawner:
        var spawnTimer: float = 0

        fun update(delta: float):
            spawnTimer += delta
            if spawnTimer > 2.0:
                spawnEnemy()
                spawnTimer = 0

    # Lighting
    light MainLight:
        type: point
        position: vec3(0, 10, 0)
        color: #FFFFFF
        intensity: 2.0

    # Camera
    camera MainCam:
        position: vec3(0, 5, 10)
        lookAt: vec3(0, 0, 0)
        fov: 60

# Enemy spawning
fun spawnEnemy():
    let x = random(-5.0, 5.0)
    let enemy = spawn cube:
        position: vec3(x, 0, -10)
        color: #F5A623  # Amber
        velocity: vec3(0, 0, 2.0)
        tag: "enemy"

# Player input
fun handleInput(delta: float):
    let player = GameWorld.Player

    if input.key(Key.Left):
        player.position.x -= 5.0 * delta
    if input.key(Key.Right):
        player.position.x += 5.0 * delta
    if input.key(Key.Space):
        shoot()

# Shooting
fun shoot():
    let player = GameWorld.Player
    let bullet = spawn sphere:
        position: player.position + vec3(0, 0, -1)
        radius: 0.1
        color: #2979FF  # Electric Blue
        velocity: vec3(0, 0, -20.0)
        tag: "bullet"

    audio.play("shoot.wav")

# Collision detection
fun onCollision(a: object, b: object):
    if a.tag == "bullet" and b.tag == "enemy":
        destroy(a)
        destroy(b)
        state.score += 100
        audio.play("explosion.wav")

    if a.tag == "enemy" and b.tag == "Player":
        state.lives -= 1
        destroy(a)
        if state.lives <= 0:
            gameOver()

# Game loop
fun main():
    # Initialize
    audio.load("shoot.wav")
    audio.load("explosion.wav")

    # Main loop
    while true:
        let delta = time.deltaTime()

        handleInput(delta)
        physics.update(delta)
        render(GameWorld, camera: MainCam)

        # UI overlay
        ui.text("Score: {state.score}", pos: vec2(10, 10))
        ui.text("Lives: {state.lives}", pos: vec2(10, 40))
```

## 📊 Type System Summary

### Type Hierarchy
```
any                    # Top type (all types)
├─ primitive
│  ├─ int
│  ├─ float
│  ├─ bool
│  ├─ char
│  └─ byte
├─ string
├─ vector
│  ├─ vec2
│  ├─ vec3
│  └─ vec4
├─ color
├─ collection
│  ├─ list[T]
│  ├─ dict[K, V]
│  ├─ set[T]
│  └─ tuple(...)
├─ function
│  └─ (Args...) -> Return
├─ object
│  ├─ cube
│  ├─ sphere
│  ├─ plane
│  ├─ light
│  └─ camera
└─ never              # Bottom type (no values)
```

## 🏗️ Compiler Architecture

### Build Process
```bash
# Compile to native binary
roadc build main.road --output app

# Compile to WebAssembly
roadc build main.road --target wasm

# Compile to JavaScript
roadc build main.road --target js

# JIT compilation
roadc run main.road

# REPL
roadc repl
```

### Compilation Stages
1. **Lexer**: Source → Tokens
2. **Parser**: Tokens → AST (Abstract Syntax Tree)
3. **Semantic Analysis**: Type checking, name resolution
4. **IR Generation**: AST → Intermediate Representation
5. **Optimization**: IR → Optimized IR (LLVM-style)
6. **Code Generation**: IR → Target (native/WASM/JS)

## 🎯 Design Goals Achieved

| Feature | Inspired By | Status |
|---------|-------------|--------|
| Simple syntax | Python | ✅ |
| Type safety | Rust, TypeScript, Ada | ✅ |
| Performance | C++, Rust, Go | ✅ |
| Memory safety | Rust | ✅ |
| Concurrency | Go | ✅ |
| 3D native | THREE.js, Unity | ✅ |
| Pattern matching | Rust | ✅ |
| Low-level control | C++, Assembly | ✅ |
| Package management | Cargo, npm | ✅ |
| Metaprogramming | Rust, Lisp | ✅ |
| Machine-friendly | YAML, JSON | ✅ |

## 🌌 Philosophy

> **"Code should be a conversation between humans and machines, not a monologue."**

BlackRoad OS Language is designed to be:
- **Readable** by humans
- **Parseable** by AI
- **Performant** on metal
- **Beautiful** in structure
- **Powerful** in capability

---

**BlackRoad OS Language** - Where code meets the 3rd dimension. 🖤🛣️
