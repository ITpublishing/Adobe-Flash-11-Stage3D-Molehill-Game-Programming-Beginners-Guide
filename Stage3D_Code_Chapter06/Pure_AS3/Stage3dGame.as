////////////////////////////////////////////////////////////
// Stage3D Game Template - Chapter 6
// (c) by Christer Kaitila (http://www.mcfunkypants.com)
// http://www.mcfunkypants.com/molehill/chapter_6_demo/
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

[SWF(width="640", height="480", frameRate="60", 
backgroundColor="#000000")]	

public class Stage3dGame extends Sprite
{

// available blend/texture/mesh
private var blendNum:int = -1;
private var blendNumMax:int = 4;
private var texNum:int = -1;
private var texNumMax:int = 4;
private var meshNum:int = -1;
private var meshNumMax:int = 4;

// used by the GUI
private var fpsLast:uint = getTimer();
private var fpsTicks:uint = 0;
private var fpsTf:TextField;
private var scoreTf:TextField;
private var score:uint = 0;
private var label1:TextField;
private var label2:TextField;
private var label3:TextField;

// constants used during inits
private const swfWidth:int = 640;
private const swfHeight:int = 480;

// the 3d graphics window on the stage
private var context3D:Context3D;
// the compiled shaders used to render our mesh
private var shaderProgram1:Program3D;
private var shaderProgram2:Program3D;

// matrices that affect the mesh location and camera angles
private var projectionmatrix:PerspectiveMatrix3D = 
	new PerspectiveMatrix3D();
private var modelmatrix:Matrix3D = new Matrix3D();
private var viewmatrix:Matrix3D = new Matrix3D();
private var terrainviewmatrix:Matrix3D = new Matrix3D();
private var modelViewProjection:Matrix3D = new Matrix3D();

// a simple frame counter used for animation
private var t:Number = 0;
// a reusable loop counter
private var looptemp:int = 0;

/* TEXTURES: Pure AS3 and Flex version:
 * if you are using Adobe Flash CS5 
 * comment out the following: */
[Embed (source = "art/leaf.png")] 
private var myTextureBitmap1:Class;
private var myTextureData1:Bitmap = new myTextureBitmap1();
[Embed (source = "art/fire.jpg")] 
private var myTextureBitmap2:Class;
private var myTextureData2:Bitmap = new myTextureBitmap2();
[Embed (source = "art/flare.jpg")] 
private var myTextureBitmap3:Class;
private var myTextureData3:Bitmap = new myTextureBitmap3();
[Embed (source = "art/glow.jpg")] 
private var myTextureBitmap4:Class;
private var myTextureData4:Bitmap = new myTextureBitmap4();
[Embed (source = "art/smoke.jpg")] 
private var myTextureBitmap5:Class;
private var myTextureData5:Bitmap = new myTextureBitmap5();
[Embed (source = "art/terrain_texture.jpg")] 
private var terrainTextureBitmap:Class;
private var terrainTextureData:Bitmap = new terrainTextureBitmap();

/* TEXTURES: Flash CS5 version:
 * add the jpgs to your library (F11)
 * right click and edit the advanced properties
 * so it is exported for use in Actionscript 
 * and call them TextureBitmap1..5 and terrainTextureBitmap
 * if you are using Flex/FlashBuilder/FlashDevelop/FDT
 * comment out the following: */
/*
private var myTextureData1:Bitmap = // leaf.png
	new Bitmap(new myTextureBitmapData1(256,256));
private var myTextureData2:Bitmap = // fire.jpg
	new Bitmap(new myTextureBitmapData2(256,256));
private var myTextureData3:Bitmap = // flare.jpg
	new Bitmap(new myTextureBitmapData3(128,128));
private var myTextureData4:Bitmap = // glow.jpg
	new Bitmap(new myTextureBitmapData4(128,128));
private var myTextureData5:Bitmap = // smoke.jpg
	new Bitmap(new myTextureBitmapData5(128,128));
private var terrainBitmapDataObject:terrainTextureBitmapData = 
	new terrainTextureBitmapData(512,512);
private var terrainTextureData:Bitmap = 
	new Bitmap(terrainBitmapDataObject);
*/
					
// The Stage3d Textures that use the above
private var myTexture1:Texture;
private var myTexture2:Texture;
private var myTexture3:Texture;
private var myTexture4:Texture;
private var myTexture5:Texture;
private var terrainTexture:Texture;

// Points to whatever the current mesh is
private var myMesh:Stage3dObjParser;

// The mesh data
[Embed (source = "art/cluster.obj",
	mimeType = "application/octet-stream")] 
private var myObjData1:Class;
private var myMesh1:Stage3dObjParser;
[Embed (source = "art/puff.obj",
	mimeType = "application/octet-stream")] 
private var myObjData2:Class;
private var myMesh2:Stage3dObjParser;
[Embed (source = "art/box.obj",
	mimeType = "application/octet-stream")] 
private var myObjData3:Class;
private var myMesh3:Stage3dObjParser;
[Embed (source = "art/sphere.obj",
	mimeType = "application/octet-stream")] 
private var myObjData4:Class;
private var myMesh4:Stage3dObjParser;
[Embed (source = "art/spaceship.obj", 
	mimeType = "application/octet-stream")] 
private var myObjData5:Class;
private var myMesh5:Stage3dObjParser;
		
// The terrain mesh data
[Embed (source = "art/terrain.obj", 
	mimeType = "application/octet-stream")] 
private var terrainObjData:Class;
private var terrainMesh:Stage3dObjParser;

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
	
	// get keypresses
	stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
	
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
	// a text format descriptor used by all gui labels
	var myFormat:TextFormat = new TextFormat();  
	myFormat.color = 0xFFFFFF;
	myFormat.size = 13;

	// create an FPSCounter that displays the framerate on screen
	fpsTf = new TextField();
	fpsTf.x = 0;
	fpsTf.y = 0;
	fpsTf.selectable = false;
	fpsTf.autoSize = TextFieldAutoSize.LEFT;
	fpsTf.defaultTextFormat = myFormat;
	fpsTf.text = "Initializing Stage3d...";
	addChild(fpsTf);

	// create a score display
	scoreTf = new TextField();
	scoreTf.x = 560;
	scoreTf.y = 0;
	scoreTf.selectable = false;
	scoreTf.autoSize = TextFieldAutoSize.LEFT;
	scoreTf.defaultTextFormat = myFormat;
	addChild(scoreTf);

	// add some labels to describe each shader
	label1 = new TextField();
	label1.x = 250;
	label1.y = 400;
	label1.selectable = false;  
	label1.autoSize = TextFieldAutoSize.LEFT;  
	label1.defaultTextFormat = myFormat;
	addChild(label1);

	label2 = new TextField();
	label2.x = 250;
	label2.y = 420;
	label2.selectable = false;  
	label2.autoSize = TextFieldAutoSize.LEFT;  
	label2.defaultTextFormat = myFormat;
	addChild(label2);

	label3 = new TextField();
	label3.x = 250;
	label3.y = 440;
	label3.selectable = false;  
	label3.autoSize = TextFieldAutoSize.LEFT;  
	label3.defaultTextFormat = myFormat;
	addChild(label3);
	
	// force these labels to be set
	nextMesh();
	nextTexture();
	nextBlendmode();
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
	
	// Initialize our mesh data
	initData();
	
	// The 3d back buffer size is in pixels (2=antialiased)
	context3D.configureBackBuffer(swfWidth, swfHeight, 2, true);

	// assemble all the shaders we need
	initShaders();

	myTexture1 = context3D.createTexture(
		myTextureData1.width, myTextureData1.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		myTexture1, myTextureData1.bitmapData);

	myTexture2 = context3D.createTexture(
		myTextureData2.width, myTextureData2.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		myTexture2, myTextureData2.bitmapData);

	myTexture3 = context3D.createTexture(
		myTextureData3.width, myTextureData3.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		myTexture3, myTextureData3.bitmapData);

	myTexture4 = context3D.createTexture(
		myTextureData4.width, myTextureData4.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		myTexture4, myTextureData4.bitmapData);

	myTexture5 = context3D.createTexture(
		myTextureData5.width, myTextureData5.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		myTexture5, myTextureData5.bitmapData);

	terrainTexture = context3D.createTexture(
		terrainTextureData.width, terrainTextureData.height,
		Context3DTextureFormat.BGRA, false);
	uploadTextureWithMipmaps(
		terrainTexture, terrainTextureData.bitmapData);

	// create projection matrix for our 3D scene
	projectionmatrix.identity();
	// 45 degrees FOV, 640/480 aspect ratio, 0.1=near, 100=far
	projectionmatrix.perspectiveFieldOfViewRH(
		45.0, swfWidth / swfHeight, 0.01, 5000.0);
	
	// create a matrix that defines the camera location
	viewmatrix.identity();
	// move the camera back a little so we can see the mesh
	viewmatrix.appendTranslation(0, 0, -1.5);

	// tilt the terrain a little so it is coming towards us
	terrainviewmatrix.identity();
	terrainviewmatrix.appendRotation(-60,Vector3D.X_AXIS);
	
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
	// parse the OBJ file and create buffers
	trace("Parsing the meshes...");
	myMesh1 = new Stage3dObjParser(
		myObjData1, context3D, 1, true, true);
	myMesh2 = new Stage3dObjParser(
		myObjData2, context3D, 1, true, true);
	myMesh3 = new Stage3dObjParser(
		myObjData3, context3D, 1, true, true);
	myMesh4 = new Stage3dObjParser(
		myObjData4, context3D, 1, true, true);
	myMesh5 = new Stage3dObjParser(
		myObjData5, context3D, 1, true, true);
	// parse the terrain mesh as well
	trace("Parsing the terrain...");
	terrainMesh = new Stage3dObjParser(
		terrainObjData, context3D, 1, true, true);
}		

private function renderMesh():void 
{
	if (blendNum > 1)
		// ignore depth zbuffer 
		// always draw polies even those that are behind others
		context3D.setDepthTest(false, Context3DCompareMode.LESS);
	else
		// use the depth zbuffer
		context3D.setDepthTest(true, Context3DCompareMode.LESS);
	
	// for our tests, don't cull any polies
	//context3D.setCulling(Context3DTriangleFace.NONE);
	// clear the transformation matrix to 0,0,0
	modelmatrix.identity();
	context3D.setProgram ( shaderProgram1 );
	setTexture();
	setBlendmode();
	modelmatrix.appendRotation(t*0.7, Vector3D.Y_AXIS);
	modelmatrix.appendRotation(t*0.6, Vector3D.X_AXIS);
	modelmatrix.appendRotation(t*1.0, Vector3D.Y_AXIS);
	// clear the matrix and append new angles
	modelViewProjection.identity();
	modelViewProjection.append(modelmatrix);
	modelViewProjection.append(viewmatrix);
	modelViewProjection.append(projectionmatrix);
	// pass our matrix data to the shader program
	context3D.setProgramConstantsFromMatrix(
		Context3DProgramType.VERTEX, 
		0, modelViewProjection, true );
	
	switch(meshNum)
	{
		case 0:
			myMesh = myMesh1;
		break;
		case 1:
			myMesh = myMesh2;
		break;
		case 2:
			myMesh = myMesh3;
		break;
		case 3:
			myMesh = myMesh4;
		break;
		case 4:
			myMesh = myMesh5;
		break;
	}
		
	// draw a mesh
	// position
	context3D.setVertexBufferAt(0, myMesh.positionsBuffer, 
		0, Context3DVertexBufferFormat.FLOAT_3);
	// tex coord
	context3D.setVertexBufferAt(1, myMesh.uvBuffer, 
		0, Context3DVertexBufferFormat.FLOAT_2);
	// vertex rgba
	context3D.setVertexBufferAt(2, myMesh.colorsBuffer, 
		0, Context3DVertexBufferFormat.FLOAT_4);
	// render it
	context3D.drawTriangles(myMesh.indexBuffer, 
		0, myMesh.indexBufferCount);		

}

private function renderTerrain():void
{
	// texture blending: no blending at all - opaque
	context3D.setBlendFactors(
		Context3DBlendFactor.ONE,
		Context3DBlendFactor.ZERO);
	// draw to depth zbuffer and do not draw polies that are obscured
	context3D.setDepthTest(true, Context3DCompareMode.LESS);
	// only render the front faces
	//context3D.setCulling(Context3DTriangleFace.FRONT);
	context3D.setTextureAt(0, terrainTexture);
	// simple textured shader
	context3D.setProgram ( shaderProgram1 );
	// position
	context3D.setVertexBufferAt(0, terrainMesh.positionsBuffer, 
		0, Context3DVertexBufferFormat.FLOAT_3);
	// tex coord
	context3D.setVertexBufferAt(1, terrainMesh.uvBuffer, 
		0, Context3DVertexBufferFormat.FLOAT_2);
	// vertex rgba
	context3D.setVertexBufferAt(2, terrainMesh.colorsBuffer, 
		0, Context3DVertexBufferFormat.FLOAT_4);
	// set up camera angle
	modelmatrix.identity();
	// make the terrain face the right way
	modelmatrix.appendRotation( -90, Vector3D.Y_AXIS);
	// slowly move the terrain around
	modelmatrix.appendTranslation(
		Math.cos(t/300)*1000,Math.cos(t/200)*1000 + 500,-130); 
	// clear the matrix and append new angles
	modelViewProjection.identity();
	modelViewProjection.append(modelmatrix);
	modelViewProjection.append(terrainviewmatrix);
	modelViewProjection.append(projectionmatrix);	
	// pass our matrix data to the shader program
	context3D.setProgramConstantsFromMatrix(
		Context3DProgramType.VERTEX, 
		0, modelViewProjection, true );
	context3D.drawTriangles(terrainMesh.indexBuffer, 
		0, terrainMesh.indexBufferCount);		
}

private function keyPressed(event:KeyboardEvent):void 
{
	switch(event.charCode)
	{
		case 98: // the b key
			nextBlendmode();
		break;
		case 109: // the m key
			nextMesh();
		break;
		case 116: // the t key
			nextTexture();
		break;
	}
}

private function nextBlendmode():void 
{
	blendNum++;
	if (blendNum > blendNumMax)
	blendNum = 0;
	
	switch(blendNum)
	{
		case 0:
			label1.text = '[B] ONE,ZERO';
		break;
		case 1:
			label1.text = '[B] SOURCE_ALPHA,ONE_MINUS_SOURCE_ALPHA';
		break;
		case 2:
			label1.text = '[B] SOURCE_COLOR,ONE';
		break;
		case 3:
			label1.text = '[B] ONE,ONE';
		break;
		case 4:
			label1.text = '[B] DESTINATION_COLOR,ZERO';
		break;
	}
}

private function nextTexture():void 
{
	texNum++;
	if (texNum > texNumMax)
	texNum = 0;
	switch(texNum)
	{
		case 0:
			label2.text = '[T] Transparent Leaf Texture';
		break;
		case 1:
			label2.text = '[T] Fire Texture';
		break;
		case 2:
			label2.text = '[T] Lens Flare Texture';
		break;
		case 3:
			label2.text = '[T] Glow Texture';
		break;
		case 4:
			label2.text = '[T] Smoke Texture';
		break;
	}
}

private function nextMesh():void 
{
	meshNum++;
	if (meshNum > meshNumMax)
	meshNum = 0;
	switch(meshNum)
	{
		case 0:
			label3.text = '[M] Random Particle Cluster';
		break;
		case 1:
			label3.text = '[M] Round Puff Cluster';
		break;
		case 2:
			label3.text = '[M] Cube Model';
		break;
		case 3:
			label3.text = '[M] Sphere Model';
		break;
		case 4:
			label3.text = '[M] Spaceship Model';
		break;
	}
}

private function setTexture():void 
{
	switch(texNum)
	{
		case 0:	
			context3D.setTextureAt(0, myTexture1);
		break;
		case 1:	
			context3D.setTextureAt(0, myTexture2);
		break;
		case 2:	
			context3D.setTextureAt(0, myTexture3);
		break;
		case 3:	
			context3D.setTextureAt(0, myTexture4);
		break;
		case 4:	
			context3D.setTextureAt(0, myTexture5);
		break;
	}
}

private function setBlendmode():void 
{
	// All possible blendmodes:
	// Context3DBlendFactor.DESTINATION_ALPHA
	// Context3DBlendFactor.DESTINATION_COLOR
	// Context3DBlendFactor.ONE
	// Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA
	// Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR
	// Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
	// Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR
	// Context3DBlendFactor.SOURCE_ALPHA
	// Context3DBlendFactor.SOURCE_COLOR
	// Context3DBlendFactor.ZERO
	switch(blendNum)
	{
		case 0:
			// the default: nice for opaque textures
			context3D.setBlendFactors(
				Context3DBlendFactor.ONE,
				Context3DBlendFactor.ZERO);
		break;
		case 1:
			// perfect for transparent textures like foliage/fences/fonts
			context3D.setBlendFactors(
				Context3DBlendFactor.SOURCE_ALPHA,
				Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		break;
		case 2:
			// perfect to make it lighten the scene only (black is not drawn)
			context3D.setBlendFactors(
				Context3DBlendFactor.SOURCE_COLOR,
				Context3DBlendFactor.ONE);
		break;
		case 3:
			// just lightens the scene - great for particles
			context3D.setBlendFactors(
				Context3DBlendFactor.ONE,
				Context3DBlendFactor.ONE);
		break;
		case 4:
			// perfect for when you want to darken only (smoke, etc)
			context3D.setBlendFactors(
				Context3DBlendFactor.DESTINATION_COLOR,
				Context3DBlendFactor.ZERO);
		break;
	}
}

private function enterFrame(e:Event):void 
{
	// clear scene before rendering is mandatory
	context3D.clear(0,0,0); 
	// move or rotate more each frame
	t += 2.0;
	// scroll and render the terrain once
	renderTerrain();
	// render whatever mesh is selected
	renderMesh();
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
		fpsTf.text = fps.toFixed(1) + " fps";
		fpsTicks = 0;
		fpsLast = now;
	}
	// update the rest of the GUI
	updateScore();
}

} // end of class
} // end of package
