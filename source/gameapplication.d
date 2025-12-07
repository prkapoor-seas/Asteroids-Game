import std.stdio, std.string;
import bindbc.sdl;
import sdl_abstraction,  gameobject, scenescript;
import component;
import std.conv;
import std.math;
import std.array;
import std.random;
import std.json;
import std.algorithm;

struct TreeNode{

	GameObject obj;
	TreeNode*[] children;

	this(GameObject object){
		obj = object;
	}

	void addChild(TreeNode* child){
		children ~= child;
	}

	void update(){
		obj.Update();

		foreach(child; children){
			child.update();
		}
	}

}


struct SceneTree{

	TreeNode* root;



	this(TreeNode* r){
		root = r;
	}

	void update(){
		root.update();
	}

}

struct AppState{
	int framesPassed;
	double angle;
	int score;
}


struct Scene{

	SceneTree tree;
	AppState gameState;
	SceneScript sceneScript;
	SDL_Renderer* mRenderer;

	this(SceneTree st, SDL_Renderer* rend){
		tree = st;
		mRenderer = rend;
		gameState.framesPassed = 0;
		gameState.angle = 0;
		gameState.score = 0;
	}

	void setScript(SceneScript script){
		sceneScript = script;
	}

	void Input(){
		sceneScript.Input();
	}

	void Update(){
		sceneScript.Update();
	}

	void Render(){
		sceneScript.Render();
	}

}

struct Image{

  SDL_Texture* mTexture;

}

struct Audio{

  SDL_AudioStream* mStream;
  SDL_AudioSpec mAudioSpec;
  ubyte*        mWaveData;
  uint          mWaveDataLength;

}

struct ResourceManager{

  Image* LoadImageResource(string filename){

    if(filename in mImageResourceMap){
      return mImageResourceMap[filename];
    }else{
      SDL_Surface* surface = SDL_LoadBMP(filename.toStringz);
      SDL_Texture* texture = SDL_CreateTextureFromSurface(mRenderer,surface);
      SDL_DestroySurface(surface);

      Image* image = new Image;
      image.mTexture = texture;

      mImageResourceMap[filename] = image;

      return image;
    }

  }

  Audio* LoadAudioResource(string filename){

    if(filename in mAudioResourceMap){
      return mAudioResourceMap[filename];
    }else{

      Audio* audio = new Audio;
      SDL_LoadWAV(filename.toStringz,&audio.mAudioSpec, &audio.mWaveData, &audio.mWaveDataLength);
      audio.mStream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &audio.mAudioSpec, null, null);

      mAudioResourceMap[filename] = audio;

      return audio;
    }

  }

  void setRenderer(SDL_Renderer* renderer){

    mRenderer = renderer;

  }


  private:
  Image*[string] mImageResourceMap;
  Audio*[string] mAudioResourceMap;
  SDL_Renderer* mRenderer;

}


struct GameAppState{
		ResourceManager* mManager = new ResourceManager;
		bool mGameIsRunning = false;
		bool mShutScreen = false;
}


struct GameApplication{

		/// Arguments for initial program launch
		string[] 			mArgs;
		SDL_Window* 	mWindow ;
		GameAppState mGAppState;
		SDL_Renderer* mRenderer;

		Scene firstScene;
		Scene secondScene;
		Scene currentScene;

		JSONValue j;


		GameObject[] createAsteroids(GameObject ship, GameObject world, JSONValue j){

					string asteroidBitmapSrc = j["Scene"]["Sprites"]["asteroid"].str;
					auto obj = j["Scene"]["GameObjects"]["asteroid"].object;

					int num = cast(int) obj["num"].integer;
					int w = cast(int) obj["width"].integer;
					int h = cast(int) obj["height"].integer;

					int x1_lower = cast(int) obj["lower_x1"].integer;
					int x1_upper = cast(int) obj["upper_x1"].integer;

					int x2_lower = cast(int) obj["lower_x2"].integer;
					int x2_upper = cast(int) obj["upper_x2"].integer;

					int y1_lower = cast(int) obj["lower_y1"].integer;
					int y1_upper = cast(int) obj["upper_y1"].integer;

					int y2_lower = cast(int) obj["lower_y2"].integer;
					int y2_upper = cast(int) obj["upper_y2"].integer;

					auto l = obj["initial_transform"].array;

					string animationFile = j["Scene"]["AnimationData"]["asteroid"].str;

					GameObject[] asteroids = new GameObject[num];
					for(int i = 0; i < asteroids.length; i++){
						asteroids[i] = GameObject("asteroid");

						Image* image = mGAppState.mManager.LoadImageResource(asteroidBitmapSrc);
		        IComponent texture = new ComponentTexture(asteroids[i], mRenderer, image.mTexture);
						asteroids[i].AddComponent!(ComponentType.TEXTURE)(texture);

						ComponentCollision sc = cast(ComponentCollision) ship.GetComponent(ComponentType.COLLISION);
						ComponentCollision wc = cast(ComponentCollision) world.GetComponent(ComponentType.COLLISION);

						auto x1 = wc.GetmRectangle().x;
						auto y1 = wc.GetmRectangle().y;


						if(i == 0){

								auto x = uniform(x1+x1_lower, x1+x1_upper);
		            auto y = uniform(y1+y1_lower, y1+ y1_upper);
								IComponent coll= new ComponentCollision(asteroids[i], x, y, w, h);
								IComponent transform = new ComponentTransform(asteroids[i], cast(float)l[0].integer, cast(float)l[1].integer, cast(float)l[2].integer , cast(float)l[3].integer);
								asteroids[i].AddComponent!(ComponentType.COLLISION)(coll);
								asteroids[i].AddComponent!(ComponentType.TRANSFORM)(transform);

								IComponent animationComponent = new AnimatedTextureComponent(asteroids[i], mRenderer, animationFile);
								asteroids[i].AddComponent!(ComponentType.TEXTURE_ANIMATED)(animationComponent);


								// Calculate the angle between the asteroid and the ship

								double ang = atan2(cast(float) sc.GetmRectangle().x-x, cast(float)y-sc.GetmRectangle().y);
								ComponentCollision c = cast(ComponentCollision) coll;
								AsteroidScript as = new AsteroidScript(asteroids[i], ang, &c.GetmRectangle());
								asteroids[i].AddScript(as);
						} else if(i == 1){
								auto x = uniform(x1+x2_lower, x1+x2_upper);
								auto y = uniform(y1+y1_lower, y1+y1_upper);
								IComponent coll = new ComponentCollision(asteroids[i], x, y, w, h);
								IComponent transform = new ComponentTransform(asteroids[i], cast(float)l[0].integer, cast(float)l[1].integer, cast(float)l[2].integer , cast(float)l[3].integer);
								asteroids[i].AddComponent!(ComponentType.TRANSFORM)(transform);
								asteroids[i].AddComponent!(ComponentType.COLLISION)(coll);

								IComponent animationComponent = new AnimatedTextureComponent(asteroids[i], mRenderer, animationFile);
								asteroids[i].AddComponent!(ComponentType.TEXTURE_ANIMATED)(animationComponent);


								double ang = atan2(cast(float) sc.GetmRectangle().x-x, cast(float)y-sc.GetmRectangle().y);
								ComponentCollision c = cast(ComponentCollision) coll;
								AsteroidScript as = new AsteroidScript(asteroids[i], ang, &c.GetmRectangle());
								asteroids[i].AddScript(as);
						} else if(i == 2){
								auto x = uniform(x1+x1_lower, x1+x1_upper);
								auto y = uniform(y1+y2_lower, y1+y2_upper);
								IComponent coll = new ComponentCollision(asteroids[i], x, y, w, h);
								IComponent transform = new ComponentTransform(asteroids[i], cast(float)l[0].integer, cast(float)l[1].integer, cast(float)l[2].integer , cast(float)l[3].integer);
								asteroids[i].AddComponent!(ComponentType.COLLISION)(coll);
								asteroids[i].AddComponent!(ComponentType.TRANSFORM)(transform);

								IComponent animationComponent = new AnimatedTextureComponent(asteroids[i], mRenderer, animationFile);
								asteroids[i].AddComponent!(ComponentType.TEXTURE_ANIMATED)(animationComponent);

								// Calculate the angle between the asteroid and the ship
								double ang = atan2(cast(float) sc.GetmRectangle().x-x, cast(float)y-sc.GetmRectangle().y);

								ComponentCollision c = cast(ComponentCollision) coll;
								AsteroidScript as = new AsteroidScript(asteroids[i], ang, &c.GetmRectangle());
								asteroids[i].AddScript(as);
						} else{
							auto x = uniform(x1+x2_lower, x1+x2_upper);
							auto y = uniform(y1+y2_lower, y1+y2_upper);
							IComponent coll = new ComponentCollision(asteroids[i], x, y, w, h);
							IComponent transform = new ComponentTransform(asteroids[i], cast(float)l[0].integer, cast(float)l[1].integer, cast(float)l[2].integer , cast(float)l[3].integer);
							asteroids[i].AddComponent!(ComponentType.COLLISION)(coll);
							asteroids[i].AddComponent!(ComponentType.TRANSFORM)(transform);

							IComponent animationComponent = new AnimatedTextureComponent(asteroids[i], mRenderer, animationFile);
							asteroids[i].AddComponent!(ComponentType.TEXTURE_ANIMATED)(animationComponent);

							// Calculate the angle between the asteroid and the ship

							double ang = atan2(cast(float) sc.GetmRectangle().x-x, cast(float)y-sc.GetmRectangle().y);
							ComponentCollision c = cast(ComponentCollision) coll;
							AsteroidScript as = new AsteroidScript(asteroids[i], ang, &c.GetmRectangle());
							asteroids[i].AddScript(as);
						}
					}
					return asteroids;
		}

		GameObject createShip(JSONValue j){

			GameObject ship =  GameObject("ship");

			string shipBitmapSrc = j["Scene"]["Sprites"]["ship"].str;
			auto obj = j["Scene"]["GameObjects"]["ship"].object;

			int x = cast(int) obj["initial_x"].integer;
			int y = cast(int) obj["initial_y"].integer;
			int w = cast(int) obj["width"].integer;
			int h = cast(int) obj["height"].integer;
			auto l = obj["initial_transform"].array;
			string animationFile = j["Scene"]["AnimationData"]["ship"].str;

			Image* image = mGAppState.mManager.LoadImageResource(shipBitmapSrc);
			IComponent texture = new ComponentTexture(ship, mRenderer, image.mTexture);
			IComponent collision = new ComponentCollision(ship, x, y, w, h);
			ship.AddComponent!(ComponentType.TEXTURE)(texture);
			ship.AddComponent!(ComponentType.COLLISION)(collision);
			IComponent st = new ComponentTransform(ship, cast(float)l[0].integer, cast(float)l[1].integer, cast(float)l[2].integer , cast(float)l[3].integer);

			ComponentCollision sc = cast(ComponentCollision) collision;
			ship.AddComponent!(ComponentType.TRANSFORM)(st);
			IComponent animationComponent = new AnimatedTextureComponent(ship, mRenderer, animationFile);
			ship.AddComponent!(ComponentType.TEXTURE_ANIMATED)(animationComponent);
			ShipScript ss = new ShipScript(ship, 0, &sc.GetmRectangle(), false);
			ship.AddScript(ss);

			return ship;
		}

		Scene createFirstScene(JSONValue j){

				GameObject world = GameObject("world"); // This is the camera

				auto obj = j["Scene"]["GameObjects"]["world"].object;
				auto worldX = cast(int) obj["initial_x"].integer;
				auto worldY = cast(int) obj["initial_y"].integer;
				auto worldWidth = cast(int) obj["width"].integer;
				auto worldHeight = cast(int) obj["height"].integer;

				IComponent collision = new ComponentCollision(world, worldX, worldY, worldWidth, worldHeight);
				world.AddComponent!(ComponentType.COLLISION)(collision);

				GameObject ship = createShip(j);
				ComponentCollision wc = cast(ComponentCollision) collision;
				ComponentCollision sc = cast(ComponentCollision) ship.GetComponent(ComponentType.COLLISION);
				ScriptComponent wScript = new WorldScript(world, &wc.GetmRectangle(), &sc.GetmRectangle(), false);
				world.AddScript(wScript);

				TreeNode* root = new TreeNode(world);
				TreeNode* shipNode = new TreeNode(ship);
				root.addChild(shipNode);

				GameObject[] asteroids = createAsteroids(ship, world, j);
				foreach(asteroid; asteroids){
					TreeNode* astNode = new TreeNode(asteroid);
					root.addChild(astNode);
				}

				SceneTree tree =  SceneTree(root);
				Scene scene = Scene(tree, mRenderer);

				return scene;

		}

		Scene createSecondScene(){

			GameObject world = GameObject("world");
			TreeNode* root = new TreeNode(world);

			SceneTree tree =  SceneTree(root);
			Scene scene = Scene(tree, mRenderer);

			return scene;

		}


    this(string[] args){

			string mFilename = args[1];
			auto myFile = File(mFilename, "r");
			auto jsonFileContents = myFile.byLine.joiner("\n");

			// You can then parse the jSON contents
			j=parseJSON(jsonFileContents);

			auto title = j["title"].str;
			auto windowSize = j["WindowSize"].array;

      mWindow = SDL_CreateWindow(title.toStringz, cast(int) windowSize[0].integer, cast(int) windowSize[1].integer, SDL_WINDOW_ALWAYS_ON_TOP);

      // Create a hardware accelerated mRenderer
      mRenderer = SDL_CreateRenderer(mWindow,null);
			mGAppState.mManager.setRenderer(mRenderer);

			// First create the first scene
			firstScene = createFirstScene(j);
			SceneScript script = new GameSceneScript(firstScene.tree, &firstScene.gameState, mRenderer, &mGAppState, j);
			firstScene.setScript(script);

			// Create the second scene
			secondScene = createSecondScene();
			string[] options = [ "New Game", "Quit"];
			SceneScript menuScript = new MenuScript(mRenderer, options, &mGAppState);
			secondScene.setScript(menuScript);
			currentScene = secondScene;


    }

		void Input(){
			currentScene.sceneScript.Input();
		}

		void Update(){
			currentScene.sceneScript.Update();
			if(mGAppState.mGameIsRunning && currentScene == secondScene){
				currentScene = firstScene;
			}
			if(!mGAppState.mGameIsRunning){
				currentScene = secondScene;
				firstScene = createFirstScene(j);
				SceneScript script = new GameSceneScript(firstScene.tree, &firstScene.gameState, mRenderer, &mGAppState, j);
				firstScene.setScript(script);
			}
		}

		void Render(){
			currentScene.sceneScript.Render();
		}



    // Advance world one frame at a time
    void AdvanceFrame(){
        Input();
        Update();
        Render();
    }


    // Run Loop
    void RunLoop(){
      auto previous = SDL_GetTicks();
      auto accumulatedTime = 0;
      auto framesCompleted = 0;
      while(!mGAppState.mShutScreen){
          AdvanceFrame();
          auto elapsed =  SDL_GetTicks() - previous;
          const int targetFrame = 1000 / 60;
          long delay = targetFrame - elapsed;
          if(delay > 0){
             SDL_Delay(cast(uint)delay);
          }
          accumulatedTime += SDL_GetTicks() - previous;
          previous = SDL_GetTicks();
          framesCompleted++;
          if(accumulatedTime > 1000){
            string framerate = "Framerate is: " ~framesCompleted.to!string;
            SDL_SetWindowTitle(mWindow, framerate.toStringz);
            accumulatedTime = 0;
            framesCompleted = 0;
          }
      }

    }

}
