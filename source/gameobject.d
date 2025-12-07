import core.atomic;
import std.stdio;
import std.conv;

import component;

// Code adapted from Mike's public repository
// https://github.com/MikeShah/BuildingGameEngines/blob/main/dlang/06_gameobject/full_component/gameobject.d
// https://github.com/MikeShah/BuildingGameEngines/blob/main/dlang/07_gameplay_scripts/behaviors/strategy3.d

struct GameObject{

    string mName;
    size_t mID;
    IComponent[ComponentType] mComponents;
    ScriptComponent mScript;
    static shared size_t sGameObjectCount = 0;
    bool mActive;

    // Constructor
    this(string name){
      assert(name.length > 0);
      mName = name;
      // atomic increment of number of game objects
      sGameObjectCount.atomicOp!"+="(1);
      mID = sGameObjectCount;
      mActive = true;
    }

    // Destructor
    ~this(){	}

    string GetName() const { return mName; }
    size_t GetID() const { return mID; }


    IComponent GetComponent(ComponentType type){
      if(type in mComponents){
        return mComponents[type];
      }else{
        return null;
      }
    }


    void AddComponent(ComponentType T)(IComponent component){
      mComponents[T] = component;
    }

    void AddScript(ScriptComponent component){
      mScript = component;
    }

    ref ScriptComponent GetScript(){
      return mScript;
    }

    void SetInactive(){
      mActive = false;
    }

    void SetActive(){
      mActive = true;
    }


    void Update(){
      if(mScript !is null && mActive){
        mScript.Update();
      }
    }


}
