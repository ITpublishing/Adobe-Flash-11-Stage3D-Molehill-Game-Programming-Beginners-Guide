// Stage3d game input routines version 1.0
// 
package
{

import flash.display.Stage;
import flash.ui.Keyboard;
import flash.events.*;

public class GameInput
{
	// the current state of the mouse
	public var mouseIsDown:Boolean = false;
	public var mouseClickX:int = 0;
	public var mouseClickY:int = 0;
	public var mouseX:int = 0;
	public var mouseY:int = 0;

	// the current state of the keyboard controls
	public var pressing:Object = 
	{ up:0, down:0, left:0, right:0, fire:0 };

	// if mouselook is on, this is added to the chase camera
	public var cameraAngleX:Number = 0;
	public var cameraAngleY:Number = 0;
	public var cameraAngleZ:Number = 0;

	// if this is true, dragging the mouse changes the camera angle
	public var mouseLookMode:Boolean = true;

	// the game's main stage
	public var stage:Stage;
	
	// class constructor
	public function GameInput(theStage:Stage)
	{
		stage = theStage;
		// get keypresses and detect the game losing focus
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
		stage.addEventListener(Event.DEACTIVATE, lostFocus);
		stage.addEventListener(Event.ACTIVATE, gainFocus);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);   
		stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);   
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove); 
	}

	private function mouseMove(e:MouseEvent):void   
	{
		mouseX = e.stageX;
		mouseY = e.stageY;
		if (mouseIsDown && mouseLookMode)
		{
			cameraAngleY = 90 * ((mouseX - mouseClickX) / stage.width);
			cameraAngleX = 90 * ((mouseY - mouseClickY) / stage.height);
		}
	}

	private function mouseDown(e:MouseEvent):void   
	{   
		trace('mouseDown at '+e.stageX+','+e.stageY);
		mouseClickX = e.stageX;
		mouseClickY = e.stageY;
		mouseIsDown = true;
	}	

	private function mouseUp(e:MouseEvent):void   
	{   
		trace('mouseUp at '+e.stageX+','+e.stageY+' drag distance:'+
			(e.stageX-mouseClickX)+','+(e.stageY-mouseClickY));
		mouseIsDown = false;
		if (mouseLookMode)
		{	// reset camera angle
			cameraAngleX = cameraAngleY = cameraAngleZ = 0;
		}
	}	

	private function keyPressed(event:KeyboardEvent):void 
	{
		// qwer 81 87 69 82
		// asdf 65 83 68 70
		// left right 37 39
		// up down 38 40

		//trace("keyPressed " + event.keyCode);
		
		switch(event.keyCode)
		{
			case Keyboard.UP:
			case 87:
				pressing.up = true;
			break;
			
			case Keyboard.DOWN:
			case 83:
				pressing.down = true;
			break;
			
			case Keyboard.LEFT:
			case 65:
				pressing.left = true;
			break;
			
			case Keyboard.RIGHT:
			case 68:
				pressing.right = true;
			break;
			
			case Keyboard.SPACE:
				pressing.fire = true;
			break;
		}
	}

	private function gainFocus(event:Event):void 
	{
		trace("Game received keyboard focus.");
	}

	// if the game loses focus, don't keep keys held down
	private function lostFocus(event:Event):void 
	{
		trace("Game lost keyboard focus.");
		pressing.up = false;
		pressing.down = false;
		pressing.left = false;
		pressing.right = false;
		pressing.fire = false;
	}

	private function keyReleased(event:KeyboardEvent):void 
	{
		switch(event.keyCode)
		{
			case Keyboard.UP:
			case 87:
				pressing.up = false;
			break;

			case Keyboard.DOWN:
			case 83:
				pressing.down = false;
			break;

			case Keyboard.LEFT:
			case 65:
				pressing.left = false;
			break;

			case Keyboard.RIGHT:
			case 68:
				pressing.right = false;
			break;

			case Keyboard.SPACE:
				pressing.fire = false;
			break;
		}
	}

} // end class

} // end package
