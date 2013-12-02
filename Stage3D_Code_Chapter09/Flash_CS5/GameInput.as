// Stage3d game input routines version 1.2
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
	{ up:0, down:0, left:0, right:0, fire:0, 
	strafeLeft:0, strafeRight:0, 
	key0:0, key1:0, key2:0, key3:0, key4:0,
	key5:0,	key6:0, key7:0, key8:0, key9:0 };

	// if mouselook is on, this is added to the chase camera
	public var cameraAngleX:Number = 0;
	public var cameraAngleY:Number = 0;
	public var cameraAngleZ:Number = 0;

	// if this is true, dragging the mouse changes the camera angle
	public var mouseLookMode:Boolean = true;

	// the game's main stage
	public var stage:Stage;
	
	// for click events to be sent to the game
	private var _clickfunc:Function = null;
	
	// class constructor
	public function GameInput(
		theStage:Stage, 
		clickfunc:Function = null)
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
		
		// handle clicks in game
		_clickfunc = clickfunc;
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
		if (_clickfunc != null) _clickfunc();
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
		// 0123456789 = 48 to 57
		// zxcv = 90 88 67 86

		// trace("keyPressed " + event.keyCode);
		
		if (event.ctrlKey || 
			event.altKey || 
			event.shiftKey)
			pressing.fire = true;

		switch(event.keyCode)
		{
			/*
			case 81: // Q
				pressing.strafeLeft = true;
			break;
			case 69: // E
				pressing.strafeRight = true;
			break;
			*/

			case Keyboard.UP:
			case 87: // W
			case 90: // Z
				pressing.up = true;
			break;
			
			case Keyboard.DOWN:
			case 83: // S
				pressing.down = true;
			break;
			
			case Keyboard.LEFT:
			case 65: // A
			case 81: // Q
				pressing.left = true;
			break;
			
			case Keyboard.RIGHT:
			case 68: // D
				pressing.right = true;
			break;
			
			case Keyboard.SPACE:
			case Keyboard.SHIFT:
			case Keyboard.CONTROL:
			case Keyboard.ENTER:
			// case 90: // z
			case 88: // x
			case 67: // c
				pressing.fire = true;
			break;

			case 48: pressing.key0 = true; break;
			case 49: pressing.key1 = true; break;
			case 50: pressing.key2 = true; break;
			case 51: pressing.key3 = true; break;
			case 52: pressing.key4 = true; break;
			case 53: pressing.key5 = true; break;
			case 54: pressing.key6 = true; break;
			case 55: pressing.key7 = true; break;
			case 56: pressing.key8 = true; break;
			case 57: pressing.key9 = true; break;
			
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
		pressing.strafeLeft = false;
		pressing.strafeRight = false;
		pressing.fire = false;
		pressing.key0 = false;
		pressing.key1 = false;
		pressing.key2 = false;
		pressing.key3 = false;
		pressing.key4 = false;
		pressing.key5 = false;
		pressing.key6 = false;
		pressing.key7 = false;
		pressing.key8 = false;
		pressing.key9 = false;
	}

	private function keyReleased(event:KeyboardEvent):void 
	{
		switch(event.keyCode)
		{
			/*
			case 81: // Q
				pressing.strafeLeft = false;
			break;
			case 69: // E
				pressing.strafeRight = false;
			break;
			*/

			case Keyboard.UP:
			case 87: // W
			case 90: // Z
				pressing.up = false;
			break;

			case Keyboard.DOWN:
			case 83: // S
				pressing.down = false;
			break;

			case Keyboard.LEFT:
			case 65: // A
			case 81: // Q
				pressing.left = false;
			break;

			case Keyboard.RIGHT:
			case 68: // D
				pressing.right = false;
			break;

			case Keyboard.SPACE:
			case Keyboard.SHIFT:
			case Keyboard.CONTROL:
			case Keyboard.ENTER:
			// case 90: // z
			case 88: // x
			case 67: // c
				pressing.fire = false;
			break;

			case 48: pressing.key0 = false; break;
			case 49: pressing.key1 = false; break;
			case 50: pressing.key2 = false; break;
			case 51: pressing.key3 = false; break;
			case 52: pressing.key4 = false; break;
			case 53: pressing.key5 = false; break;
			case 54: pressing.key6 = false; break;
			case 55: pressing.key7 = false; break;
			case 56: pressing.key8 = false; break;
			case 57: pressing.key9 = false; break;
			
		}
	}

} // end class

} // end package
