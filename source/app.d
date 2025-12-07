/// Run with: 'dub'
import gameapplication;
import std.stdio;
import core.stdc.stdlib;

// Entry point to program
void main(string[] args)
{
  if(args.length < 2){
      writeln("usage: dub -- \".resources.json\"");
      exit(1);
  }else{
      writeln("Starting with args:\n",args);
  }
  GameApplication app = GameApplication(args);
  //GameApplication app = GameApplication("Asteroids");
  app.RunLoop();
}
