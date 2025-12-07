import std.stdio;
// Third-party libraries
import bindbc.sdl;
import gameobject;
import std.math;
import std.json;
import std.algorithm;
import std.array;

enum ComponentType{TRANSFORM,TEXTURE,COLLISION, TEXTURE_ANIMATED};

interface IComponent{
	void Update();
}

class ComponentTexture : IComponent{

  SDL_Texture* mTexture;
	GameObject mOwner;

	this(GameObject owner, SDL_Renderer* renderer, SDL_Texture* t){
    mOwner = owner;
    // Create a texture
    mTexture = t;
	}
	~this(){}

  SDL_Texture* GetTexture(){
    return mTexture;
  }

	override void Update(){
    // This function does nothing
	}

}

class ComponentCollision : IComponent{

  SDL_FRect mRectangle;
	GameObject mOwner;

	this(GameObject owner, float x, float y, float w, float h){
		mOwner = owner;
    mRectangle.x = x;
    mRectangle.y = y;
    mRectangle.w = w;
    mRectangle.h = h;
	}

  ref SDL_FRect GetmRectangle(){
    return mRectangle;
  }

	void SetPosition(float x, float y){
		mRectangle.x = x;
		mRectangle.y = y;
	}

	~this(){}

	override void Update(){

	}

}

class ComponentTransform : IComponent{

  SDL_FRect mRectangle;
	GameObject mOwner;

	this(GameObject owner, float x, float y, float w, float h){
		mOwner = owner;
    mRectangle.x = x;
    mRectangle.y = y;
    mRectangle.w = w;
    mRectangle.h = h;

	}

	~this(){}

	override void Update(){

	}

	ref SDL_FRect GetmRectangle(){
		return mRectangle;
	}

}

/// Store a series of frames and multiple animation sequences that can be played
class AnimatedTextureComponent : IComponent{
		/// Store an individual Frame for an animation
		struct Frame{
				SDL_Rect mRect;
				float mElapsedTime;
		}

    // Store filename of the data file for these sequences
    string mFilename;
    // Collection of all of the possible frames that are part of a sprite
    // At a minimum, these are just rectangles
    Frame[] mFrames;
    // Array of longs for the named sequence of an animation
    // i.e. this is a map, with a name (e.g. 'walkUp') followed by frame numbers (e.g. [0,1,2,3] )
    long[][string] mFrameNumbers;


		GameObject mOwner;

		// Helpers for references to data
    SDL_Renderer* mRendererRef;
		ComponentTransform mTransformRef;

    // Stateful information about the current animation
    // sequene that is playing
    string mCurrentAnimationName; // Which animation is currently playing
    long mCurrentFramePlaying ;   // Current frame that is playing, an index into 'mFrames'
    long mLastFrameInSequence;

    /// Hold a copy of the texture that is referenced
    this(GameObject owner, SDL_Renderer* r, string filename){
				mOwner = owner;
        mFilename = filename;
    		mRendererRef = r;
				mTransformRef = cast(ComponentTransform) mOwner.GetComponent(ComponentType.TRANSFORM);
				LoadMetaData(filename);
    }

    /// Load a data file that describes meta-data about animations stored in a single file.
		/// In practice, this could be a public member function, so you can otherwise
		/// load new meta data as needed.
    void LoadMetaData(string filename){

			// Parse the json file
			auto myFile = File(mFilename, "r");
			auto jsonFileContents = myFile.byLine.joiner("\n");

			// You can then parse the jSON contents
			auto j=parseJSON(jsonFileContents);

			mFilename = j["filepath"].str;

			// Extract the tileWidth, tileHeight, numFramesWide, numFramesHeight
			int tileWidth = cast(int)j["format"]["tileWidth"].integer;
			int tileHeight = cast(int)j["format"]["tileHeight"].integer;
			int numFramesW = cast(int)j["format"]["width"].integer/tileWidth;
			int numFramesH = cast(int)j["format"]["height"].integer/tileHeight;

			// Initialize the frames with their rectangle
			auto count = 0;
			mFrames = new Frame[numFramesH*numFramesW];
			for(int i = 0; i < numFramesH; i++){
				for(int k = 0; k < numFramesW; k++){
					mFrames[count] = Frame(SDL_Rect(k*tileWidth,i*tileHeight,tileWidth, tileHeight), 0.1f);
					count++;
				}
			}

			// Now parse the frameNumbers for different animation sequences
			auto kys = j["frames"].object.keys();
			foreach(key; kys){
				mFrameNumbers[key] = j["frames"][key].array.map!(v => v.integer).array;
			}

			mCurrentFramePlaying = 0;

    }

    /// Play an animation based on the name of the animation sequence
    /// specified in the data file.
    void LoopAnimationSequence(string name){

			auto frames = mFrameNumbers[name];
			mCurrentFramePlaying = frames[0];

			SDL_FRect src = SDL_FRect(cast(float) mFrames[mCurrentFramePlaying].mRect.x,cast(float) mFrames[mCurrentFramePlaying].mRect.y,cast(float) mFrames[mCurrentFramePlaying].mRect.w,  cast(float) mFrames[mCurrentFramePlaying].mRect.h);

			mTransformRef.mRectangle.x = src.x;
			mTransformRef.mRectangle.y = src.y;
			mTransformRef.mRectangle.w = src.w;
			mTransformRef.mRectangle.h = src.h;

    }

		override void Update(){

		}
}


class ScriptComponent: IComponent{

	void Update(){

	}

}

class WorldScript: ScriptComponent{

	GameObject mOwner;
	SDL_FRect* ship;
	SDL_FRect* rect;
	bool move;

	this(GameObject owner, SDL_FRect* r, SDL_FRect* sr, bool m){
		mOwner = owner;
		ship = sr;
		rect = r;
		move = m;
	}

	override void Update(){
		if(move){

			auto shipCenterX = ship.x + ship.w/2;
			auto shipCenterY = ship.y + ship.h/2;

			rect.x = shipCenterX - 320;
			rect.y = shipCenterY - 240;

			if(rect.x < 0){
				rect.x = 0;
			}
			if(rect.y < 0){
				rect.y = 0;
			}
			if(rect.x + rect.w > 1000){
				rect.x = 1000-rect.w;
			}
			if(rect.y + rect.h > 1000){
				rect.y = 1000- rect.h;
			}

			move = false;
		}
	}



	void setMove(SDL_FRect* sr){
		ship = sr;
		move = true;
	}


}


class ShipScript: ScriptComponent{

	double angle;
	GameObject mOwner;
	SDL_FRect* rect;
	bool move;

	this(GameObject owner, double ang, SDL_FRect* r, bool m){
		mOwner = owner;
		angle = ang;
		rect = r;
		move = m;
	}

	override void Update(){
		if(move){

			auto rx = rect.x + sin(angle * PI/180.0) * 10.0;
			auto ry = rect.y -cos(angle * PI/180.0) * 10.0;
			if(rx > 0 && rx < 950 && ry > 0 && ry < 950){
				rect.x = rx;
				rect.y = ry;
			}
			move = false;
		}
	}

	double getAngle(){
		return angle;
	}

	void setAngle(double ang){
		angle = ang;
		move = true;
	}

}

class MissileScript: ScriptComponent{

	double angle;
	GameObject mOwner;
	SDL_FRect* rect;


	this(GameObject owner, double ang, SDL_FRect* r){

		mOwner = owner;
		angle = ang;
		rect = r;
	}

	override void Update(){

		rect.x += sin(angle * PI/180.0) * 5.0;
		rect.y += -cos(angle * PI/180.0) * 5.0;

	}

	double getAngle(){
		return angle;
	}

}


class AsteroidScript: ScriptComponent{

	double angle;
	GameObject mOwner;
	SDL_FRect* rect;


	this(GameObject owner, double ang, SDL_FRect* r){

		mOwner = owner;
		angle = ang;
		rect = r;
	}

	override void Update(){

			rect.x += sin(angle) * 0.5;
			rect.y += -cos(angle) * 0.5;

	}

	double getAngle(){
		return angle;
	}

	void setAngle(double ang){
		angle = ang;
	}

}
