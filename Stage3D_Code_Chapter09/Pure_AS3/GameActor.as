// Game actor class version 1.1
// an entity that can move, shoot, spawn particles
// trigger sounds and detect collisions
//
package
{

import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.display3D.Context3D;
import flash.display3D.Program3D;
import flash.display3D.textures.Texture;
import flash.media.Sound;

public class GameActor extends Stage3dEntity
{
	// game-related stats
	public var name:String = ''; // unique
	public var classname:String = ''; // not unique
	public var owner:GameActor; // so you can't shoot yourself
	public var touching:GameActor; // last collision detected
	public var active:Boolean = true; // animate?
	public var visible:Boolean = true; // render?
	public var health:Number = 1; // when zero, die
	public var damage:Number = 250; // inflicted on others
	public var points:Number = 25; // score earned if destroyed
	public var collides:Boolean = false; // check hits?
	public var collidemode:uint = 0; // 0=sphere, 1=aabb
	public var radius:Number = 1; // used for sphere collision
	public var aabbMin:Vector3D = new Vector3D(1, 1, 1, 1);
	public var aabbMax:Vector3D = new Vector3D(1, 1, 1, 1);
	// callback functions
	public var runConstantly:Function;
	public var runConstantlyDelay:uint = 1000;
	public var runWhenNoHealth:Function;
	public var runWhenMaxAge:Function;
	public var runWhenCreated:Function;
	// time-related vars
	public var age:uint = 0;
	public var ageMax:uint = 0;
	public var stepCounter:uint = 0;
	// animation vars in units per SECOND (1000ms)
	public var posVelocity:Vector3D;
	public var rotVelocity:Vector3D;
	public var scaleVelocity:Vector3D;
	public var tintVelocity:Vector3D;
	// automatically shoot bullets when 'near' an enemy
	public var bullets:GameActorpool;
	public var shootName:String = '';
	public var shootDelay:uint = 4000;
	public var shootNext:uint = 0;
	public var shootRandomDelay:Number = 2000;
	public var shootDist:Number = 100;
	public var shootAt:GameActor = null;
	public var shootVelocity:Number = 50;
	public var shootSound:Sound;
	// spawnable particles
	public var particles:GameParticlesystem;
	public var spawnConstantly:String = '';
	public var spawnConstantlyDelay:uint = 0;
	public var spawnConstantlyNext:uint = 0;
	public var spawnWhenNoHealth:String = '';
	public var spawnWhenMaxAge:String = '';
	public var spawnWhenCreated:String = '';
	// sound effects
	public var soundConstantlyDelay:uint = 1000;
	public var soundConstantlyNext:uint = 0;
	public var soundConstantly:Sound;
	public var soundWhenNoHealth:Sound;
	public var soundWhenMaxAge:Sound;
	public var soundWhenCreated:Sound;
	
	public function GameActor(mydata:Class = null,
		mycontext:Context3D = null,
		myshader:Program3D = null,
		mytexture:Texture = null,
		modelscale:Number = 1,
		flipAxis:Boolean = true,
		flipTexture: Boolean = true)
	{
		super(mydata, mycontext, myshader, mytexture, 
			modelscale, flipAxis, flipTexture);
	}
	
	public function step(ms:uint):void
	{
		if (!active) return;
		
		age += ms;
		stepCounter++;
		
		if (health <= 0)
		{
			//trace(name + " out of health.");
			if (particles && spawnWhenNoHealth)
			{
				trace(name + " exploding into " + spawnWhenNoHealth);
				var spawnxform:Matrix3D = new Matrix3D();
				spawnxform.position = position.clone();
				//particles.spawn(spawnWhenNoHealth,transform);
				particles.spawn(spawnWhenNoHealth,spawnxform,5555,0,10);
			}
			if (soundWhenNoHealth)
				soundWhenNoHealth.play();
			if (runWhenNoHealth != null)
				runWhenNoHealth();
			die();
			return;
		}
		
		if ((ageMax != 0) && (age >= ageMax))
		{
			//trace(name + " old age.");
			if (particles && spawnWhenMaxAge)
				particles.spawn(spawnWhenMaxAge, transform);
			if (soundWhenMaxAge)
				soundWhenMaxAge.play();
			if (runWhenMaxAge != null)
				runWhenMaxAge();
			die();
			return;
		}

		if (posVelocity)
		{
			x += posVelocity.x * (ms / 1000);
			y += posVelocity.y * (ms / 1000);
			z += posVelocity.z * (ms / 1000);
		}
		
		if (rotVelocity)
		{
			rotationDegreesX += rotVelocity.x * (ms / 1000);
			rotationDegreesY += rotVelocity.y * (ms / 1000);
			rotationDegreesZ += rotVelocity.z * (ms / 1000);
		}

		if (scaleVelocity)
		{
			scaleX += scaleVelocity.x * (ms / 1000);
			scaleY += scaleVelocity.y * (ms / 1000);
			scaleZ += scaleVelocity.z * (ms / 1000);
		}

		// maybe spawn a new particle
		if (visible && particles && spawnConstantlyDelay > 0)
		{
			if (spawnConstantly != '')
			{
				if (age >= spawnConstantlyNext)
				{
					//trace("actor spawn " + spawnConstantly);
					spawnConstantlyNext = 
						age + spawnConstantlyDelay;
					particles.spawn(spawnConstantly, transform);
				}
			}
		}
		
		// maybe trigger a sound
		if (visible && soundConstantlyDelay > 0)
		{
			if (soundConstantly)
			{
				if (age >= soundConstantlyNext)
				{
					soundConstantlyNext = 
						age + soundConstantlyDelay;
					soundConstantly.play();
				}
			}
		}

		// maybe "shoot" (spawn an actor)
		if (visible && bullets && (shootName != ''))
		{
			var shouldShoot:Boolean = false;
			if (age >= shootNext)
			{
				shootNext = age + shootDelay + 
					(Math.random() * shootRandomDelay);
				
				if (shootDist < 0) 
					shouldShoot = true;
				else if (shootAt &&
						(shootDist > 0) &&
						(Vector3D.distance(
							position, shootAt.position) <= shootDist))
				{
					shouldShoot = true;	
				}
		
				if (shouldShoot)
				{
					var b:GameActor = 
						bullets.spawn(shootName, transform);

					// remember who this bullet belongs to	
					b.owner = this;
					
					// aim towards an enemy?
					if (shootAt)
					{
						b.transform.pointAt(
							shootAt.transform.position);
						b.rotationDegreesY -= 90;
						
						b.posVelocity = 
							b.transform.position.subtract(
							shootAt.transform.position);
						b.posVelocity.normalize();
						b.posVelocity.negate();
						b.posVelocity.scaleBy(shootVelocity);
					}
					// otherwise we simply fire in whatever
					// direction was given during spawn
					// when the game set posVelocity

					if (shootSound) 
						shootSound.play();
				}
			}
		}
	}

	public function cloneactor():GameActor
	{
		var myclone:GameActor = new GameActor();
        updateTransformFromValues();
		myclone.transform = this.transform.clone();
		myclone.updateValuesFromTransform();
		myclone.mesh = this.mesh;
		myclone.texture = this.texture;
		myclone.shader = this.shader;
		myclone.vertexBuffer = this.vertexBuffer;
		myclone.indexBuffer = this.indexBuffer;
		myclone.context = this.context;
		myclone.polycount = this.polycount;
		myclone.blendSrc = this.blendSrc;
		myclone.blendDst = this.blendDst;
		myclone.cullingMode = this.cullingMode;
		myclone.depthTestMode = this.depthTestMode;
		myclone.depthTest = this.depthTest;
		myclone.depthDraw = this.depthDraw;
		// game-related stats
		myclone.name = this.name;
		myclone.classname = this.classname;
		myclone.owner = this.owner;
		myclone.active = this.active;
		myclone.visible = this.visible;
		myclone.health = this.health;
		myclone.damage = this.damage;
		myclone.points = this.points;
		myclone.collides = this.collides;
		myclone.collidemode = this.collidemode;
		myclone.radius = this.radius;
		myclone.aabbMin = this.aabbMin.clone();
		myclone.aabbMax = this.aabbMax.clone();
		// callback functions
		myclone.runConstantly = this.runConstantly;
		myclone.runConstantlyDelay = this.runConstantlyDelay;
		myclone.runWhenNoHealth = this.runWhenNoHealth;
		myclone.runWhenMaxAge = this.runWhenMaxAge;
		myclone.runWhenCreated = this.runWhenCreated;
		// time-related vars
		myclone.age = this.age;
		myclone.ageMax = this.ageMax;
		myclone.stepCounter = this.stepCounter;
		// animation-related vars - per ms
		myclone.posVelocity = this.posVelocity;
		myclone.rotVelocity = this.rotVelocity;
		myclone.scaleVelocity = this.scaleVelocity;
		myclone.tintVelocity = this.tintVelocity;
		// bullets
		myclone.bullets = this.bullets;
		myclone.shootName = this.shootName;
		myclone.shootDelay = this.shootDelay;
		myclone.shootNext = this.shootNext;
		myclone.shootRandomDelay = this.shootRandomDelay;
		myclone.shootDist = this.shootDist;
		myclone.shootAt = this.shootAt;
		myclone.shootVelocity = this.shootVelocity;
		myclone.shootSound = this.shootSound;
		// spawnable particles
		myclone.particles = this.particles;
		myclone.spawnConstantly = this.spawnConstantly;
		myclone.spawnConstantlyDelay = this.spawnConstantlyDelay;
		myclone.spawnConstantlyNext = this.spawnConstantlyNext;
		myclone.spawnWhenNoHealth = this.spawnWhenNoHealth;
		myclone.spawnWhenMaxAge = this.spawnWhenMaxAge;
		myclone.spawnWhenCreated = this.spawnWhenCreated;
		// sound effects
		myclone.soundConstantlyDelay = this.soundConstantlyDelay;
		myclone.soundConstantlyNext = this.soundConstantlyNext;
		myclone.soundConstantly = this.soundConstantly;
		myclone.soundWhenNoHealth = this.soundWhenNoHealth;
		myclone.soundWhenMaxAge = this.soundWhenMaxAge;
		myclone.soundWhenCreated = this.soundWhenCreated;
		myclone.active = true;
		myclone.visible = true;
		return myclone;
	}

	public function die():void
	{
		//trace(name + " dies!");
		active = false;
		visible = false;
	}
	
	public function respawn(pos:Matrix3D = null):void
	{
		age = 0;
		stepCounter = 0;
		active = true;
		visible = true;

		// don't shoot immediately
		shootNext = Math.random() * shootRandomDelay;
		
		if (pos)
		{	
			transform = pos.clone();
		}
		
		if (soundWhenCreated)
			soundWhenCreated.play();
		
		if (runWhenCreated != null)
			runWhenCreated();

		if (particles && spawnWhenCreated)
			particles.spawn(spawnWhenCreated, transform);
		
		//trace("Respawned " + name + " at " + posString());
	}

	// used for collision callback performed in GameActorpool
	public function colliding(checkme:GameActor):GameActor
	{
		if (collidemode == 0)
		{
			if (isCollidingSphere(checkme))
				return checkme;
			else
				return null;
		}
		else
		{
			if (isCollidingAabb(checkme))
				return checkme;
			else
				return null;
		}
	}
	
	// simple sphere to sphere collision
	public function isCollidingSphere(checkme:GameActor):Boolean
	{
		// never collide with yourself
		if (this == checkme) return false;
		// only check if these shapes are collidable
		if (!collides || !checkme.collides) return false;
		// don't check your own bullets
		if (checkme.owner == this) return false;
		// don't check if no radius
		if (radius == 0 || checkme.radius == 0) return false;
		
		var dist:Number = 
			Vector3D.distance(position, checkme.position);
			
		if (dist <= (radius+checkme.radius))
		{
			// trace("Collision detected at distance="+dist);
			touching = checkme; // remember who hit us
			return true;
		}
		
		// default: too far away
		// trace("No collision. Dist = "+dist);
		return false;
		
	}

	// axis-aligned bounding box collision detection
	// not used in the example game but here for convenience
	private function aabbCollision(
		min1:Vector3D, max1:Vector3D, 
		min2:Vector3D, max2:Vector3D ):Boolean
	{
		if ( min1.x > max2.x || 
			min1.y > max2.y || 
			min1.z > max2.z || 
			max1.x < min2.x || 
			max1.y < min2.y || 
			max1.z < min2.z ) 
		{
			return false;
		}	
		return true;
	}		
	
	public function isCollidingAabb(checkme:GameActor):Boolean
	{
		// never collide with yourself
		if (this == checkme) return false;
		// only check if these shapes are collidable
		if (!collides || !checkme.collides) return false;
		// don't check your own bullets
		if (checkme.owner == this) return false;
		// don't check if no aabb data
		if (aabbMin == null || 
			aabbMax == null ||
			checkme.aabbMin == null || 
			checkme.aabbMax == null) 
			return false;
		
		if (aabbCollision(
			position + aabbMin, 
			position + aabbMax, 
			checkme.position + checkme.aabbMin, 
			checkme.position + checkme.aabbMax))
		{
			touching = checkme; // remember who hit us
			return true;
		}

		// trace("No collision.");
		return false;
	}
	
} // end package

} // end class
