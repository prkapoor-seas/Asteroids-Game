🚀 Asteroids — Modern Remake (D Language + SDL3)

<video src="Asteroids.mp4" controls width="600"></video>

A modern re-implementation of the classic 1979 Asteroids arcade game, built from scratch using the D Programming Language, SDL3, and a fully custom game engine.
This project demonstrates game architecture, rendering, resource management, scene systems, and real-time gameplay programming.

🎯 Features
🛠 Custom Game Engine

60 FPS frame-capped main loop

deltaTime-based frame-independent movement

Scene Tree / Scene Graph architecture

Supports multiple scenes (Main Menu, Level 1, etc.)

Scenes can be swapped at runtime

Resource Manager for all textures, sprite sheets, JSON, and audio

JSON-driven sprite animation

Camera System

World space decoupled from screen space

Camera tracks player

🎮 Core Gameplay

Player Ship

Rotation, thrust movement, acceleration

Fire projectiles in the direction the ship faces

Asteroids

Free-floating movement

Collision detection and destruction

Large Scrollable World

World larger than the window: 1000×1000 space with a centered camera

Score Display

Bitmap or SDL_TTF-based scoring system

Audio Support

Includes at least one sound effect

📁 Project Structure
Asteroids-Game-/
│
├── source/                # D source code
├── assets/                # Sprites, images, audio
├── .resources.json        # Resource manifest (loaded on startup)
├── dub.json               # DUB build config
├── README.md              # Project documentation
└── media/
    └── Asteroids.mp4      # Gameplay video

⚙️ Build & Run
Requirements

D compiler (ldc2)

SDL3 (via bindbc-sdl)

DUB package manager

Run the game
dub -- resources.json

🧪 Technical Highlights

Designed a modular game engine using modern D features

Implemented a reusable resource loading + caching system

Built a JSON animation parser compatible with multiple sprite sheets

Implemented physics-like motion using vectors and acceleration

Created a camera system following player movement in a larger world

Used SDL3 subsystems (rendering, input, audio) idiomatically with D

👤 Author

Pranay Raj Kapoor
Game Developer • Software Engineer

LinkedIn: https://www.linkedin.com/in/pranay-raj-kapoor-180974242/
