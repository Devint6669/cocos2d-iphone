//
// Demo of calling integrating Box2D physics engine with cocos2d AtlasSprites
// a cocos2d example
// http://code.google.com/p/cocos2d-iphone
//
// by Steve Oldmeadow
//

#import "Box2dTest.h"

@implementation Box2DTestLayer

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32

enum {
	kTagTileMap = 1,
	kTagSpriteManager = 1,
	kTagAnimation1 = 1,
};

-(id) init
{
	[super init];
	CGSize screenSize = [Director sharedDirector].winSize;
	CCLOG(@"Screen width %0.2f screen height %0.2f",screenSize.width,screenSize.height);
	
	//Set up world bounds - this should be larger than screen as any body that reaches
	//the boundary will be frozen
	b2AABB worldAABB;
	float borderSize = 96 / PTM_RATIO;//We want a 96 pixel border between the screen and the world bounds
	worldAABB.lowerBound.Set(-borderSize, -borderSize);//Bottom left
	worldAABB.upperBound.Set(screenSize.width/PTM_RATIO + borderSize, screenSize.height/PTM_RATIO + borderSize);//Top right
	
	b2Vec2 gravity(0.0f, -30.0f);//Set up gravity
	bool doSleep = true;
	
	world = new b2World(worldAABB, gravity, doSleep);
	
	//Set up ground, we will make it as wide as the screen
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(screenSize.width/PTM_RATIO/2, -1.0f);//This is a mid point, hence the /2
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	b2PolygonDef groundShapeDef;
	groundShapeDef.SetAsBox(screenSize.width/PTM_RATIO/2, 1.0f);//This is a mid point, hence the /2
	groundBody->CreateShape(&groundShapeDef);
	
	[self schedule: @selector(tick:)];
	
	//Set up sprite
	
	AtlasSpriteManager *mgr = [AtlasSpriteManager spriteManagerWithFile:@"blocks.png" capacity:150];
	[self addChild:mgr z:0 tag:kTagSpriteManager];
	
	isTouchEnabled = YES;
	return self;
}

-(void) dealloc
{
	delete world;
	body = NULL;
	world = NULL;
	[super dealloc];
}	

-(void) addNewSpriteWithCoords:(CGPoint)p
{
	CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
	AtlasSpriteManager *mgr = (AtlasSpriteManager*) [self getChildByTag:kTagSpriteManager];
	
	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	//just randomly picking one of the images
	int idx = (CCRANDOM_0_1() > .5 ? 0:1);
	int idy = (CCRANDOM_0_1() > .5 ? 0:1);
	AtlasSprite *sprite = [AtlasSprite spriteWithRect:CGRectMake(32 * idx,32 * idy,32,32) spriteManager:mgr];
	[mgr addChild:sprite];
	
	sprite.position = ccp( p.x, p.y);
	
	//Set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	bodyDef.userData = sprite;
	body = world->CreateBody(&bodyDef);
	b2PolygonDef shapeDef;
	shapeDef.SetAsBox(.5f, .5f);//These are mid points for our 1m box
	shapeDef.density = 1.0f;
	shapeDef.friction = 0.3f;
	body->CreateShape(&shapeDef);
	body->SetMassFromShapes();
}



-(void) tick: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	world->Step(dt, 10, 8);//Step the physics world
	//Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL) {
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			AtlasSprite* myActor = (AtlasSprite*)b->GetUserData();
			myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}	
	}
}

- (BOOL)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Add a new body/atlas sprite at the touched location
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		
		location = [[Director sharedDirector] convertCoordinate: location];
		
		[self addNewSpriteWithCoords: location];
	}
	return kEventHandled;
}

@end

// CLASS IMPLEMENTATIONS
@implementation AppController

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	// Init the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	// cocos2d will inherit these values
	[window setUserInteractionEnabled:YES];	
	[window setMultipleTouchEnabled:YES];
	
	// must be called before any othe call to the director
	[Director useFastDirector];

	// AnimationInterval doesn't work with FastDirector, yet
//	[[Director sharedDirector] setAnimationInterval:1.0/60];
	[[Director sharedDirector] setDisplayFPS:YES];
	[[Director sharedDirector] setDeviceOrientation:CCDeviceOrientationLandscapeLeft];

	// create an openGL view inside a window
	[[Director sharedDirector] attachInView:window];

	// And you can later, once the openGLView was created
	// you can change it's properties
	[[[Director sharedDirector] openGLView] setMultipleTouchEnabled:YES];

	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[Texture2D setDefaultAlphaPixelFormat:kTexture2DPixelFormat_RGBA8888];	
	
	// add layer
	Scene *scene = [Scene node];
	id box2dLayer = [[Box2DTestLayer alloc] init];
	[scene addChild:box2dLayer z:0];
	glClearColor(1.0f,1.0f,1.0f,1.0f);

	[window makeKeyAndVisible];

	[[Director sharedDirector] runWithScene: scene];
}

- (void) dealloc
{
	[window release];
	[super dealloc];
}

// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
	[[Director sharedDirector] pause];
}

// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
	[[Director sharedDirector] resume];
}

// purge memroy
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	[[TextureMgr sharedTextureMgr] removeAllTextures];
}

// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[Director sharedDirector] setNextDeltaTimeZero:YES];
}

@end
