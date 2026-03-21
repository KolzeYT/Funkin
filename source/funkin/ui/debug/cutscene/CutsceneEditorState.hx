package funkin.ui.debug.cutscene;

import flixel.FlxSprite;
import flixel.FlxCamera;
import funkin.ui.debug.FunkinDebugDisplay;
import funkin.graphics.FunkinCamera;
import flixel.util.FlxColor;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.ListView;
import haxe.ui.containers.menus.MenuBar;
import funkin.audio.FunkinSound;
import haxe.ui.events.UIEvent;
import flixel.FlxObject;
import funkin.graphics.FunkinSprite;
import haxe.ui.containers.menus.MenuOptionBox;
import funkin.data.character.CharacterData.CharacterDataParser;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.windows.WindowManager;
import flixel.graphics.frames.FlxFrame;
import flixel.addons.display.FlxGridOverlay;
import funkin.ui.debug.cutscene.toolboxes.*;
import funkin.ui.debug.cutscene.components.*;
import funkin.ui.debug.cutscene.components.CutsceneTimeline.CutsceneEventType;
import haxe.ui.core.Screen;
import funkin.ui.mainmenu.MainMenuState;
import funkin.input.Cursor;
import funkin.util.WindowUtil;
import funkin.data.stage.StageRegistry;
import funkin.play.stage.Stage;
import funkin.play.character.BaseCharacter;
import flixel.math.FlxMath;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import openfl.geom.Rectangle;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.components.NumberStepper;

using flixel.util.FlxSpriteUtil;

@:build(haxe.ui.ComponentBuilder.build('assets/exclude/data/ui/cutscene-editor/main-view.xml'))
class CutsceneEditorState extends UIState
{
  public static final MAX_Z_INDEX:Int = 10000;

  public var moveStep:Int = 1;

  public var camHUD:FlxCamera;

  var camGame:FunkinCamera;
  var camPreview:FunkinCamera;

  public var instance:Null<CutsceneEditorState>;

  public var selectedSprite(get, never):Dynamic;

  var isCamSelected:Bool = false;

  function get_selectedSprite():Dynamic
  {
    return moveableObjects[curSelected];
  }

  var swagOutlines:FlxSprite;

  // all menu items
  var menubarItemExit:MenuItem;
  var menubarItemResetZoom:MenuItem;
  var menubar:MenuBar;
  var objects:ListView;
  var menubarItemWindowObjectProps:MenuCheckBox;
  var menubarItemWindowCameraProps:MenuCheckBox;
  var menubarItemWindowCameraPreview:MenuCheckBox;
  var menubarItemKeyframeProps:MenuCheckBox;
  var timelineLength:NumberStepper;

  public var currentStage:Null<Stage> = null;

  public var cameraObject:CutsceneCamObject;

  var moveableObjects:Array<CutsceneObject> = [];

  public var timeline:CutsceneTimeline;

  // var nameMap:Map<FunkinSprite, String> = new Map<FunkinSprite, String>();
  var curSelected:Null<Int> = null;

  var bg:FlxSprite;

  var dialogs:Map<CutsceneEditorDialogType, CutsceneEditorDefaultToolbox> = new Map<CutsceneEditorDialogType, CutsceneEditorDefaultToolbox>();

  var isCursorOverHaxeUI(get, never):Bool;

  function get_isCursorOverHaxeUI():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(Screen.instance.currentMouseX, Screen.instance.currentMouseY);
  }

  override function create():Void
  {
    WindowManager.instance.reset();
    instance = this;
    FlxG.sound.music?.stop();
    WindowUtil.setWindowTitle("Friday Night Funkin\' Cutscene Editor");

    Main.debugDisplay.y = 250;
    Main.debugDisplay.x = 30;

    camGame = new FunkinCamera();
    camGame.y = -Std.int(FlxG.height / 3 / 2);
    camPreview = new FunkinCamera();
    camPreview.x = -450;
    camPreview.y = -220;
    camPreview.visible = false;
    camPreview.flashSprite.scaleX = 0.25;
    camPreview.flashSprite.scaleY = 0.25;
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;

    FlxG.cameras.reset(camGame);
    FlxG.cameras.add(camPreview, false);
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.setDefaultDrawTarget(camGame, true);

    persistentUpdate = false;

    bg = FlxGridOverlay.create(10, 10);
    bg.scrollFactor.set();
    add(bg);

    super.create();

    root.scrollFactor.set();
    root.cameras = [camHUD];
    root.width = FlxG.width;
    root.height = FlxG.height;

    menubar.height = 35;
    WindowManager.instance.container = root;
    Screen.instance.addComponent(root);

    var testBlock = new FlxSprite().makeGraphic(60, 60, FlxColor.RED);
    add(testBlock);

    Cursor.show();
    FunkinSound.playMusic('chartEditorLoop', {
      startingVolume: 0.0
    });
    FlxG.sound.music.fadeIn(10, 0, 1);

    addUI();

    loadStage('mainStageErect');
    initCharacters();

    cameraObject = new CutsceneCamObject(0, 0, camPreview);
    cameraObject.zoom = currentStage.camZoom;
    addToList(cameraObject, 'camera');
    add(cameraObject);

    updateDialog(CutsceneEditorDialogType.CAMERA_PROPERTIES);
    updateDialog(CutsceneEditorDialogType.OBJECT_PROPERTIES);

    timeline = new CutsceneTimeline(this, Std.int(FlxG.width / 2 - 350), Std.int(FlxG.height - 200));
    timeline.timeLength = timelineLength.pos;
    timeline.cameras = [camHUD];
    add(timeline);

    timeline.addEvent({time: 0.5, type: VARIABLE_TWEEN, params: [cameraObject, 'zoom', 1.3, 2]});
  }

  var zoomToLerp:Float = FlxG.camera.zoom;
  var camPosToLerp:Array<Float> = [FlxG.camera.scroll.x, FlxG.camera.scroll.y];

  override function update(elapsed:Float):Void
  {
    if (!isCursorOverHaxeUI)
    {
      if (FlxG.mouse.wheel != 0) zoomToLerp += 0.02 * FlxG.mouse.wheel;

      handleMoving();
    }

    FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, zoomToLerp, elapsed * 30);
    FlxG.camera.scroll.x = FlxMath.lerp(FlxG.camera.scroll.x, camPosToLerp[0], elapsed * 30);
    FlxG.camera.scroll.y = FlxMath.lerp(FlxG.camera.scroll.y, camPosToLerp[1], elapsed * 30);

    updateBGSize();

    super.update(elapsed);
  }

  var isMovingCam:Bool = false;
  var firstClick:Bool = false;
  var offset:Array<Float> = [];

  function handleMoving():Void
  {
    var mouse = FlxG.mouse;

    var selectables = [];
    for (object in moveableObjects)
    {
      if (mouse.overlaps(object)) selectables.insert(0, object);
    }

    for (object in selectables)
    {
      if (!mouse.overlaps(object)) selectables.remove(object);
    }

    if (mouse.pressedMiddle)
    {
      isMovingCam = true;
      if (mouse.justMoved)
      {
        camPosToLerp[0] -= mouse.deltaScreenX;
        camPosToLerp[1] -= mouse.deltaScreenY;
      }
      Cursor.cursorMode = Grabbing;
    }
    else
    {
      isMovingCam = false;
    }

    if (!isMovingCam)
    {
      if (selectables.length > 0)
      {
        if (mouse.pressed)
        {
          if (mouse.justPressed
            && (curSelected < 0 || !mouse.overlaps(moveableObjects[curSelected]))
            && curSelected != moveableObjects.indexOf(selectables[0]))
          {
            changeSelectedObject(moveableObjects.indexOf(selectables[0]));
          }
          if (Cursor.cursorMode != Grabbing) Cursor.cursorMode = Grabbing;
        }
        else
        {
          if (Cursor.cursorMode != Pointer) Cursor.cursorMode = Pointer;
        }

        if (mouse.justPressed)
        {
          trace('clicked');
        }
      }
      else
      {
        if (Cursor.cursorMode != Default) Cursor.cursorMode = Default;
      }
    }

    if (curSelected >= 0)
    {
      var theThing = moveableObjects[curSelected];
      var overlaps = mouse.overlaps(theThing);

      if (mouse.justPressed)
      {
        if (!overlaps)
        {
          changeSelectedObject(-1, false);
        }
      }

      if (mouse.justReleased && firstClick) firstClick = false;

      if (overlaps && mouse.pressed && !firstClick)
      {
        if (mouse.justPressed) offset = [mouse.viewX - theThing.x, mouse.viewY - theThing.y];
        theThing.setPosition(mouse.viewX - offset[0], mouse.viewY - offset[1]);
        refreshOutlinePos();
        if (isCamSelected)
        {
          updateDialog(CutsceneEditorDialogType.CAMERA_PROPERTIES);
        }
        else
        {
          updateDialog(CutsceneEditorDialogType.OBJECT_PROPERTIES);
        }
      }
    }
  }

  function updateBGSize():Void
  {
    bg.scale.set(1 / FlxG.camera.zoom, 1 / FlxG.camera.zoom);
    bg.updateHitbox();
    bg.screenCenter();
  }

  // from playstate
  function initCharacters():Void
  {
    //
    // GIRLFRIEND
    //
    var girlfriend:Null<BaseCharacter> = CharacterDataParser.fetchCharacter('gf');

    //
    // DAD
    //
    var dad:Null<BaseCharacter> = CharacterDataParser.fetchCharacter('dad');

    //
    // BOYFRIEND
    //
    var boyfriend:Null<BaseCharacter> = CharacterDataParser.fetchCharacter('bf');

    //
    // ADD CHARACTERS TO SCENE
    //

    if (currentStage != null)
    {
      // Characters get added to the stage, not the main scene.
      if (girlfriend != null)
      {
        currentStage.addCharacter(girlfriend, GF);
        addToList(girlfriend, 'girlfriend');

        #if FEATURE_DEBUG_FUNCTIONS
        FlxG.console.registerObject('gf', girlfriend);
        #end
      }

      if (boyfriend != null)
      {
        currentStage.addCharacter(boyfriend, BF);
        addToList(boyfriend, 'boyfriend');

        #if FEATURE_DEBUG_FUNCTIONS
        FlxG.console.registerObject('bf', boyfriend);
        #end
      }

      if (dad != null)
      {
        currentStage.addCharacter(dad, DAD);
        addToList(dad, 'dad');

        #if FEATURE_DEBUG_FUNCTIONS
        FlxG.console.registerObject('dad', dad);
        #end
      }

      // Rearrange by z-indexes.
      currentStage.refresh();
      resortObjects();
    }
  }

  function loadStage(id:String):Void
  {
    currentStage = StageRegistry.instance.fetchEntry(id);

    if (currentStage != null)
    {
      currentStage.revive(); // Stages are killed and props destroyed when the PlayState is destroyed to save memory.

      @:privateAccess
      Paths.currentLevel = currentStage._data.directory;

      // Actually create and position the sprites.
      var event:ScriptEvent = new ScriptEvent(CREATE, false);
      ScriptEventDispatcher.callEvent(currentStage, event);

      resetCameraZoom();

      @:privateAccess
      for (object in currentStage.namedProps)
      {
        addToList(object, object.name);
      }
      resortObjects();

      // Add the stage to the scene.
      this.add(currentStage);

      #if FEATURE_DEBUG_FUNCTIONS
      FlxG.console.registerObject('stage', currentStage);
      #end
    }
    else
    {
      // lolol
      funkin.util.WindowUtil.showError('Stage Error', 'Unable to load stage $id, is its data corrupted?.');
    }
  }

  function refreshList():Void
  {
    objects.dataSource.clear();

    for (object in moveableObjects)
    {
      if (object != cameraObject) object.cameras = [camGame, camPreview];
      objects.dataSource.add({text: object.name, id: object});
    }
  }

  function addToList(object:Dynamic, name:String):Void
  {
    var cutsceneObject = Std.isOfType(object, FunkinSprite) ? cast(object, CutsceneObject) : object;
    cutsceneObject.name = name;
    moveableObjects.push(cutsceneObject);
  }

  function resortObjects():Void
  {
    moveableObjects.sort(function(a, b)
    {
      return a.zIndex - b.zIndex;
    });

    refreshList();
  }

  public function updateDialog(type:CutsceneEditorDialogType, onlyPos:Bool = false)
  {
    if (!dialogs.exists(type)) return;

    dialogs[type].refresh(onlyPos);
  }

  public function toggleDialog(type:CutsceneEditorDialogType, show:Bool = true)
  {
    if (!dialogs.exists(type)) return;

    dialogs[type].toggle(show);
    dialogs[type].refresh();
  }

  function addUI():Void
  {
    dialogs.set(CutsceneEditorDialogType.OBJECT_PROPERTIES, new CutsceneEditorObjectPropertiesToolbox(this));
    dialogs.set(CutsceneEditorDialogType.CAMERA_PROPERTIES, new CutsceneEditorObjectPropertiesCameraToolbox(this));
    dialogs.set(CutsceneEditorDialogType.KEYFRAME_PROPERTIES, new CutsceneEditorObjectPropertiesKeyframeToolbox(this));

    menubarItemExit.onClick = function(_) menuExit();
    menubarItemResetZoom.onClick = function(_) resetCameraZoom();
    objects.onChange = function(_) if (objects.selectedIndex != curSelected) changeSelectedObject(objects.selectedIndex, false);
    menubarItemWindowObjectProps.onChange = function(_) toggleDialog(CutsceneEditorDialogType.OBJECT_PROPERTIES, menubarItemWindowObjectProps.selected);
    menubarItemWindowCameraProps.onChange = function(_) toggleDialog(CutsceneEditorDialogType.CAMERA_PROPERTIES, menubarItemWindowCameraProps.selected);
    menubarItemKeyframeProps.onChange = function(_) toggleDialog(CutsceneEditorDialogType.CAMERA_PROPERTIES, menubarItemWindowCameraProps.selected);
    menubarItemWindowCameraPreview.onChange = function(_) camPreview.visible = menubarItemWindowCameraPreview.selected;
    timelineLength.onChange = function(_) timeline.timeLength = timelineLength.pos;
  }

  public function changeSelectedObject(index:Int, first:Bool = true):Void
  {
    objects.selectedIndex = index;
    curSelected = index;
    firstClick = first;

    if (index >= 0)
    {
      updateDialog(CutsceneEditorDialogType.OBJECT_PROPERTIES);

      isCamSelected = moveableObjects[curSelected] == cameraObject;

      if (isCamSelected) dialogs[CutsceneEditorDialogType.OBJECT_PROPERTIES].lock();
      else
      {
        dialogs[CutsceneEditorDialogType.OBJECT_PROPERTIES].lock(false);
      }

      if (members.contains(cameraObject)) remove(cameraObject);
      add(cameraObject);
      if (swagOutlines != null) swagOutlines.visible = true;
      refreshOutline();
    }
    else
    {
      if (swagOutlines != null) swagOutlines.visible = false;
      dialogs[CutsceneEditorDialogType.OBJECT_PROPERTIES].lock();
    }
  }

  public function refreshOutline():Void
  {
    if (curSelected < 0) return;
    var sprite = moveableObjects[curSelected];

    if (members.contains(swagOutlines)) remove(swagOutlines);
    swagOutlines = new FlxSprite(sprite.x,
      sprite.y).makeGraphic(Std.int(sprite.frameWidth * sprite.scale.x), Std.int(sprite.frameHeight * sprite.scale.y), FlxColor.TRANSPARENT);
    swagOutlines.scrollFactor.set(sprite.scrollFactor.x, sprite.scrollFactor.y);
    swagOutlines.angle = sprite.angle;
    var lineStyle:LineStyle = {color: FlxColor.RED, thickness: 6};
    swagOutlines.drawRect(0, 0, swagOutlines.frameWidth, swagOutlines.frameHeight, FlxColor.TRANSPARENT, lineStyle);

    if (isCamSelected)
    {
      swagOutlines.x -= (1280 * (sprite.scale.x - 1)) / 2;
      swagOutlines.y -= (720 * (sprite.scale.y - 1)) / 2;
    }
    add(swagOutlines);
  }

  public function refreshOutlinePos():Void
  {
    if (curSelected < 0) return;
    var sprite = moveableObjects[curSelected];

    swagOutlines.x = sprite.x;
    swagOutlines.y = sprite.y;

    if (isCamSelected)
    {
      swagOutlines.x -= (1280 * (sprite.scale.x - 1)) / 2;
      swagOutlines.y -= (720 * (sprite.scale.y - 1)) / 2;
    }
  }

  function menuExit():Void
  {
    if (currentStage != null)
    {
      remove(currentStage);
      currentStage.kill();
      currentStage = null;
    }
    instance = null;

    Main.debugDisplay.y = 10;
    Main.debugDisplay.x = 10;

    Cursor.hide();
    FlxG.switchState(() -> new MainMenuState());
    FlxG.sound.music.stop();
  }

  function resetCameraZoom():Void
  {
    zoomToLerp = currentStage.camZoom;
  }
}

enum CutsceneEditorDialogType
{
  /**
   * The Object Properties Options Dialog.
   */
  OBJECT_PROPERTIES;

  /**
   * The Camera Properties Options Dialog.
   */
  CAMERA_PROPERTIES;

  /**
   * The Keyframe Properties Options Dialog.
   */
  KEYFRAME_PROPERTIES;
}
