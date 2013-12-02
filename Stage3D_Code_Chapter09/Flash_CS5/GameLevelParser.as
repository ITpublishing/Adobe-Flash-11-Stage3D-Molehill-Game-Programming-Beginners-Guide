// Game Level Parser Class - version 1.1
// spawns meshes based on the pixels in an image
// uses a tiny key image to define what RGB = what mesh #
//
package
{
import flash.display.*;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.geom.Point;
import GameActorpool;

public class GameLevelParser
{
	// create an array of the level for future use
	// to avoid having to look at the map pixels again
	// in our example game this is not used but
	// this would be handy for pathfinding AI for example
	public var leveldata:Array = [];
	
	public function GameLevelParser()
	{
		trace("Created a new level parser.");
	}

	public function spawnActors(
		keyImage:BitmapData, 		// tiny image defining rgb
		mapImage:BitmapData, 		// blueprint of the level
		thecast:Array, 				// list of entity names
		pool:GameActorpool,		// where to spawn them 
		offsetX:Number = 0,			// shift in X space
		offsetY:Number = 0,			// shift in X space
		offsetZ:Number = 0,			// shift in Z space
		tileW:int = 1, 				// size in world units... 
		tileH:int = 1,				// ...for each pixel
		trenchlike:Number = 0,		// U-shaped? #=direction:-1,0,+1
		spiral:Number = 0			// spiral shaped? #=num spirals
		):Number // returns the "length" of the map
	{
		trace("Spawning level entities...");
		trace("Actor List length = " + thecast.length);
		trace("keyImage is ",keyImage.width,"x",keyImage.height);
		trace("mapImage is ",mapImage.width,"x",mapImage.height);
		trace("Tile size is ", tileW, "x", tileH);
		trace("Total level size will be ", 
			mapImage.width * tileW, 
			"x", mapImage.height * tileH);
		
		var pos:Matrix3D = new Matrix3D();
		var mapPixel:uint;
		var keyPixel:uint;
		var whichtile:int;
		var ang:Number;
		var degreesToRadians:Number = Math.PI / 180;
			
		// read all the pixels in the map image
		// and place entities in the level
		// in the correponding locations
		for (var y:int = 0; y < mapImage.height; y++)
		{
			leveldata[y] = [];
				
			for (var x:int = 0; x < mapImage.width; x++)
			{
				mapPixel = mapImage.getPixel(x, y);

				for (var keyY:int = 0; keyY < keyImage.height; keyY++)
				{
					for (var keyX:int = 0; keyX < keyImage.width; keyX++)
					{
						keyPixel = keyImage.getPixel(keyX, keyY);
						if (mapPixel == keyPixel)
						{
							whichtile = keyY * keyImage.width + keyX;

							if (whichtile != 0)
							{
								pos.identity();
									
								// turn to face "backwards"
								// facing towards the camera
								pos.appendRotation(180, Vector3D.Y_AXIS);

								pos.appendTranslation(
									(x * tileW),
									0,
									(y * tileH));

								if (trenchlike != 0)
								{
									// trenchlike means U-shaped
									ang = x / mapImage.width * 360;
									pos.appendTranslation(
									0,
									trenchlike * 
										Math.cos(ang * degreesToRadians) 
										/ Math.PI * mapImage.width * tileW,
									0);
								}
								
								if (spiral != 0)
								{
									// spiral formation: like a corkscrew
									ang = (((y / mapImage.height * spiral) * 360) - 180);
									pos.appendRotation(-ang, Vector3D.Z_AXIS);
								}

								pos.appendTranslation(
									offsetX,
									offsetY,
									offsetZ);
									
								// does a name exist for this index?
								if (thecast[whichtile-1])
									pool.spawn(thecast[whichtile-1], pos);
								
								// store the location for later use
								// good for pathfinding ai, etc
								leveldata[y][x] = whichtile;
							}
							break;
						}
					}
				}
			}
		}
		
		// tell the game the coordinate of the "finish line"
		// or farthest position in the map in the z axis
		// this is used in the example game to determine when 
		// you have reached the end of a level
		
		return mapImage.height * tileH; 
	}

} // end class

} // end package