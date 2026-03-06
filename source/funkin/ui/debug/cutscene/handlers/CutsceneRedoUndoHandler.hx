package funkin.ui.debug.cutscene.handlers;

class CutsceneUndoRedoHandler
{
  // public var undos:Array<
  public function addAction(action:UndoAction, redo:Bool):Void
  {
    switch (action)
    {
      default:
        trace('wip');
    }
  }
}

typedef UndoAction =
{
  /**
   * The Type of Undo Action to store.
   */
  var type:UndoActionType;

  /**
   * The added Data of the Action.
   */
  var data:Dynamic;
}

enum abstract UndoActionType(String) from String
{
  /**
   * Triggerred when an Object is deleted.
   */
  var OBJECT_DELETED = "object_deleted";

  /**
   * Triggerred when an Object is created.
   */
  var OBJECT_CREATED = "object_created";

  /**
   * Triggerred when an Object is moved.
   */
  var OBJECT_MOVED = "object_moved";

  /**
   * Triggerred when a Character is moved.
   */
  var CHARACTER_MOVED = "character_moved";

  /**
   * Triggerred when an Object is rotated.
   */
  var OBJECT_ROTATED = "object_rotated";
}
