import std.stdio, std.string;
import bindbc.sdl;
import sdl_abstraction, gameapplication, gameobject;
import component;
import std.conv;
import std.math;
import std.array;
import std.random;
import std.json;

class SceneScript{

  void Input(){

  }

  void Update(){

  }

  void Render(){

  }

}

class GameSceneScript : SceneScript{

  SceneTree tree;
  AppState* gameState;
  SDL_Renderer* mRenderer;

  GameObject world;
  GameObject ship;
  GameObject[] asteroids;
  GameObject[] shipMissile;

  GameAppState* mGameAppState;

  int[] framesPassed;
  Audio* mAudio;
  Audio* mAudioExplosion;
  JSONValue ja;

  this(SceneTree t, AppState* g, SDL_Renderer* r, GameAppState* mg, JSONValue j){

      tree = t;
      gameState = g;
      mRenderer = r;

      asteroids = [];
      shipMissile = [];
      framesPassed = [];

      mGameAppState = mg;

      // Iterate over the tree to extract the ship, asteroids
      // The root of the tree is the world i.e. Camera
      world = tree.root.obj;

      foreach(child; tree.root.children){

        if(child.obj.mName == "ship"){

          ship = child.obj;

        } else if(child.obj.mName == "asteroid"){
          asteroids ~= child.obj;
          framesPassed ~= [0];
        }

      }

      string explosionSoundSrc = j["Scene"]["AudioData"]["explosion"].str;
      string shootSoundSrc = j["Scene"]["AudioData"]["shoot"].str;
      ja = j;

      mAudio = mGameAppState.mManager.LoadAudioResource(shootSoundSrc);
      mAudioExplosion = mGameAppState.mManager.LoadAudioResource(explosionSoundSrc);


  }

  void ResumeSound(Audio* mA){
    SDL_ResumeAudioStreamDevice(mA.mStream);
  }

  void PlaySound(Audio* mA){
    if(SDL_GetAudioStreamQueued(mA.mStream) < cast(int)mA.mWaveDataLength){
      SDL_PutAudioStreamData(mA.mStream,mA.mWaveData,mA.mWaveDataLength);
    }
  }


  override void Input(){
    SDL_Event event;
    // Start our event loop
    while(SDL_PollEvent(&event)){
        // Handle each specific event
        if(event.type == SDL_EVENT_QUIT){
            mGameAppState.mGameIsRunning= false;
            mGameAppState.mShutScreen = true;
        }
        if(event.type == SDL_EVENT_KEY_DOWN){
          int k = event.key.key;
          if(k == SDLK_A){
            gameState.angle -= 15;

          }
          if(k == SDLK_D){
            gameState.angle += 15;
          }
          if(k == SDLK_W){

            // When w is pressed update the angle to move in the direction
            ShipScript ss = cast(ShipScript) ship.GetScript();
            ss.setAngle(gameState.angle);

            WorldScript ws = cast(WorldScript) world.GetScript();
            ComponentCollision c = cast(ComponentCollision) ship.GetComponent(ComponentType.COLLISION);

            ws.setMove(&c.GetmRectangle());

          }
          if(k == SDLK_SPACE){

              GameObject missile = GameObject("missile");
              string missileBitmapSrc = ja["Scene"]["Sprites"]["missile"].str;
              Image* image = mGameAppState.mManager.LoadImageResource(missileBitmapSrc);
  		        IComponent texture = new ComponentTexture(missile, mRenderer, image.mTexture);
              missile.AddComponent!(ComponentType.TEXTURE)(texture);

              // Calculate the coordinates for the missile
              ComponentCollision c = cast(ComponentCollision) ship.GetComponent(ComponentType.COLLISION);
              SDL_FRect r = c.GetmRectangle();

              float x = r.x + r.w/2.0f;
              float y = r.y + r.h/2.0f;

              double radians = (gameState.angle * PI / 180.0);

              float dx = cast(float) r.h / 2.0f * sin(radians);
              float dy = cast(float)(-(r.h / 2.0f) * cos(radians));

              x = x + dx ;
              y = y + dy ;

              auto obj = ja["Scene"]["GameObjects"]["missile"].object;

              float h = cast(int) obj["height"].integer;
              float w = cast(int) obj["width"].integer;

              float offsetX = -(h / 2.0f) * sin(radians);
              float offsetY = (h / 2.0f) * cos(radians);

              IComponent collision = new ComponentCollision(missile, x +offsetX - w/2, y + offsetY-h/2, w , h);
              missile.AddComponent!(ComponentType.COLLISION)(collision);

              ComponentCollision comp = cast(ComponentCollision) collision;
              MissileScript ms = new MissileScript(missile, gameState.angle, &comp.GetmRectangle());
              missile.AddScript(ms);

              shipMissile ~= missile;

              ResumeSound(mAudio);
              PlaySound(mAudio);

            }
        }
      }
  }

  override void Update(){

    tree.root.update();

    for(int i = 0; i < shipMissile.length; i++){
      shipMissile[i].Update();
    }

    // Check for collision between shipMissile and asteroid
    for(int j = 0; j < shipMissile.length; j++){

      ComponentCollision c = cast(ComponentCollision) shipMissile[j].GetComponent(ComponentType.COLLISION);
      SDL_FRect r = c.GetmRectangle();

      // Check for collision between a shipMissile and an asteroid
      for(int k = 0; k < asteroids.length; k++){

        ComponentCollision ac = cast(ComponentCollision) asteroids[k].GetComponent(ComponentType.COLLISION);
        SDL_FRect ar = ac.GetmRectangle();

        if(asteroids[k].mActive && ar.x - ar.w/2 < r.x && ar.x + ar.w/2 > r.x && ar.y - ar.h/2 < r.y && ar.y + ar.h/2 > r.y ){

          asteroids[k].SetInactive();
          shipMissile[j].SetInactive();
          gameState.framesPassed = 0;
          gameState.score+= 1;

          AnimatedTextureComponent atc = cast(AnimatedTextureComponent) asteroids[k].GetComponent(ComponentType.TEXTURE_ANIMATED);
          atc.LoopAnimationSequence("fire");

          ResumeSound(mAudioExplosion);
          PlaySound(mAudioExplosion);

        }

      }

      // Remove inActive missiles from list of missiles
      if(r.x < 0 || r.x > 1000 || r.y < 0 || r.y > 1000 || !shipMissile[j].mActive ){
        shipMissile = shipMissile[0..j] ~ shipMissile[j+1..$];
        j--;
      }
    }


    // Check for asteroid and ship collisions
    for(int i = 0; i < asteroids.length; i++){

      ComponentCollision ac = cast(ComponentCollision) asteroids[i].GetComponent(ComponentType.COLLISION);
      SDL_FRect ar = ac.GetmRectangle();

      ComponentCollision sc = cast(ComponentCollision) ship.GetComponent(ComponentType.COLLISION);
      SDL_FRect r = sc.GetmRectangle();

      if(asteroids[i].mActive && ar.x - ar.w/2 < r.x && ar.x + ar.w/2 > r.x && ar.y - ar.h/2 < r.y && ar.y + ar.h/2 > r.y ){

        AsteroidScript script = cast(AsteroidScript) asteroids[i].GetScript();
        script.setAngle(PI-script.getAngle());

        ship.SetInactive();

        AnimatedTextureComponent stc = cast(AnimatedTextureComponent) ship.GetComponent(ComponentType.TEXTURE_ANIMATED);
        stc.LoopAnimationSequence("fire");

        ResumeSound(mAudioExplosion);
        PlaySound(mAudioExplosion);

      }

      // For asteroid-asteroid collisions
      for(int j = i+1; j < asteroids.length; j++){

        sc = cast(ComponentCollision) asteroids[j].GetComponent(ComponentType.COLLISION);
        r = sc.GetmRectangle();

        if(asteroids[i].mActive && ar.x - ar.w/2 < r.x && ar.x + ar.w/2 > r.x && ar.y - ar.h/2 < r.y && ar.y + ar.h/2 > r.y ){

          AsteroidScript script = cast(AsteroidScript) asteroids[i].GetScript();
          script.setAngle(PI-script.getAngle());

          AsteroidScript ascript = cast(AsteroidScript) asteroids[j].GetScript();
          ascript.setAngle(PI-ascript.getAngle());

        }


      }

    }

    for(int i = 0 ; i < asteroids.length; i++){
      ComponentCollision ac = cast(ComponentCollision) asteroids[i].GetComponent(ComponentType.COLLISION);
      SDL_FRect ar = ac.GetmRectangle();

      if(ar.x < 0 || ar.x > 1000 || ar.y < 0 || ar.y > 1000 || (!asteroids[i].mActive && framesPassed[i] > 15)){

        /// Get the ship SetPosition
        ComponentCollision sc = cast(ComponentCollision) ship.GetComponent(ComponentType.COLLISION);
        auto x0 = sc.GetmRectangle().x;
        auto y0 = sc.GetmRectangle().y;

        ComponentCollision wc = cast(ComponentCollision) world.GetComponent(ComponentType.COLLISION);
        auto x1 = wc.GetmRectangle().x;
        auto y1 = wc.GetmRectangle().y;

        auto x = x0;
        auto y = y0;

        do{
          // Identify the quadrant
          if(i == 0){
            x = uniform(x1+30, x1+120);
            y = uniform(y1+ 30, y1+ 120);
          } else if(i == 1){
            x = uniform(x1+450, x1+610);
            y = uniform(y1+30, y1+120);
          } else if(i == 2){
            x = uniform(x1+30, x1+120);
            y = uniform(y1+350, y1+450);
          } else{
            x = uniform(x1+450, x1+610);
            y = uniform(y1+350, y1+450);
          }
        }while(x == x0 || y == y0);
        ac.SetPosition(x, y);

        // Set the angle
        double ang = atan2(cast(float) (x0-x) , cast(float) (y-y0));
        AsteroidScript as = cast(AsteroidScript) asteroids[i].GetScript();
        as.setAngle(ang);

        if(!asteroids[i].mActive){

          AnimatedTextureComponent atc = cast(AnimatedTextureComponent) asteroids[i].GetComponent(ComponentType.TEXTURE_ANIMATED);
          atc.LoopAnimationSequence("object");
          asteroids[i].mActive = true;
          framesPassed[i] = 0;
        }

      }
    }

  }

  override void Render(){

    SDL_SetRenderDrawColor(mRenderer, 0, 0, 255, 255);

    SDL_RenderClear(mRenderer);

    // Render the score on top-left
    string ret = "Score " ~ to!string(gameState.score);
    SDL_SetRenderDrawColor(mRenderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
    SDL_SetRenderScale(mRenderer, 1.0f, 1.0f);
    SDL_RenderDebugText(mRenderer, 30, 20, ret.toStringz);

    // Render the time on the top-right
    //auto time = SDL_GetTicks()/1000;
    //string timeElapsed = "Seconds Elapsed: "  ~ to!string(time);
    //SDL_SetRenderScale(mRenderer, 1.0f, 1.0f);
    //SDL_SetRenderDrawColor(mRenderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
    //SDL_RenderDebugText(mRenderer, 430, 20, timeElapsed.toStringz);

    // Get the world camera rectangle
    ComponentCollision wc = cast(ComponentCollision) world.GetComponent(ComponentType.COLLISION);
    SDL_FRect cameraRect = wc.GetmRectangle();


    if(ship.mActive){
      ComponentTexture t = cast(ComponentTexture) ship.GetComponent(ComponentType.TEXTURE);
      ComponentCollision c = cast(ComponentCollision) ship.GetComponent(ComponentType.COLLISION);
      ComponentTransform tr = cast(ComponentTransform) ship.GetComponent(ComponentType.TRANSFORM);

      SDL_FPoint center;
      center.x = (c.GetmRectangle().w) / 2.0f;
      center.y = c.GetmRectangle().h / 2.0f;

      float angle = cast(float) gameState.angle;
      SDL_FRect screenRect;
       screenRect.x = c.GetmRectangle().x - cameraRect.x;
       screenRect.y = c.GetmRectangle().y - cameraRect.y;
       screenRect.w = c.GetmRectangle().w;
       screenRect.h = c.GetmRectangle().h;

      SDL_RenderTextureRotated(mRenderer, t.GetTexture(), & tr.GetmRectangle(), &screenRect, angle, &center, SDL_FLIP_NONE);
    }else{
      ComponentTexture t = cast(ComponentTexture) ship.GetComponent(ComponentType.TEXTURE);
      ComponentCollision c = cast(ComponentCollision) ship.GetComponent(ComponentType.COLLISION);
      ComponentTransform tr = cast(ComponentTransform) ship.GetComponent(ComponentType.TRANSFORM);

       SDL_FRect screenRect;
       screenRect.x = c.GetmRectangle().x - cameraRect.x;
       screenRect.y = c.GetmRectangle().y - cameraRect.y;
       screenRect.w = c.GetmRectangle().w;
       screenRect.h = c.GetmRectangle().h;

      SDL_RenderTexture(mRenderer, t.GetTexture(), &tr.GetmRectangle(), &screenRect);
      gameState.framesPassed += 1;
    }


     for(int i = 0; i < shipMissile.length; i++){
      if(shipMissile[i].mActive){
        ComponentTexture t2 = cast(ComponentTexture) shipMissile[i].GetComponent(ComponentType.TEXTURE);
        ComponentCollision c2 = cast(ComponentCollision) shipMissile[i].GetComponent(ComponentType.COLLISION);
        SDL_FPoint center2;
        center2.x = c2.GetmRectangle().w / 2.0f;
        center2.y = c2.GetmRectangle().h / 2.0f;

        SDL_FRect screenRect;
        screenRect.x = c2.GetmRectangle().x - cameraRect.x;
        screenRect.y = c2.GetmRectangle().y - cameraRect.y;
        screenRect.w = c2.GetmRectangle().w;
        screenRect.h = c2.GetmRectangle().h;


        MissileScript ms = cast(MissileScript) shipMissile[i].GetScript();
        SDL_RenderTextureRotated(mRenderer, t2.GetTexture(), null, &screenRect, ms.getAngle(), &center2, SDL_FLIP_NONE);
      }
    }

    for(int i = 0; i < asteroids.length; i++){

      if(asteroids[i].mActive){
        ComponentTexture t2 = cast(ComponentTexture) asteroids[i].GetComponent(ComponentType.TEXTURE);
        ComponentCollision c2 = cast(ComponentCollision) asteroids[i].GetComponent(ComponentType.COLLISION);
        ComponentTransform tr2 = cast(ComponentTransform) asteroids[i].GetComponent(ComponentType.TRANSFORM);


         SDL_FRect screenRect;
         screenRect.x = c2.GetmRectangle().x - cameraRect.x;
         screenRect.y = c2.GetmRectangle().y - cameraRect.y;
         screenRect.w = c2.GetmRectangle().w;
         screenRect.h = c2.GetmRectangle().h;

        //writeln(i, " ", screenRect.x, " ", screenRect.y);

        SDL_RenderTexture(mRenderer, t2.GetTexture(),&tr2.GetmRectangle(), &screenRect);
      }else{
        ComponentTexture t2 = cast(ComponentTexture) asteroids[i].GetComponent(ComponentType.TEXTURE);
        ComponentCollision c2 = cast(ComponentCollision) asteroids[i].GetComponent(ComponentType.COLLISION);
        ComponentTransform tr2 = cast(ComponentTransform) asteroids[i].GetComponent(ComponentType.TRANSFORM);

        SDL_FRect screenRect;
        screenRect.x = c2.GetmRectangle().x - cameraRect.x;
        screenRect.y = c2.GetmRectangle().y - cameraRect.y;
        screenRect.w = c2.GetmRectangle().w;
        screenRect.h = c2.GetmRectangle().h;



        SDL_RenderTexture(mRenderer, t2.GetTexture(),&tr2.GetmRectangle(), &screenRect);
        framesPassed[i] += 1;
      }

    }

    SDL_RenderPresent(mRenderer);

    if(gameState.framesPassed > 30){
        mGameAppState.mGameIsRunning = false;
    }

  }

}


class MenuScript: SceneScript{

  SDL_Renderer* mRenderer;
  string[] options;
  GameAppState* mGameAppState;
  int selection;
  int length;

  this(SDL_Renderer* r, string[] op, GameAppState* gp){
    mRenderer = r;
    options = op;
    mGameAppState = gp;
    selection = 0;
    length = cast(int)options.length;

  }

  override void Input(){
      SDL_Event event;
    while(SDL_PollEvent(&event)){
        // Handle each specific event
        if(event.type == SDL_EVENT_QUIT){
            mGameAppState.mGameIsRunning= false;
            mGameAppState.mShutScreen = true;
        } else if (event.type  == SDL_EVENT_KEY_DOWN){
          int k = event.key.key;
          if(k == SDLK_DOWN){
            selection = (selection + 1) % length;
          }
          if(k == SDLK_UP){
            selection = (selection - 1 + length) % length;
          }
          if(k == SDLK_RETURN){
            if(options[selection] == "New Game"){
              mGameAppState.mGameIsRunning = true;
            } else{
              mGameAppState.mShutScreen = true;
            }
          }

        }
    }

    }

    override void Update(){

    }

    override void Render(){

      SDL_SetRenderDrawColor(mRenderer, 0, 0, 255, 255);

      SDL_RenderClear(mRenderer);

      SDL_SetRenderScale(mRenderer, 2.5f, 2.5f);
      SDL_SetRenderDrawColor(mRenderer, 255, 255, 255, 255);
      SDL_RenderDebugText(mRenderer, 75, 10, "Main Menu".toStringz);

      auto x= 100;
      auto y = 40;
      for(int i = 0; i < options.length; i++){
        string option = options[i];
        SDL_SetRenderScale(mRenderer, 2.0f, 2.0f);
        if(i == selection){
          SDL_SetRenderDrawColor(mRenderer, 255, 255, 0, SDL_ALPHA_OPAQUE);
        }else{
          SDL_SetRenderDrawColor(mRenderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
        }

        SDL_RenderDebugText(mRenderer, x, y + i * 20, option.toStringz);
      }

      string str = "Press Up/Down to navigate between options.";

      SDL_SetRenderScale(mRenderer, 1.25f, 1.25f);
      SDL_SetRenderDrawColor(mRenderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
      SDL_RenderDebugText(mRenderer, 50, 130, str.toStringz);

      string str2 = "Press Enter to begin.";

      SDL_SetRenderScale(mRenderer, 1.25f, 1.25f);
      SDL_SetRenderDrawColor(mRenderer, 255, 255, 255, SDL_ALPHA_OPAQUE);
      SDL_RenderDebugText(mRenderer, 50, 150, str2.toStringz);

      SDL_RenderPresent(mRenderer);

    }



}
