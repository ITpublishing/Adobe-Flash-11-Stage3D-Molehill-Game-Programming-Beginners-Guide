// Stage3d game entity class version 1.31
// gratefully adapted from work by Alejandro Santander
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

public class Stage3dEntity
{
	// Matrix variables (position, rotation, etc.)
	private var _transform:Matrix3D;
	private var _inverseTransform:Matrix3D;
	private var _transformNeedsUpdate:Boolean;
	private var _valuesNeedUpdate:Boolean;
	private var _x:Number = 0;
	private var _y:Number = 0;
	private var _z:Number = 0;
	private var _rotationDegreesX:Number = 0;
	private var _rotationDegreesY:Number = 0;
	private var _rotationDegreesZ:Number = 0;
	private var _scaleX:Number = 1;
	private var _scaleY:Number = 1;
	private var _scaleZ:Number = 1;
	private const RAD_TO_DEG:Number = 180/Math.PI;
	
	// Stage3d objects (public so they can be inherited)
	public var context:Context3D;
	public var vertexBuffer:VertexBuffer3D;
	public var indexBuffer:IndexBuffer3D;
	public var shader:Program3D;
	public var texture:Texture;
	public var mesh:Stage3dObjParser;
	// Render modes:
	public var cullingMode:String = Context3DTriangleFace.FRONT;
	public var blendSrc:String = Context3DBlendFactor.ONE;
	public var blendDst:String = Context3DBlendFactor.ZERO;
	public var depthTestMode:String = Context3DCompareMode.LESS;
	public var depthTest:Boolean = true;
	public var depthDraw:Boolean = true;

	// used only for stats
	public var polycount:uint = 0;

	// if this is set entity is "stuck" to another
	public var following:Stage3dEntity;
	
	// optimize what data we need to send to Stage3D
	// this depends on what the shaders require
	public var shaderUsesUV:Boolean = true;
	public var shaderUsesRgba:Boolean = true;
	public var shaderUsesNormals:Boolean = false;
	
	// Class Constructor
	public function Stage3dEntity(
		mydata:Class = null,
		mycontext:Context3D = null,
		myshader:Program3D = null,
		mytexture:Texture = null,
		modelscale:Number = 1,
		flipAxis:Boolean = true,
		flipTexture: Boolean = true)
	{
		_transform = new Matrix3D();
		context = mycontext;
		shader = myshader;
		texture = mytexture;
		if (mydata && context) 
		{
			mesh = new Stage3dObjParser(
				mydata, context, modelscale, flipAxis, flipTexture);
			polycount = mesh.indexBufferCount;
			trace("Mesh has " + polycount + " polygons.");
		}
	}

    public function get transform():Matrix3D
    {
        if(_transformNeedsUpdate)
            updateTransformFromValues();
        return _transform;
    }

    public function set transform(value:Matrix3D):void
    {
        _transform = value;
        _transformNeedsUpdate = false;
        _valuesNeedUpdate = true;
    }

    // Position:

    public function set position(value:Vector3D):void
    {
        _x = value.x;
        _y = value.y;
        _z = value.z;
        _transformNeedsUpdate = true;
    }

    private var _posvec:Vector3D = new Vector3D();
	public function get position():Vector3D
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
		// optimization: avoid creating temporary variable
        // e.g. return new Vector3D(_x, _y, _z);
		_posvec.setTo(_x, _y, _z);
		return _posvec;
    }

    public function set x(value:Number):void
    {
        _x = value;
        _transformNeedsUpdate = true;
    }
    public function get x():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _x;
    }

    public function set y(value:Number):void
    {
        _y = value;
        _transformNeedsUpdate = true;
    }
    public function get y():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _y;
    }

    public function set z(value:Number):void
    {
        _z = value;
        _transformNeedsUpdate = true;
    }
    public function get z():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _z;
    }

    // Rotation:

    public function set rotationDegreesX(value:Number):void
    {
        _rotationDegreesX = value;
        _transformNeedsUpdate = true;
    }
    public function get rotationDegreesX():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _rotationDegreesX;
    }

    public function set rotationDegreesY(value:Number):void
    {
        _rotationDegreesY = value;
        _transformNeedsUpdate = true;
    }
    public function get rotationDegreesY():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _rotationDegreesY;
    }

    public function set rotationDegreesZ(value:Number):void
    {
        _rotationDegreesZ = value;
        _transformNeedsUpdate = true;
    }
    public function get rotationDegreesZ():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _rotationDegreesZ;
    }

    // Scale:

    public function set scale(vec:Vector3D):void
    {
        _scaleX = vec.x;
        _scaleY = vec.y;
        _scaleZ = vec.z;
        _transformNeedsUpdate = true;
    }
    private var _scalevec:Vector3D = new Vector3D();
	public function get scale():Vector3D
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        //return new Vector3D(_scaleX, _scaleY, _scaleZ, 1.0);
		
		// optimization: avoid creating a temporary variable
		_scalevec.setTo(_scaleX, _scaleX, _scaleZ);
		_scalevec.w = 1.0;
		return _scalevec;
    }
    public function set scaleXYZ(value:Number):void
    {
        _scaleX = value;
        _scaleY = value;
        _scaleZ = value;
        _transformNeedsUpdate = true;
    }
    public function get scaleXYZ():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _scaleX; // impossible to determine
        _transformNeedsUpdate = true;
    }
    public function set scaleX(value:Number):void
    {
        _scaleX = value;
        _transformNeedsUpdate = true;
    }
    public function get scaleX():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _scaleX;
    }

    public function set scaleY(value:Number):void
    {
        _scaleY = value;
        _transformNeedsUpdate = true;
    }
    public function get scaleY():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _scaleY;
    }

    public function set scaleZ(value:Number):void
    {
        _scaleZ = value;
        _transformNeedsUpdate = true;
    }
    public function get scaleZ():Number
    {
        if(_valuesNeedUpdate)
            updateValuesFromTransform();
        return _scaleZ;
    }

    // Update:

    public function updateTransformFromValues():void
    {
        _transform.identity();

        _transform.appendRotation(
			_rotationDegreesX, Vector3D.X_AXIS);
        _transform.appendRotation(
			_rotationDegreesY, Vector3D.Y_AXIS);
        _transform.appendRotation(
			_rotationDegreesZ, Vector3D.Z_AXIS);

        // avoid matrix error #2183: 
		// scale values must not be zero
		if (_scaleX == 0) _scaleX = 0.0000001;
		if (_scaleY == 0) _scaleY = 0.0000001;
		if (_scaleZ == 0) _scaleZ = 0.0000001;
		_transform.appendScale(_scaleX, _scaleY, _scaleZ);

        _transform.appendTranslation(_x, _y, _z);

        _transformNeedsUpdate = false;
    }

    public function updateValuesFromTransform():void
    {
        var d:Vector.<Vector3D> = _transform.decompose();

        var position:Vector3D = d[0];
        _x = position.x;
        _y = position.y;
        _z = position.z;

        var rotation:Vector3D = d[1];
        _rotationDegreesX = rotation.x*RAD_TO_DEG;
        _rotationDegreesY = rotation.y*RAD_TO_DEG;
        _rotationDegreesZ = rotation.z*RAD_TO_DEG;

        var scale:Vector3D = d[2];
        _scaleX = scale.x;
        _scaleY = scale.y;
        _scaleZ = scale.z;

        _valuesNeedUpdate = false;
    }

    // Movement Utils:

    // move according to the direction we are facing
	public function moveForward(amt:Number):void
    {
		if (_transformNeedsUpdate) 
			updateTransformFromValues();
		var v:Vector3D = frontvector;
		v.scaleBy(-amt)
		transform.appendTranslation(v.x, v.y, v.z);
		_valuesNeedUpdate = true;
    }
    public function moveBackward(amt:Number):void
    {
		if (_transformNeedsUpdate) 
			updateTransformFromValues();
		var v:Vector3D = backvector;
		v.scaleBy(-amt)
		transform.appendTranslation(v.x, v.y, v.z);
		_valuesNeedUpdate = true;
    }
    public function moveUp(amt:Number):void
    {
		if (_transformNeedsUpdate) 
			updateTransformFromValues();
		var v:Vector3D = upvector;
		v.scaleBy(amt)
		transform.appendTranslation(v.x, v.y, v.z);
		_valuesNeedUpdate = true;
    }
    public function moveDown(amt:Number):void
    {
		if (_transformNeedsUpdate) 
			updateTransformFromValues();
		var v:Vector3D = downvector;
		v.scaleBy(amt)
		transform.appendTranslation(v.x, v.y, v.z);
		_valuesNeedUpdate = true;
    }
	public function moveLeft(amt:Number):void
    {
		if (_transformNeedsUpdate) 
			updateTransformFromValues();
		var v:Vector3D = leftvector;
		v.scaleBy(amt)
		transform.appendTranslation(v.x, v.y, v.z);
		_valuesNeedUpdate = true;
    }
    public function moveRight(amt:Number):void
    {
		if (_transformNeedsUpdate) 
			updateTransformFromValues();
		var v:Vector3D = rightvector;
		v.scaleBy(amt)
		transform.appendTranslation(v.x, v.y, v.z);
		_valuesNeedUpdate = true;
    }
	
    // optimization: these vectors are defined as constants
	// to avoid creation of temporary variables each frame
	private static const vecft:Vector3D = new Vector3D(0, 0, 1);
    private static const vecbk:Vector3D = new Vector3D(0, 0, -1);
    private static const veclf:Vector3D = new Vector3D(-1, 0, 0);
    private static const vecrt:Vector3D = new Vector3D(1, 0, 0);
    private static const vecup:Vector3D = new Vector3D(0, 1, 0);
    private static const vecdn:Vector3D = new Vector3D(0, -1, 0);

    public function get frontvector():Vector3D
    {
        if(_transformNeedsUpdate)
            updateTransformFromValues();
        return transform.deltaTransformVector(vecft);
    }

    public function get backvector():Vector3D
    {
        if(_transformNeedsUpdate)
            updateTransformFromValues();
        return transform.deltaTransformVector(vecbk);
    }

    public function get leftvector():Vector3D
    {
        if(_transformNeedsUpdate)
            updateTransformFromValues();
        return transform.deltaTransformVector(veclf);
    }

    public function get rightvector():Vector3D
    {
        if(_transformNeedsUpdate)
            updateTransformFromValues();
        return transform.deltaTransformVector(vecrt);
    }

    public function get upvector():Vector3D
    {
        if(_transformNeedsUpdate)
            updateTransformFromValues();
        return transform.deltaTransformVector(vecup);
    }

    public function get downvector():Vector3D
    {
        if(_transformNeedsUpdate)
            updateTransformFromValues();
        return transform.deltaTransformVector(vecdn);
    }

    // Handy Utils:

    public function get rotationTransform():Matrix3D
    {
        var d:Vector.<Vector3D> = transform.decompose();
        d[0] = new Vector3D();
        d[1] = new Vector3D(1, 1, 1);
        var t:Matrix3D = new Matrix3D();
        t.recompose(d);
        return t;
    }

    public function get reducedTransform():Matrix3D
    {
        var raw:Vector.<Number> = transform.rawData;
        raw[3] = 0; // Remove translation.
        raw[7] = 0;
        raw[11] = 0;
        raw[15] = 1;
        raw[12] = 0;
        raw[13] = 0;
        raw[14] = 0;
        var reducedTransform:Matrix3D = new Matrix3D();
        reducedTransform.copyRawDataFrom(raw);
        return reducedTransform;
    }

    public function get invRotationTransform():Matrix3D
    {
        var t:Matrix3D = rotationTransform;
        t.invert();
        return t;
    }

    public function get positionVector():Vector.<Number>
    {
        return Vector.<Number>([_x, _y, _z, 1.0]);
    }

    public function get inverseTransform():Matrix3D
    {
        _inverseTransform = transform.clone();
        _inverseTransform.invert();

        return _inverseTransform;
    }

	public function posString():String
	{
		if (_valuesNeedUpdate)
			updateValuesFromTransform();
		
		return _x.toFixed(2) + ',' 
			+ _y.toFixed(2) + ',' 
			+ _z.toFixed(2);
	}
	
	public function rotString():String
	{
		if (_valuesNeedUpdate)
			updateValuesFromTransform();
		
		return _rotationDegreesX.toFixed(2) + ',' 
			+ _rotationDegreesY.toFixed(2) + ',' 
			+ _rotationDegreesZ.toFixed(2);
	}
	
	public function follow(thisentity:Stage3dEntity):void
	{
		following = thisentity;
	}
	
	// create an exact duplicate in the game world
	// whle re-using all Stage3d objects
	public function clone():Stage3dEntity
	{
        if(_transformNeedsUpdate)
            updateTransformFromValues();
		var myclone:Stage3dEntity = new Stage3dEntity();
		myclone.transform = this.transform.clone();
		myclone.mesh = this.mesh;
		myclone.texture = this.texture;
		myclone.shader = this.shader;
		myclone.vertexBuffer = this.vertexBuffer;
		myclone.indexBuffer = this.indexBuffer;
		myclone.context = this.context;
		myclone.polycount = this.polycount;
		myclone.shaderUsesNormals = this.shaderUsesNormals;
		myclone.shaderUsesRgba = this.shaderUsesRgba;
		myclone.shaderUsesUV = this.shaderUsesUV;
		myclone.updateValuesFromTransform();
		return myclone;
	}
	
	// optimization: reuse the same temporary matrix
	private var _rendermatrix:Matrix3D = new Matrix3D();
	// renders the entity, changing states only if required
	public function render(
		view:Matrix3D,
		projection:Matrix3D,
		statechanged:Boolean = true):void
	{
		// used only for debugging:
		if (!mesh) trace("Missing mesh!");
		if (!context) trace("Missing context!");
		if (!shader) trace("Missing shader!");
		
		// only render if these are set
		if (!mesh) return;
		if (!context) return;
		if (!shader) return;
		
		//Reset our matrix
		_rendermatrix.identity();
		_rendermatrix.append(transform);
		if (following) _rendermatrix.append(following.transform);

		/*
		// for lighting, we may need to transform the vertex
		// normals based on the orientation of the mesh only = vc1
		context.setProgramConstantsFromMatrix(
			Context3DProgramType.VERTEX, 1, _rendermatrix, false);
		*/

		_rendermatrix.append(view);
		_rendermatrix.append(projection);
		
		// Set the vertex program register vc0 to our
		// model view projection matrix = vc0
		context.setProgramConstantsFromMatrix(
			Context3DProgramType.VERTEX, 0, _rendermatrix, true);
			
		// optimization: only change render state
		// if the previously rendered actor is not
		// using an identical mesh/shader as the current one
		if (statechanged)
		{
			// Set the AGAL program
			context.setProgram(shader);
			
			// Set the fragment program register ts0 to a texture
			if (texture) context.setTextureAt(0,texture);

			// position
			context.setVertexBufferAt(0, mesh.positionsBuffer, 
				0, Context3DVertexBufferFormat.FLOAT_3);
			// tex coord
			if (shaderUsesUV)
				context.setVertexBufferAt(1, mesh.uvBuffer, 
				0, Context3DVertexBufferFormat.FLOAT_2);
			else
				context.setVertexBufferAt(1, null);
			// vertex rgba
			if (shaderUsesRgba)
				context.setVertexBufferAt(2, mesh.colorsBuffer, 
				0, Context3DVertexBufferFormat.FLOAT_4);
			else
				context.setVertexBufferAt(2, null);
			// vertex normal
			if (shaderUsesNormals)
				context.setVertexBufferAt(3, mesh.normalsBuffer, 
				0, Context3DVertexBufferFormat.FLOAT_3);
			else
				context.setVertexBufferAt(3, null);
			
			context.setBlendFactors(blendSrc, blendDst);
			context.setDepthTest(depthTest,depthTestMode);
			context.setCulling(cullingMode);
			context.setColorMask(true, true, true, depthDraw);
		}
		
		// render it
		context.drawTriangles(mesh.indexBuffer, 
			0, mesh.indexBufferCount);		

	}
	
} // end class

} // end package