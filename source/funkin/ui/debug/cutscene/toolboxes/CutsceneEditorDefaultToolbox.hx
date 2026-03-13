package funkin.ui.debug.cutscene.toolboxes;

import haxe.ui.containers.dialogs.CollapsibleDialog;
import funkin.audio.FunkinSound;

@:access(funkin.ui.debug.cutscene.CutsceneEditorState)
class CutsceneEditorDefaultToolbox extends CollapsibleDialog
{
  var cutsceneEditorState:CutsceneEditorState;

  public var dialogVisible:Bool = false;

  private function new(cutsceneEditorState:CutsceneEditorState)
  {
    super();

    this.cutsceneEditorState = cutsceneEditorState;

    closable = true;
    modal = true;
    destroyOnClose = false;
  }

  /**
   * Handles the Sound and Visibility
   * @param on
   */
  public function toggle(on:Bool)
  {
    if (!dialogVisible && on) FunkinSound.playOnce(Paths.sound('chartingSounds/openWindow'));
    else if (dialogVisible && !on) FunkinSound.playOnce(Paths.sound('chartingSounds/exitWindow'));

    if (on) showDialog(false);
    else
      hide();

    dialogVisible = on;
  }

  /**
   * Override to implement this.
   */
  public function refresh(onlyPos:Bool = false)
  {
  }

  /**
   * Override to implement this.
   */
  public function lock(on:Bool = true)
  {
  }
}
