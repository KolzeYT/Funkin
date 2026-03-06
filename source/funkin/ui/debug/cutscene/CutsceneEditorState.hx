package funkin.ui.debug.cutscene;

import flixel.FlxSprite;
import flixel.FlxCamera;
import funkin.graphics.FunkinCamera;
import flixel.util.FlxColor;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.ListView;
import haxe.ui.containers.menus.MenuBar;
import flixel.FlxObject;
import haxe.ui.containers.menus.MenuOptionBox;
import funkin.data.character.CharacterData.CharacterDataParser;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.windows.WindowManager;
import flixel.addons.display.FlxGridOverlay;
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
import haxe.ui.containers.dialogs.CollapsibleDialog;

@:build(haxe.ui.ComponentBuilder.build('assets/exclude/data/ui/cutscene-editor/main-view.xml'))
class CutsceneEditorState extends UIState
{
  var camHUD:FlxCamera;
  var camGame:FunkinCamera;

  // all menu items
  var menubarItemExit:MenuItem;
  var menubarItemResetZoom:MenuItem;
  var menubar:MenuBar;
  var objects:ListView;

  var currentStage:Null<Stage> = null;

  var moveableObjects:Array<FlxSprite> = [];

  var nameMap:Map<FlxSprite, String> = new Map<FlxSprite, String>();

  var curSelected(default, set):Null<Int> = null;

  function set_curSelected(value:Int):Int
  {
    objects.selectedIndex = value;
    curSelected = value;
    return value;
  }

  var bg:FlxSprite;

  override function create():Void
  {
    WindowManager.instance.reset();
    FlxG.sound.music?.stop();
    WindowUtil.setWindowTitle("Friday Night Funkin\' Cutscene Editor");
    currentStage = null; // TODO: PRECHACHE

    camGame = new FunkinCamera();
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;

    trace(objects);

    FlxG.cameras.reset(camGame);
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

    addUI();

    loadStage('phillyStreets');
    initCharacters();
  }

  var zoomToLerp:Float = FlxG.camera.zoom;
  var camPosToLerp:Array<Float> = [FlxG.camera.scroll.x, FlxG.camera.scroll.y];

  override function update(elapsed:Float):Void
  {
    if (FlxG.mouse.wheel != 0) zoomToLerp += 0.02 * FlxG.mouse.wheel;

    FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, zoomToLerp, 0.1);
    FlxG.camera.scroll.x = FlxMath.lerp(FlxG.camera.scroll.x, camPosToLerp[0], 0.1);
    FlxG.camera.scroll.y = FlxMath.lerp(FlxG.camera.scroll.y, camPosToLerp[1], 0.1);

    handleMoving();

    updateBGSize();

    super.update(elapsed);
  }

  var isMovingCam:Bool = false;
  var firstClick:Bool = false;
  var offset:Array<Float> = [];

  function handleMoving():Void
  {
    var selectables = [];
    for (object in moveableObjects)
    {
      if (FlxG.mouse.overlaps(object)) selectables.insert(0, object);
    }

    for (object in selectables)
    {
      if (!FlxG.mouse.overlaps(object)) selectables.remove(object);
    }

    if (FlxG.mouse.pressedMiddle)
    {
      isMovingCam = true;
      if (FlxG.mouse.justMoved)
      {
        camPosToLerp[0] -= FlxG.mouse.deltaScreenX;
        camPosToLerp[1] -= FlxG.mouse.deltaScreenY;
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
        if (FlxG.mouse.pressed)
        {
          if (FlxG.mouse.justPressed && curSelected != moveableObjects.indexOf(selectables[0]))
          {
            firstClick = true;
            curSelected = moveableObjects.indexOf(selectables[0]);
          }
          Cursor.cursorMode = Grabbing;
        }
        else
        {
          Cursor.cursorMode = Pointer;
        }

        if (FlxG.mouse.justPressed)
        {
          trace('clicked');
        }
      }
      else
      {
        Cursor.cursorMode = Default;
      }
    }

    if (curSelected >= 0)
    {
      var theThing = moveableObjects[curSelected];
      var overlaps = FlxG.mouse.overlaps(theThing);

      if (FlxG.mouse.justPressed)
      {
        if (!overlaps)
        {
          moveableObjects[curSelected].shader = null;
          curSelected = -1;
          firstClick = false;
        }
      }

      if (FlxG.mouse.justReleased && firstClick) firstClick = false;

      if (overlaps && FlxG.mouse.pressed && !firstClick)
      {
        if (FlxG.mouse.justPressed) offset = [FlxG.mouse.viewX - theThing.x, FlxG.mouse.viewY - theThing.y];
        theThing.setPosition(FlxG.mouse.viewX - offset[0], FlxG.mouse.viewY - offset[1]);
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
        currentStage.addCharacter(boyfriend, BF, false);
        addToList(boyfriend, 'boyfriend');

        #if FEATURE_DEBUG_FUNCTIONS
        FlxG.console.registerObject('bf', boyfriend);
        #end
      }

      if (dad != null)
      {
        currentStage.addCharacter(dad, DAD, false);
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
      trace(nameMap[object]);
      objects.dataSource.add({text: nameMap[object], id: object});
    }
  }

  function addToList(object:FlxSprite, name:String):Void
  {
    moveableObjects.push(object);
    nameMap[object] = name;
  }

  function resortObjects():Void
  {
    moveableObjects.sort(function(a, b)
    {
      return a.zIndex - b.zIndex;
    });

    refreshList();
  }

  function addUI():Void
  {
    menubarItemExit.onClick = function(_) menuExit();
    menubarItemResetZoom.onClick = function(_) resetCameraZoom();
  }

  function menuExit():Void
  {
    if (currentStage != null)
    {
      remove(currentStage);
      currentStage.kill();
      currentStage = null;
    }
    Cursor.hide();
    FlxG.switchState(() -> new MainMenuState());
    FlxG.sound.music.stop();
  }

  function resetCameraZoom():Void
  {
    zoomToLerp = currentStage.camZoom;
  }
}
