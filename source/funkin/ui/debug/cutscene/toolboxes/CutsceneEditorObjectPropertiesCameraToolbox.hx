package funkin.ui.debug.cutscene.toolboxes;

import haxe.ui.containers.VBox;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import funkin.ui.debug.cutscene.components.CutsceneCamObject;
import haxe.ui.components.NumberStepper;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.util.Color;
import flixel.util.FlxColor;
import haxe.ui.events.UIEvent;
import flixel.FlxSprite;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler;

@:access(funkin.ui.debug.cutscene.CutsceneEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/cutscene-editor/toolboxes/properties/camera-properties.xml"))
class CutsceneEditorObjectPropertiesCameraToolbox extends CutsceneEditorDefaultToolbox
{
  var linkedObj:CutsceneCamObject = null;

  var objPosX:NumberStepper;
  var objPosY:NumberStepper;
  var objZoom:NumberStepper;
  var objAlpha:NumberStepper;
  var objAngle:NumberStepper;

  override public function new(state:CutsceneEditorState)
  {
    super(state);

    // Numeric callbacks.
    objPosX.onChange = function(_)
    {
      if (linkedObj != null)
      {
        linkedObj.x = objPosX.pos;
        state.refreshOutline();
      }
    }

    objPosY.onChange = function(_)
    {
      if (linkedObj != null)
      {
        linkedObj.y = objPosY.pos;
        state.refreshOutline();
      }
    }

    objZoom.onChange = function(_)
    {
      if (linkedObj != null)
      {
        linkedObj.zoom = objZoom.pos;
        state.refreshOutline();
      }
    }

    objAlpha.onChange = function(_)
    {
      if (linkedObj != null) linkedObj.alpha = objAlpha.pos;
    }

    objAngle.onChange = function(_)
    {
      if (linkedObj != null)
      {
        linkedObj.angle = objAngle.pos;
        state.refreshOutline();
      }
    }

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent):Void
  {
    // stageEditorState.menubarItemWindowObjectProps.selected = false;
  }

  override public function refresh():Void
  {
    linkedObj = cutsceneEditorState.cameraObject;

    objPosX.step = cutsceneEditorState.moveStep;
    objPosY.step = cutsceneEditorState.moveStep;
    objAngle.step = cutsceneEditorState.moveStep;
    // objAngle.step = funkin.save.Save.instance.cutsceneEditorState.value;

    if (linkedObj == null)
    {
      // If there is no selected object, reset displays.
      objPosX.pos = 0;
      objPosY.pos = 0;
      objZoom.pos = 1;
      objAlpha.pos = 1;
      objAngle.pos = 0;
    }

    // Otherwise, only update components whose linked object values have been changed.
    if (objPosX.pos != linkedObj.x) objPosX.pos = linkedObj.x;
    if (objPosY.pos != linkedObj.y) objPosY.pos = linkedObj.y;
    if (objZoom.pos != linkedObj.zoom) objZoom.pos = linkedObj.zoom;
    if (objAlpha.pos != linkedObj.alpha) objAlpha.pos = linkedObj.alpha;
    if (objAngle.pos != linkedObj.angle) objAngle.pos = linkedObj.angle;
  }
}
