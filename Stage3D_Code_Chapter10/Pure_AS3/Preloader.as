////////////////////////////////////////////////////////////
// Stage3D Game Template - Chapter 10
// (c) by Christer Kaitila (http://www.mcfunkypants.com)
// http://www.mcfunkypants.com/molehill/chapter_10_demo/
////////////////////////////////////////////////////////////
// With grateful acknowledgements to:
// Thibault Imbert, Ryan Speets, Alejandro Santander, 
// Mikko Haapoja, Evan Miller and Terry Patton
// for their valuable contributions.
////////////////////////////////////////////////////////////
// Please buy the book:
// http://link.packtpub.com/KfKeo6
////////////////////////////////////////////////////////////
//
// Game preloader version 1.1
// displays a progress bar while
// the swf is being downloaded
//
package 
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.text.Font;
	import flash.utils.getDefinitionByName;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	// Force the 3d game to be on frame two
	
	// In FlashDevelop, add this to your compiler command-line:
	// Project > Properties > 
	// Compiler Options > 
	// Additional Compiler Options:
	// -frame main Stage3dGame
	
	// In Flex, uncomment this line:
	// [frame (factoryClass="Stage3dGame")]
	
	[SWF(width="640", height="480", frameRate="60", 
	backgroundColor="#000000")]	
	
	public class Preloader extends MovieClip 
	{
		private var preloader_square:Sprite = new Sprite();
		private var preloader_border:Sprite = new Sprite();
		private var preloader_text:TextField = new TextField();
		
		public function Preloader() 
		{
			addEventListener(Event.ENTER_FRAME, checkFrame);
			
			loaderInfo.addEventListener(
				ProgressEvent.PROGRESS, progress);

			addChild(preloader_square);
			preloader_square.x = 200;
			preloader_square.y = stage.stageHeight / 2;
			
			addChild(preloader_border);
			preloader_border.x = 200-4;
			preloader_border.y = stage.stageHeight / 2 - 4;
		
			addChild(preloader_text);
			preloader_text.x = 194;
			preloader_text.y = stage.stageHeight / 2 - 30;
			preloader_text.width = 256;
			
		}
		
		private function progress(e:ProgressEvent):void 
		{
			// update loader
			preloader_square.graphics.beginFill(0xAAAAAA);
			preloader_square.graphics.drawRect(0, 0,
				(loaderInfo.bytesLoaded / loaderInfo.bytesTotal)
				* 240,20);
			preloader_square.graphics.endFill();
			
			preloader_border.graphics.lineStyle(2,0xDDDDDD);
			preloader_border.graphics.drawRect(0, 0, 248, 28);
			
			preloader_text.textColor = 0xAAAAAA;
			preloader_text.text = "Loaded " + Math.ceil(
				(loaderInfo.bytesLoaded / 
				loaderInfo.bytesTotal)*100) + "% (" +
				+ loaderInfo.bytesLoaded + " of " + 
				loaderInfo.bytesTotal + " bytes)";
			
		}
		
		private function checkFrame(e:Event):void 
		{
			if (currentFrame == totalFrames) 
			//if (loaderInfo.bytesLoaded >= loaderInfo.bytesTotal)
			{
				removeEventListener(Event.ENTER_FRAME, checkFrame);
				preloader_startup();
			}
		}
		
		private function preloader_startup():void 
		{
			// stop loader
			stop();
			loaderInfo.removeEventListener(
				ProgressEvent.PROGRESS, progress);
			// remove progress bar
			if (contains(preloader_square)) 
				removeChild(preloader_square);
			if (contains(preloader_border)) 
				removeChild(preloader_border);
			if (contains(preloader_text)) 
				removeChild(preloader_text);
			// start the game
			var mainClass:Class = 
				getDefinitionByName("Stage3dGame")
				as Class;
			addChild(new mainClass() as DisplayObject);
		}
		
	}
	
}