package funkin.ui.debug.cutscene;

import flixel.FlxSprite;
import flixel.FlxCamera;
import funkin.graphics.FunkinCamera;
import flixel.util.FlxColor;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuOptionBox;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.core.Screen;
import funkin.ui.mainmenu.MainMenuState;
import funkin.input.Cursor;
import funkin.util.WindowUtil;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/cutscene-editor/main-view.xml"))
class CutsceneEditorState extends UIState
{
  var menubar:MenuBar;

  var camHUD:FlxCamera;
  var camGame:FunkinCamera;

  var menubarItemExit:MenuItem;

  override function create():Void
  {
    WindowManager.instance.reset();
    FlxG.sound.music?.stop();
    WindowUtil.setWindowTitle("Friday Night Funkin\' Cutscene Editor");

    camGame = new FunkinCamera();
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;

    FlxG.cameras.reset(camGame);
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.setDefaultDrawTarget(camGame, true);

    persistentUpdate = false;

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
  }

  function addUI():Void
  {
    menubarItemExit.onClick = function(_) menuExit();
  }

  function menuExit():Void
  {
    Cursor.hide();
    FlxG.switchState(() -> new MainMenuState());
    FlxG.sound.music.stop();
  }
}
