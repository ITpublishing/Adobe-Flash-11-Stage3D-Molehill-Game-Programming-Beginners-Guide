////////////////////////////////////////////////////////////
// Stage3D Game Template - Chapter 9
// (c) by Christer Kaitila (http://www.mcfunkypants.com)
// http://www.mcfunkypants.com/molehill/chapter_9_demo/
////////////////////////////////////////////////////////////
// With grateful acknowledgements to:
// Thibault Imbert, Ryan Speets, Alejandro Santander, 
// Mikko Haapoja, Evan Miller and Terry Patton
// for their valuable contributions.
////////////////////////////////////////////////////////////
// Please buy the book:
// http://link.packtpub.com/KfKeo6
////////////////////////////////////////////////////////////
package
{

import com.adobe.utils.*;
import flash.display.*;
import flash.display3D.*;
import flash.display3D.textures.*;
import flash.events.*;
import flash.geom.*;
import flash.utils.*;
import flash.text.*;

import Stage3dEntity;
import GameTimer;
import GameInput;
import Stage3dParticle;
import GameParticlesystem;

[SWF(width="640", height="480", frameRate="60", 
backgroundColor="#000000")]	

public class Stage3dGame extends Sprite
{

// handles all timers for us
private var gametimer:GameTimer;

// handles keyboard and mouse inputs
private var gameinput:GameInput;
	
// all known entities in the world
private var chaseCamera:Stage3dEntity
private var player:Stage3dEntity;	
private var props:Vector.<Stage3dEntity>;	

// used for our particle system demo
private var nextShootTime:uint = 0;
private var shootDelay:uint = 0;
private var explo:Stage3dParticle;
private var particleSystem:GameParticlesystem;
private var scenePolycount:uint = 0;

// reusable entity pointer (for speed and to avoid GC)
private var entity:Stage3dEntity; 
// we want to remember these for use in gameStep()
private var asteroids1:Stage3dEntity; 
private var asteroids2:Stage3dEntity; 
private var asteroids3:Stage3dEntity; 
private var asteroids4:Stage3dEntity; 
private var engineGlow:Stage3dEntity;
private var sky:Stage3dEntity;

// used by gameStep()
private const moveSpeed:Number = 1.0; // units per ms
private const asteroidRotationSpeed:Number = 0.001; // deg per ms

// used by the GUI
private var fpsLast:uint = getTimer();
private var fpsTicks:uint = 0;
private var fpsTf:TextField;
private var scoreTf:TextField;
private var score:uint = 0;
// the 3d graphics window on the stage
private var context3D:Context3D;
// the compiled shader used to render our meshes
private var shaderProgram1:Program3D;

// matrices that affect the mesh location and camera angles
private var projectionmatrix:PerspectiveMatrix3D = 
	new PerspectiveMatrix3D();
private var viewmatrix:Matrix3D = new Matrix3D();

/* TEXTURES: Pure AS3 and Flex version:
 * if you are using Adobe Flash CS5 
 * comment out the following: */
[Embed (source = "art/spaceship_texture.jpg")] 
private var playerTextureBitmap:Class;
private var playerTextureData:Bitmap = new playerTextureBitmap();
[Embed (source = "art/terrain_texture.jpg")] 
private var terrainTextureBitmap:Class;
private var terrainTextureData:Bitmap = new terrainTextureBitmap();
[Embed (source = "art/craters.jpg")] 
private var cratersTextureBitmap:Class;
private var cratersTextureData:Bitmap = new cratersTextureBitmap();
[Embed (source = "art/sky.jpg")] 
private var skyTextureBitmap:Class;
private var skyTextureData:Bitmap = new skyTextureBitmap();
[Embed (source = "art/engine.jpg")] 
private var puffTextureBitmap:Class;
private var puffTextureData:Bitmap = new puffTextureBitmap();
[Embed (source = "art/hud_overlay.png")] 
private var hudOverlayData:Class;
private var hudOverlay:Bitmap = new hudOverlayData();

// new textures used by the particle system
[Embed (source = "art/particle1.jpg")] 
private var particle1data:Class;
private var particle1bitmap:Bitmap = new particle1data();
[Embed (source = "art/particle2.jpg")] 
private var particle2data:Class;
private var particle2bitmap:Bitmap = new particle2data();
[Embed (source = "art/particle3.jpg")] 
private var particle3data:Class;
private var particle3bitmap:Bitmap = new particle3data();
[Embed (source = "art/particle4.jpg")] 
private var particle4data:Class;
private var particle4bitmap:Bitmap = new particle4data();


/* TEXTURES: Flash CS5 version:
 * add the jpgs to your library (F11)
 * right click and edit the advanced properties
 * so it is exported for use in Actionscript 
 * and using the proper names as listed below
 * if you are using Flex/FlashBuilder/FlashDevelop/FDT
 * comment out the following: */
/*
private var playerTextureData:Bitmap =
	new Bitmap(new playerTextureBitmapData(512,512));
private var terrainTextureData:Bitmap =
	new Bitmap(new terrainTextureBitmapData(512,512));
private var cratersTextureData:Bitmap =
	new Bitmap(new cratersTextureBitmapData(512,512));
private var skyTextureData:Bitmap =
	new Bitmap(new skyTextureBitmapData(512,512));
private var puffTextureData:Bitmap =
	new Bitmap(new engineTextureBitmapData(128,128));
private var hudOverlay:Bitmap =
	new Bitmap(new hudTextureBitmapData(640,480));
	
// new textures used by the particle system
private var particle1bitmap:Bitmap =
	new Bitmap(new particle1BitmapData(128,128));
private var particle2bitmap:Bitmap =
	new Bitmap(new particle2BitmapData(128,128));
private var particle3bitmap:Bitmap =
	new Bitmap(new particle3BitmapData(128,128));
private var particle4bitmap:Bitmap =
	new Bitmap(new particle4BitmapData(128,128));

*/
					
// The Stage3d Textures that use the above
private var playerTexture:Texture;
private var terrainTexture:Texture;
private var cratersTexture:Texture;
private var skyTexture:Texture;
private var puffTexture:Texture;
// new textures used by our particle system
private var particle1texture:Texture;
private var particle2texture:Texture;
private var particle3texture:Texture;
private var particle4texture:Texture;


// the player - 142 polygons
[Embed (source = "art/spaceship.obj", 
	mimeType = "application/octet-stream")] 
private var myObjData5:Class;
		
// the engine glow - 336 polygons
[Embed (source = "art/puff.obj",
	mimeType = "application/octet-stream")] 
private var puffObjData:Class;

// The terrain mesh data - 8192 polygons
[Embed (source = "art/terrain.obj", 
	mimeType = "application/octet-stream")] 
private var terrainObjData:Class;

// an asteroid field - 3280 polygons
[Embed (source = "art/asteroids.obj", 
	mimeType = "application/octet-stream")] 
private var asteroidsObjData:Class;

// the sky - 768 polygons
[Embed (source = "art/sphere.obj",
	mimeType = "application/octet-stream")] 
private var skyObjData:Class;

// explosion start - 336 polygons
[Embed (source = "art/explosion1.obj",
	mimeType = "application/octet-stream")] 
private var explosion1_data:Class;

// explosion end - 336 polygons
[Embed (source = "art/explosion2.obj",
	mimeType = "application/octet-stream")] 
private var explosion2_data:Class;

public function Stage3dGame() 
{
	if (stage != null) 
		init();
	else 
		addEventListener(Event.ADDED_TO_STAGE, init);
}

private function init(e:Event = null):void 
{
	if (hasEventListener(Event.ADDED_TO_STAGE))
		removeEventListener(Event.ADDED_TO_STAGE, init);

	// start the game timer
	gametimer = new GameTimer(heartbeat,10000);
	gameinput = new GameInput(stage);
	
	// create some empty arrays
	props = new Vector.<Stage3dEntity>();

	// set up the stage
	stage.frameRate = 60;
	stage.scaleMode = StageScaleMode.NO_SCALE;
	stage.align = StageAlign.TOP_LEFT;
	
	// add some text labels
	initGUI();
	
	// and request a context3D from Stage3d
	stage.stage3Ds[0].addEventListener(
		Event.CONTEXT3D_CREATE, onContext3DCreate);
	stage.stage3Ds[0].requestContext3D();
}

private function updateScore():void
{
	// for now, you earn points over time
	score++;
	// padded with zeroes
	if (score < 10) scoreTf.text = 'Score: 00000' + score;
	else if (score < 100) scoreTf.text = 'Score: 0000' + score;
	else if (score < 1000) scoreTf.text = 'Score: 000' + score;
	else if (score < 10000) scoreTf.text = 'Score: 00' + score;
	else if (score < 100000) scoreTf.text = 'Score: 0' + score;
	else scoreTf.text = 'Score: ' + score;
}

private function initGUI():void
{
	// heads-up-display overlay
	addChild(hudOverlay);
	
	// a text format descriptor used by all gui labels
	var myFormat:TextFormat = new TextFormat();  
	myFormat.color = 0xFFFFAA;
	myFormat.size = 16;

	// create an FPSCounter that displays the framerate on screen
	fpsTf = new TextField();
	fpsTf.x = 4;
	fpsTf.y = 0;
	fpsTf.selectable = false;
	fpsTf.autoSize = TextFieldAutoSize.LEFT;
	fpsTf.defaultTextFormat = myFormat;
	fpsTf.text = "Initializing Stage3d...";
	addChild(fpsTf);

	// create a score display
	scoreTf = new TextField();
	scoreTf.x = 540;
	scoreTf.y = 0;
	scoreTf.selectable = false;
	scoreTf.autoSize = TextFieldAutoSize.LEFT;
	scoreTf.defaultTextFormat = myFormat;
	addChild(scoreTf);
	
}

public function uploadTextureWithMipmaps(
	dest:Texture, src:BitmapData):void
{
     var ws:int = src.width;
     var hs:int = src.height;
     var level:int = 0;
     var tmp:BitmapData;
     var transform:Matrix = new Matrix();
     //var tmp2:BitmapData;

     tmp = new BitmapData( src.width, src.height, true, 0x00000000);

     while ( ws >= 1 && hs >= 1 )
     {                                
          tmp.draw(src, transform, null, null, null, true);    
          dest.uploadFromBitmapData(tmp, level);
          transform.scale(0.5, 0.5);
          level++;
          ws >>= 1;
          hs >>= 1;
          if (hs && ws) 
		  {
               tmp.dispose();
               tmp = new BitmapData(ws, hs, true, 0x00000000);
          }
     }
     tmp.dispose();
}

private function onContext3DCreate(event:Event):void 
{
	// Remove existing frame handler. Note that a context
	// loss can occur at any time which will force you
	// to recreate all objects we create here.
	// A context loss occurs for instance if you hit
	// CTRL-ALT-DELETE on Windows.			
	// It takes a while before a new context is available
	// hence removing the enterFrame handler is important!

	if (hasEventListener(Event.ENTER_FRAME))
		removeEventListener(Event.ENTER_FRAME,enterFrame);
	
	// Obtain the current context
	var t:Stage3D = event.target as Stage3D;					
	context3D = t.context3D; 	

	if (context3D == null) 
	{
		// Currently no 3d context is available (error!)
		trace('ERROR: no context3D - video driver problem?');
		return;
	}
	
	// Disabling error checking will drastically improve performance.
	// If set to true, Flash sends helpful error messages regarding
	// AGAL compilation errors, uninitialized program constants, etc.
	context3D.enableErrorChecking = true;
	
	// The 3d back buffer size is in pixels (2=antialiased)
	context3D.configureBackBuffer(stage.width, stage.height, 2, true);

	// assemble all the shaders we need
	initShaders();

	playerTexture = context3D.createTexture(
		playerTextureData.width, playerTextureData.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		playerTexture, playerTextureData.bitmapData);

	terrainTexture = context3D.createTexture(
		terrainTextureData.width, terrainTextureData.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		terrainTexture, terrainTextureData.bitmapData);

	cratersTexture = context3D.createTexture(
		cratersTextureData.width, cratersTextureData.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		cratersTexture, cratersTextureData.bitmapData);

	puffTexture = context3D.createTexture(
		puffTextureData.width, puffTextureData.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		puffTexture, puffTextureData.bitmapData);

	skyTexture = context3D.createTexture(
		skyTextureData.width, skyTextureData.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		skyTexture, skyTextureData.bitmapData);

	// new textures used by our particle system
	particle1texture = context3D.createTexture(
		particle1bitmap.width, particle1bitmap.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		particle1texture, particle1bitmap.bitmapData);
	
	particle2texture = context3D.createTexture(
		particle2bitmap.width, particle2bitmap.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		particle2texture, particle2bitmap.bitmapData);
	
	particle3texture = context3D.createTexture(
		particle3bitmap.width, particle3bitmap.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		particle3texture, particle3bitmap.bitmapData);
	
	particle4texture = context3D.createTexture(
		particle4bitmap.width, particle4bitmap.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		particle4texture, particle4bitmap.bitmapData);
		
	// Initialize our mesh data - requires shaders and textures first
	initData();
	
	// create projection matrix for our 3D scene
	projectionmatrix.identity();
	// 45 degrees FOV, 640/480 aspect ratio, 0.1=near, 150000=far
	projectionmatrix.perspectiveFieldOfViewRH(
		45, stage.width / stage.height, 0.01, 150000.0);
	
	// start the render loop!
	addEventListener(Event.ENTER_FRAME,enterFrame);
}

private function initShaders():void
{
	// A simple vertex shader which does a 3D transformation
	// for simplicity, it is used by all four shaders
	var vertexShaderAssembler:AGALMiniAssembler = 
		new AGALMiniAssembler();
	vertexShaderAssembler.assemble
	( 
		Context3DProgramType.VERTEX,
		// 4x4 matrix multiply to get camera angle	
		"m44 op, va0, vc0\n" +
		// tell fragment shader about XYZ
		"mov v0, va0\n" +
		// tell fragment shader about UV
		"mov v1, va1\n" +
		// tell fragment shader about RGBA
		"mov v2, va2"
	);			
	
	// textured using UV coordinates
	var fragmentShaderAssembler1:AGALMiniAssembler 
		= new AGALMiniAssembler();
	fragmentShaderAssembler1.assemble
	( 
		Context3DProgramType.FRAGMENT,	
		// grab the texture color from texture 0 
		// and uv coordinates from varying register 1
		// and store the interpolated value in ft0
		"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\n"+
		// move this value to the output color
		"mov oc, ft0\n"
	);
	
	// combine shaders into a program which we then upload to the GPU
	shaderProgram1 = context3D.createProgram();
	shaderProgram1.upload(
		vertexShaderAssembler.agalcode, 
		fragmentShaderAssembler1.agalcode);
}

private function initData():void 
{
	// create the camera entity
	trace("Creating the camera entity...");
	chaseCamera = new Stage3dEntity();
	
	// create the player model
	trace("Creating the player entity...");
	player = new Stage3dEntity(
		myObjData5, 
		context3D, 
		shaderProgram1, 
		playerTexture);
	// rotate to face forward
	player.rotationDegreesX = -90;
	player.z = 2100;

	trace("Parsing the terrain...");
	// add some terrain to the props list
	var terrain:Stage3dEntity = 
		new Stage3dEntity(
			terrainObjData, 
			context3D, 
			shaderProgram1, 
			terrainTexture);
	terrain.rotationDegreesZ = 90;
	terrain.y = -50;
	props.push(terrain);		

	trace("Cloning the terrain...");
	// use the same mesh in another location
	var terrain2:Stage3dEntity = terrain.clone();
	terrain2.z = -4000;
	props.push(terrain2);		

	trace("Parsing the asteroid field...");
	// add an asteroid field to the props list
	asteroids1 = new Stage3dEntity(
			asteroidsObjData, 
			context3D, 
			shaderProgram1, 
			cratersTexture);
	asteroids1.rotationDegreesZ = 90;
	asteroids1.scaleXYZ = 200;
	asteroids1.y = 500;
	asteroids1.z = -1000;
	props.push(asteroids1);		

	trace("Cloning the asteroid field...");
	// use the same mesh in multiple locations
	asteroids2 = asteroids1.clone();
	asteroids2.z = -5000;
	props.push(asteroids2);	
	
	asteroids3 = asteroids1.clone();
	asteroids3.z = -9000;
	props.push(asteroids3);	
	asteroids4 = asteroids1.clone();
	asteroids4.z = -9000;
	asteroids4.y = -500;
	props.push(asteroids4);	
	
	trace("Parsing the sky...");
	sky = new Stage3dEntity(
			skyObjData, 
			context3D, 
			shaderProgram1, 
			skyTexture);
	// follow the player's ship
	sky.follow(player);
	sky.depthTest = false;
	sky.depthTestMode = Context3DCompareMode.LESS;
	sky.cullingMode = Context3DTriangleFace.NONE;
	sky.z = 2000.0;
	sky.scaleX = 40000;
	sky.scaleY = 40000;
	sky.scaleZ = 10000;
	sky.rotationDegreesX = 30;
	props.push(sky);	

	trace("Parsing the engine glow...");
	engineGlow = new Stage3dEntity(
			puffObjData, 
			context3D, 
			shaderProgram1, 
			puffTexture);
	// follow the player's ship
	engineGlow.follow(player);
	// draw as a transparent particle
	engineGlow.blendSrc = Context3DBlendFactor.ONE;
	engineGlow.blendDst = Context3DBlendFactor.ONE;
	engineGlow.depthTest = true;
	engineGlow.depthTestMode = Context3DCompareMode.ALWAYS;
	engineGlow.cullingMode = Context3DTriangleFace.NONE;
	engineGlow.y = -1.0;
	engineGlow.scaleXYZ = 0.5;
	props.push(engineGlow);	// a prop, not a particle

	// create a particle system
	particleSystem = new GameParticlesystem;

	// define the types of particles
	trace("Creating an explosion particle system...");
	particleSystem.defineParticle("explosion", 
		new Stage3dParticle(explosion1_data, context3D, 
		puffTexture, explosion2_data));
	particleSystem.defineParticle("bluebolt", 
		new Stage3dParticle(explosion1_data, context3D, 
		particle1texture, explosion2_data));
	particleSystem.defineParticle("greenpuff", 
		new Stage3dParticle(explosion1_data, context3D, 
		particle2texture, explosion2_data));
	particleSystem.defineParticle("ringfire", 
		new Stage3dParticle(explosion1_data, context3D, 
		particle3texture, explosion2_data));
	particleSystem.defineParticle("sparks", 
		new Stage3dParticle(explosion1_data, context3D, 
		particle4texture, explosion2_data));
}		

private function renderScene():void 
{
	scenePolycount = 0;
	
	viewmatrix.identity();
	// look at the player
	viewmatrix.append(chaseCamera.transform);
	viewmatrix.invert();
	// tilt down a little
	viewmatrix.appendRotation(15, Vector3D.X_AXIS);
	// if mouselook is on:
	viewmatrix.appendRotation(gameinput.cameraAngleX, 
		Vector3D.X_AXIS);
	viewmatrix.appendRotation(gameinput.cameraAngleY, 
		Vector3D.Y_AXIS);
	viewmatrix.appendRotation(gameinput.cameraAngleZ, 
		Vector3D.Z_AXIS);
	
	// render the player mesh from the current camera angle
	player.render(viewmatrix, projectionmatrix);
	scenePolycount += player.polycount;
	
	// loop through all known entities and render them
	for each (entity in props)
	{
		entity.render(viewmatrix, projectionmatrix);
		scenePolycount += entity.polycount;
	}

	particleSystem.render(viewmatrix, projectionmatrix);
	scenePolycount += particleSystem.totalpolycount;
}

private function gameStep(frameMs:uint):void 
{
	// handle player input
	var moveAmount:Number = moveSpeed * frameMs;
	if (gameinput.pressing.up) player.z -= moveAmount;
	if (gameinput.pressing.down) player.z += moveAmount;
	if (gameinput.pressing.left) player.x -= moveAmount;
	if (gameinput.pressing.right) player.x += moveAmount;
	if (gameinput.pressing.fire)
	{
		if (gametimer.gameElapsedTime >= nextShootTime)
		{
			//trace("Fire!");
			nextShootTime = 
				gametimer.gameElapsedTime + shootDelay;
			
			// random location somewhere ahead of player
			var groundzero:Matrix3D = new Matrix3D;
			groundzero.prependTranslation(
				player.x + Math.random() * 200 - 100, 
				player.y + Math.random() * 100 - 50, 
				player.z + Math.random() * -1000 - 250);
				
			// create a new particle (or reuse an inactive one)
			// cycles through all five types defined earlier
			switch (gametimer.frameCount % 5)
			{
				case 0:
					particleSystem.spawn("explosion", groundzero, 2000);
				break;
				case 1:
					particleSystem.spawn("bluebolt", groundzero, 2000);
				break;
				case 2:
					particleSystem.spawn("greenpuff", groundzero, 2000);
				break;
				case 3:
					particleSystem.spawn("ringfire", groundzero, 2000);
				break;
				case 4:
					particleSystem.spawn("sparks", groundzero, 2000);
				break;
			}
		}
	}
	
	// follow the player
	chaseCamera.x = player.x;
	chaseCamera.y = player.y + 1.5; // above
	chaseCamera.z = player.z + 3; // behind
	
	// animate the asteroids
	asteroids1.rotationDegreesX += asteroidRotationSpeed * frameMs;
	asteroids2.rotationDegreesX -= asteroidRotationSpeed * frameMs;
	asteroids3.rotationDegreesX += asteroidRotationSpeed * frameMs;
	asteroids4.rotationDegreesX -= asteroidRotationSpeed * frameMs;
	
	// animate the engine glow - spin fast and pulsate slowly
	engineGlow.rotationDegreesZ += 10 * frameMs;
	engineGlow.scaleXYZ = 
		Math.cos(gametimer.gameElapsedTime / 66) / 20 + 0.5;
	
	// advance all particles based on time
	particleSystem.step(frameMs);
	
}

// for efficiency, this function only runs occasionally
// ideal for calculations that don't need to be run every frame
private function heartbeat():void
{
	trace('heartbeat at ' + gametimer.gameElapsedTime + 'ms');
	trace('player ' + player.posString());
	trace('camera ' + chaseCamera.posString());
	trace('particles active: ' + particleSystem.particlesActive);
	trace('particles total: ' + particleSystem.particlesCreated);
	trace('particles polies: ' + particleSystem.totalpolycount);
}

private function enterFrame(e:Event):void 
{
	// clear scene before rendering is mandatory
	context3D.clear(0,0,0); 
	
	// count frames, measure elapsed time
	gametimer.tick();
	
	// update all entities positions, etc
	gameStep(gametimer.frameMs);
	
	// render everything
	renderScene();
	
	// present/flip back buffer
	// now that all meshes have been drawn
	context3D.present();

	// update the FPS display
	fpsTicks++;
	var now:uint = getTimer();
	var delta:uint = now - fpsLast;
	// only update the display once a second
	if (delta >= 1000) 
	{
		var fps:Number = fpsTicks / delta * 1000;
		fpsTf.text = fps.toFixed(1) + 
			" fps (" + scenePolycount + " polies)";
		fpsTicks = 0;
		fpsLast = now;
	}
	// update the rest of the GUI
	updateScore();
}

} // end of class
} // end of package
