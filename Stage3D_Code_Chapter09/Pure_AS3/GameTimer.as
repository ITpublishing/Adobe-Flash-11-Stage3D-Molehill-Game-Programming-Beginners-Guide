// Stage3d game timer routines version 1.0
// 
package
{

import flash.utils.*;

public class GameTimer
{
	// when the game started
	public var gameStartTime:Number = 0.0; 
	// timestamp: previous frame
	public var lastFrameTime:Number = 0.0; 
	// timestamp: right now
	public var currentFrameTime:Number = 0.0; 
	// how many ms elapsed last frame
	public var frameMs:Number = 0.0; 
	// number of frames this game
	public var frameCount:uint = 0; 
	// when to fire this next
	public var nextHeartbeatTime:uint = 0; 
	// how many ms so far?
	public var gameElapsedTime:uint = 0; 
	// how often in ms does the heartbeat occur?
	public var heartbeatIntervalMs:uint = 1000; 
	// function to run each heartbeat
	public var heartbeatFunction:Function; 
	
	// class constructor
	public function GameTimer(
		heartbeatFunc:Function = null, 
		heartbeatMs:uint = 1000)
	{
		if (heartbeatFunc != null) 
			heartbeatFunction = heartbeatFunc;

		heartbeatIntervalMs = heartbeatMs;
	}

	public function tick():void
	{
		currentFrameTime = getTimer();
		if (frameCount == 0) // first frame?
		{
			gameStartTime	= currentFrameTime;
			trace("First frame happened after " 
				+ gameStartTime + "ms");
			frameMs = 0;
			gameElapsedTime = 0;
		}
		else
		{
			// how much time has passed since the last frame?
			frameMs = currentFrameTime - lastFrameTime;
			gameElapsedTime += frameMs;
		}

		if (heartbeatFunction != null)
		{
			if (currentFrameTime >= nextHeartbeatTime)
			{
				heartbeatFunction();
				nextHeartbeatTime = currentFrameTime 
					+ heartbeatIntervalMs;
			}
		}

		lastFrameTime = currentFrameTime;
		frameCount++;
		
	}	

} // end class

} // end package
