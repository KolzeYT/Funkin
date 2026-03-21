package funkin.ui.debug.cutscene.toolboxes;

import haxe.ui.containers.VBox;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import funkin.ui.debug.cutscene.components.CutsceneTimeline.TimelineEventSprite;
import haxe.ui.components.NumberStepper;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.util.Color;
import flixel.util.FlxColor;
import haxe.ui.events.UIEvent;
import flixel.FlxSprite;

@:access(funkin.ui.debug.cutscene.CutsceneEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/cutscene-editor/toolboxes/properties/keyframe-properties.xml"))
class CutsceneEditorObjectPropertiesKeyframeToolbox extends CutsceneEditorDefaultToolbox
{
  var linkedObj:TimelineEventSprite;

  var timePos:NumberStepper;
  var valuePos:NumberStepper;

  override public function new(state:CutsceneEditorState)
  {
    super(state);

    // Numeric callbacks.
    timePos.onChange = function(_)
    {
      if (linkedObj != null)
      {
        linkedObj.event.time = timePos.pos;
      }
    }

    // valuePos.onChange = function(_)
    // {
    //   if (linkedObj != null)
    //   {
    //     linkedObj.y = valuePos.pos;
    //     state.refreshOutline();
    //   }
    // }

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent):Void
  {
    @:privateAccess
    cutsceneEditorState.menubarItemKeyframeProps.selected = false;
  }

  override public function refresh(onlyPos:Bool = false):Void
  {
    if (linedObj == null) return;

    linkedObj = cutsceneEditorState.timeline.currentEvent;

    // Otherwise, only update components whose linked object values have been changed.
    if (timePos.pos != linkedObj.x) timePos.pos = linkedObj.event.time;
    // if (valuePos.pos != linkedObj.y) valuePos.pos = linkedObj.y;
  }
}
