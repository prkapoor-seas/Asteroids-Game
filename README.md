# 🚀 Asteroids — Modern Remake (D Language + SDL3)

<video src="Asteroids.mp4" controls width="600"></video>

A modern re-implementation of the classic **1979 Asteroids arcade game**, built from scratch using the **D Programming Language**, **SDL3**, and a fully custom game engine.  
This project demonstrates game architecture, rendering, resource management, scene systems, and real-time gameplay programming.

---

## 🎯 Features

### 🛠 Custom Game Engine
- **60 FPS frame-capped main loop**
- **deltaTime-based** frame-independent movement
- **Scene Tree / Scene Graph** architecture  
  - Supports multiple scenes (Main Menu, Level 1, etc.)
  - Scenes can be swapped at runtime
- **Resource Manager** for textures, sprite sheets, JSON, and audio
- **JSON-driven sprite animation**
- **Camera system** separating world space from screen space
- Player-following camera for a large scrolling world

### 🎮 Core Gameplay
- **Player Ship**
  - Rotation, thrust movement, acceleration
  - Projectile firing in facing direction
- **Asteroids**
  - Free-floating randomized movement
  - Collision detection and destruction
- **Large World**
  - World larger than the view window (e.g., 1000×1000)
  - Camera centers on the ship as it moves
- **Score Display**
  - Bitmap or SDL_TTF-based
- **Audio Integration**
  - Includes at least one sound effect

---

## 📁 Project Structure

```
Asteroids-Game-/
│
├── source/                # D source code
├── assets/                # Sprites, images, audio
├── resources.json         # Resource manifest loaded at startup
├── dub.json               # DUB build configuration
├── README.md              # This file
└── media/
└── Asteroids.mp4          # Gameplay demo video
```


---

## ⚙️ Build & Run

### Requirements
- D compiler (`ldc2`)
- SDL3 (via bindbc-sdl)
- DUB build tool

### Run the game

```
dub -- "resources.json"
```
---

## 🧪 Technical Highlights

- Modular **game engine design** using modern D constructs  
- Resource loading + caching system  
- JSON-based animation loading (frame timing, sequences, offsets)  
- Physics-inspired movement using velocity + acceleration vectors  
- Camera system following the ship across a large world  
- SDL3 subsystems for graphics, input, and audio

---

## 👤 Author

**Pranay Raj Kapoor**  
Game Developer • Software Engineer  

LinkedIn: https://www.linkedin.com/in/pranay-raj-kapoor-180974242/


