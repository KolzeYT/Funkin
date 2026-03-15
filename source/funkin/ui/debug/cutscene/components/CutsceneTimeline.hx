package funkin.ui.debug.cutscene.components;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

@:access(funkin.ui.debug.cutscene.CutsceneEditorState)
class CutsceneTimeline extends FlxSpriteGroup
{
  public var previewZoom:Float = 10;

  public var previewTime:Float = 1;

  public var time:Float = 0;

  public var timeLength:Float = 0;

  public var isPlaying:Bool = false;

  var keyframes:Array<Keyframe> = [];

  var sprites:Array<TimelineEventSprite> = [];

  public var events:Array<CutsceneEvent> = []; // TODO: Make it CutsceneEvent.

  var cutsceneState:CutsceneEditorState;

  var playhead:FlxSprite;

  public var bg:FlxSprite;

  public function new(state:CutsceneEditorState, x:Int = 0, y:Int = 0)
  {
    super(x, y);

    this.cutsceneState = state;

    bg = new FlxSprite().makeGraphic(700, 200, 0xFF373737);

    playhead = new FlxSprite().makeGraphic(5, Std.int(bg.height), FlxColor.CYAN);

    add(bg);
    add(playhead);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.SPACE) isPlaying = !isPlaying;

    if (isPlaying) time += elapsed;
    else
    {
      var vel:Float = (FlxG.keys.pressed.LEFT ? -1 : 0) + (FlxG.keys.pressed.RIGHT ? 1 : 0);
      time += vel * elapsed;
    }

    playhead.x = bg.x + bg.width * (time / previewZoom);

    time = FlxMath.bound(time, 0, timeLength);
    if ((time == 0 || time == timeLength) && isPlaying) isPlaying = false;

    trace(time);

    for (keyframe in keyframes)
    {
      keyframe.tween.percent = FlxMath.bound((time - keyframe.time) / (keyframe.tween.duration), 0, 1);
    }

    for (sprite in sprites)
    {
      sprite.x = bg.x + bg.width * (sprite.event.time / previewZoom);
    }
  }

  public function addEvent(event:CutsceneEvent):Void
  {
    events.push(event);
    if (event.type == CutsceneEventType.VARIABLE_TWEEN)
    {
      var val:Dynamic = {};
      Reflect.setField(val, event.params[1], event.params[2]);
      var newTween:FlxTween = FlxTween.tween(event.params[0], val, event.params[3], {type: 2});
      keyframes.push({time: event.time, tween: newTween});
    }
    var sprite:TimelineEventSprite = new TimelineEventSprite(this, event);
    insert(members.indexOf(playhead), sprite);
    sprites.push(sprite);
  }

  // public function executeEvent(event:CutsceneEvent)
  // {
  //   switch (event.type)
  //   {
  //     case CutsceneEventType.VARIABLE_TWEEN:
  //       // var easeFull = '${event.params[4]}${event.params[5]}';
  //       var tween:FlxTween = FlxTween.tween(event.params[0], {'${event.params[1]}': event.params[2]}, event.params[3]);
  //       tweensArray.push(tween);
  //     default:
  //       trace('no behaviour yet');
  //   }
  // }
}

class TimelineEventSprite extends FlxSpriteGroup
{
  public var event:CutsceneEvent;

  var timeline:CutsceneTimeline;

  var line:FlxSprite;

  var square:FlxSprite;

  public function new(timeline:CutsceneTimeline, event:CutsceneEvent)
  {
    super();

    this.timeline = timeline;
    this.event = event;

    square = new FlxSprite(0, 10).makeGraphic(25, 25, FlxColor.GRAY);
    square.x -= square.width / 2;
    square.angle = 45;

    if (event.type == VARIABLE_TWEEN)
    {
      line = new FlxSprite(0,
        square.height / 2 - 3 + square.y).makeGraphic(Std.int(timeline.bg.width * (event.params[3] / timeline.previewZoom)), 6, FlxColor.WHITE);

      add(line);
    }
    add(square);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // line.x = Std.int(timeline.bg.width * line.scale.x / 2);
    // line.scale.x = event.params[3] / timeline.previewZoom;
    // trace(line.scale.x);
  }
}

typedef CutsceneEvent =
{
  var time:Float;
  var type:CutsceneEventType;
  var params:Array<Dynamic>;
}

typedef Keyframe =
{
  var time:Float;
  var tween:FlxTween;
}

enum abstract CutsceneEventType(Int)
{
  var VARIABLE_TWEEN = 0;

  var PLAY_ANIM = 1;
}
