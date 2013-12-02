// Game particle class version 1.0
//
package
{

import com.adobe.utils.*;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.*;
import flash.display3D.textures.*;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

public class Stage3dParticle extends Stage3dEntity
{
	public var active:Boolean = true;
	public var age:uint = 0;
	public var ageMax:uint = 1000;
	public var stepCounter:uint = 0;

	private var mesh2:Stage3dObjParser;
	private var ageScale:Vector.<Number> = 
		new Vector.<Number>([1, 0, 1, 1]);
	private var rgbaScale:Vector.<Number> = 
		new Vector.<Number>([1, 1, 1, 1]);
	private var startSize:Number = 0;
	private var endSize:Number = 1;
	
	// Class Constructor - the second mesh defines the 
	// ending positions of each vertex in the first
	public function Stage3dParticle(
		mydata:Class = null,
		mycontext:Context3D = null,
		mytexture:Texture = null,
		mydata2:Class = null
		)
	{
		transform = new Matrix3D();
		context = mycontext;
		texture = mytexture;
		
		// use a shader specifically designed for particles
		// this version is for two frames: interpolating from one
		// mesh to another over time
		if (context && mydata2) initParticleShader(true);
		// only one mesh defined: use the simpler shader
		else if (context) initParticleShader(false);
		
		if (mydata && context) 
		{
			mesh = new Stage3dObjParser(
				mydata, context, 1, true, true);
			polycount = mesh.indexBufferCount;
			trace("Mesh has " + polycount + " polygons.");
		}

		// parse the second mesh
		if (mydata2 && context) 
			mesh2 = new Stage3dObjParser(
				mydata2, context, 1, true, true);
				
		// default a render state suitable for particles
		blendSrc = Context3DBlendFactor.ONE;
		blendDst = Context3DBlendFactor.ONE;
		cullingMode = Context3DTriangleFace.NONE;
		depthTestMode = Context3DCompareMode.ALWAYS;
		depthTest = false;
	}
	
	public function cloneparticle():Stage3dParticle
	{
		var myclone:Stage3dParticle = new Stage3dParticle();
        updateTransformFromValues();
		myclone.transform = this.transform.clone();
		myclone.mesh = this.mesh;
		myclone.texture = this.texture;
		myclone.shader = this.shader;
		myclone.vertexBuffer = this.vertexBuffer;
		myclone.indexBuffer = this.indexBuffer;
		myclone.context = this.context;
		myclone.updateValuesFromTransform();
		myclone.mesh2 = this.mesh2;
		myclone.startSize = this.startSize;
		myclone.endSize = this.endSize;
		myclone.polycount = this.polycount;
		return myclone;
	}
	
	private var twoPi:Number = 2*Math.PI;
	// returns a float from -amp to +amp in wobbles per second
	private function wobble(
		ms:Number = 0, amp:Number = 1, spd:Number = 1):Number 
	{
		var val:Number;
		val = amp*Math.sin((ms/1000)*spd*twoPi);
		return val;
	}

	// returns a float that oscillates from 0..1..0 each second
	private function wobble010(ms:Number):Number 
	{
		var retval:Number;
		retval = wobble(ms-250, 0.5, 1.0) + 0.5;
		return retval;
	}

	public function step(ms:uint):void
	{
		stepCounter++;
		age += ms;
		if (age >= ageMax)
		{
			//trace("Particle died (" + age + "ms)");
			active = false;
			return;
		}
		// based on age, change the scale for starting pos (1..0)
		ageScale[0] = 1 - (age / ageMax);
		// based on age, change the scale for ending pos (0..1)
		ageScale[1] = age / ageMax;
		// based on age: go from 0..1..0
		ageScale[2] = wobble010(age);
		// ensure it is within the valid range
		if (ageScale[0] < 0) ageScale[0] = 0;
		if (ageScale[0] > 1) ageScale[0] = 1;
		if (ageScale[1] < 0) ageScale[1] = 0;
		if (ageScale[1] > 1) ageScale[1] = 1;
		if (ageScale[2] < 0) ageScale[2] = 0;
		if (ageScale[2] > 1) ageScale[2] = 1;
		// fade alpha in and out
		rgbaScale[0] = ageScale[0];
		rgbaScale[1] = ageScale[0];
		rgbaScale[2] = ageScale[0];
		rgbaScale[3] = ageScale[2];
	}

	public function respawn(
		pos:Matrix3D, maxage:uint = 1000, 
		scale1:Number = 0, scale2:Number = 50):void
	{
		age = 0;
		stepCounter = 0;
		ageMax = maxage;
		transform = pos.clone();
		updateValuesFromTransform();
		rotationDegreesX = 180; // point "down"
		// start at a random orientation each time
		rotationDegreesY = Math.random() * 360 - 180;
		updateTransformFromValues();
		ageScale[0] = 1;
		ageScale[1] = 0;
		ageScale[2] = 0;
		ageScale[3] = 1;
		rgbaScale[0] = 1;
		rgbaScale[1] = 1;
		rgbaScale[2] = 1;
		rgbaScale[3] = 1;
		startSize = scale1;
		endSize = scale2;
		active = true;
		//trace("Respawned particle at " + posString());
	}

	// optimization: reuse the same temporary matrix
	private var _rendermatrix:Matrix3D = new Matrix3D();
	override public function render(
		view:Matrix3D,
		projection:Matrix3D,
		statechanged:Boolean = true):void
	{
		// only render if these are set
		if (!active) return;
		if (!mesh) return;
		if (!context) return;
		if (!shader) return;
		if (!texture) return;
		
		// get bigger over time
		scaleXYZ = startSize + 
			((endSize - startSize) * ageScale[1]);
		
		//Reset our matrix
		_rendermatrix.identity();
		_rendermatrix.append(transform);
		if (following) _rendermatrix.append(following.transform);
		_rendermatrix.append(view);
		_rendermatrix.append(projection);
		
		// Set the vertex program register vc0
		// to our model view projection matrix
		context.setProgramConstantsFromMatrix(
			Context3DProgramType.VERTEX, 0, _rendermatrix, true); 
		
		// Set the vertex program register vc4
		// to our time scale from (0..1)
		// used to interpolate vertex position over time
		context.setProgramConstantsFromVector(
			Context3DProgramType.VERTEX, 4, ageScale);

		// Set the fragment program register fc0
		// to our time scale from (0..1)
		// used to interpolate transparency over time
		context.setProgramConstantsFromVector(
			Context3DProgramType.FRAGMENT, 0, rgbaScale);

		// Set the AGAL program
		context.setProgram(shader);
		// Set the fragment program register ts0 to a texture
		context.setTextureAt(0,texture);
		// starting position (va0)
		context.setVertexBufferAt(0, mesh.positionsBuffer, 
			0, Context3DVertexBufferFormat.FLOAT_3);
		// tex coords (va1)
		context.setVertexBufferAt(1, mesh.uvBuffer, 
			0, Context3DVertexBufferFormat.FLOAT_2);
		// final position (va2)
		if (mesh2)
		{
			context.setVertexBufferAt(2, mesh2.positionsBuffer, 
				0, Context3DVertexBufferFormat.FLOAT_3);
		}

		// set the render state
		context.setBlendFactors(blendSrc, blendDst);
		context.setDepthTest(depthTest,depthTestMode);
		context.setCulling(cullingMode);

		// render it
		context.drawTriangles(mesh.indexBuffer, 
			0, mesh.indexBufferCount);		
	} // render function ends

	private function initParticleShader(twomodels:Boolean=false):void
	{
		var vertexShader:AGALMiniAssembler = 
			new AGALMiniAssembler();
		var fragmentShader:AGALMiniAssembler 
			= new AGALMiniAssembler();
		
		if (twomodels)
		{		
			trace("Compiling the TWO FRAME particle shader...");
			vertexShader.assemble
			( 
				Context3DProgramType.VERTEX,
				// scale the starting position
				"mul vt0, va0, vc4.xxxx\n" + 
				// scale the ending position
				"mul vt1, va2, vc4.yyyy\n" + 
				// interpolate the two positions
				"add vt2, vt0, vt1\n" + 
				// 4x4 matrix multiply to get camera angle	
				"m44 op, vt2, vc0\n" +
				// tell fragment shader about UV
				"mov v1, va1"
			);
		}
		else
		{
			trace("Compiling the ONE FRAME particle shader...");
			vertexShader.assemble
			( 
				Context3DProgramType.VERTEX,
				// get the vertex pos multiplied by camera angle
				"m44 op, va0, vc0\n" +
				// tell fragment shader about UV
				"mov v1, va1"
			);
		}
		
		// textured using UV coordinates
		fragmentShader.assemble
		( 
			Context3DProgramType.FRAGMENT,	
			// grab the texture color from texture 0 
			// and uv coordinates from varying register 1
			// and store the interpolated value in ft0
			"tex ft0, v1, fs0 <2d,linear,repeat,miplinear>\n" +
			// multiply by "fade" color register (fc0)
			"mul ft0, ft0, fc0\n" + 
			// move this value to the output color
			"mov oc, ft0\n"
		);
		
		// combine shaders into a program and upload to the GPU
		shader = context.createProgram();
		shader.upload(
			vertexShader.agalcode, 
			fragmentShader.agalcode);

	} // end initParticleShader function

} // end class

} // end package
