package funkin.ui.debug.cutscene.components;

import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import flixel.util.FlxColor;

class CutsceneCamObject extends FunkinSprite
{
  public var zoom(default, set):Float = 1;

  function set_zoom(val:Float):Float
  {
    var scale:Float = 1 / val;
    this.scale.set(scale, scale);

    followCamera.zoom = val;

    zoom = val;
    return val;
  }

  var followCamera:FunkinCamera;

  public function new(x:Float = 0, y:Float = 0, followCamera:FunkinCamera)
  {
    super(x, y);

    this.followCamera = followCamera;

    makeGraphic(1280, 720, FlxColor.CYAN);
    alpha = 0.4;
    zIndex = 10000;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (followCamera.visible)
    {
      if (followCamera.scroll.x != this.x) followCamera.scroll.x = this.x;
      if (followCamera.scroll.y != this.y) followCamera.scroll.y = this.y;
      // followCamera.angle = angle;
    }
  }
}
