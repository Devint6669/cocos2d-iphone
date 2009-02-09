//
// Effects Demo
// a cocos2d example
//
// Demo by Ernesto Corvi and On-Core
//

// cocos2d import
#import "cocos2d.h"

// local import
#import "EffectsAdvancedTest.h"

enum {
	kTagTextLayer = 1,

	kTagBackground = 1,
	kTagLabel = 2,
};

#pragma mark - Classes

@interface Effect1 : TextLayer
{
}
@end

@implementation Effect1
-(void) onEnter
{
	[super onEnter];
	
	id target = [self getByTag:kTagBackground];
	
	id lens = [Lens3D actionWithPosition:cpv(240,160) radius:240 grid:cpv(15,10) duration:0.0f];
	id reuse = [ReuseGrid actionWithTimes:1];
	id delay = [DelayTime actionWithDuration:8];
	id waves = [Waves3D actionWithWaves:18 amplitude:80 grid:cpv(15,10) duration:10];

	id orbit = [OrbitCamera actionWithDuration:5 radius:1 deltaRadius:2 angleZ:0 deltaAngleZ:180 angleX:0 deltaAngleX:-90];
	id orbit_back = [orbit reverse];

	[target do: [RepeatForever actionWithAction: [Sequence actions: orbit, orbit_back, nil]]];
	[target do: [Sequence actions: lens, delay, reuse, waves, nil]];
}
-(NSString*) title
{
	return @"Lens + Waves3d";
}
@end


#pragma mark Demo - order

static int actionIdx=0;
static NSString *actionList[] =
{
	@"Effect1",
};

Class nextAction()
{	
	actionIdx++;
	actionIdx = actionIdx % ( sizeof(actionList) / sizeof(actionList[0]) );
	NSString *r = actionList[actionIdx];
	Class c = NSClassFromString(r);
	return c;
}

Class backAction()
{
	actionIdx--;
	int total = ( sizeof(actionList) / sizeof(actionList[0]) );
	if( actionIdx < 0 )
		actionIdx += total;
	NSString *r = actionList[actionIdx];
	Class c = NSClassFromString(r);
	return c;
}

Class restartAction()
{
	NSString *r = actionList[actionIdx];
	Class c = NSClassFromString(r);
	return c;
}

@implementation TextLayer
-(id) init
{
	if( self = [super init] ) {
	
		float x,y;
		
		CGSize size = [[Director sharedDirector] winSize];
		x = size.width;
		y = size.height;
		
		Sprite *bg = [Sprite spriteWithFile:@"background.png"];
		[self add: bg z:0 tag:kTagBackground];
		bg.position = cpv(x/2,y/2);
		
		Sprite *grossini = [Sprite spriteWithFile:@"grossini.png"];
		[bg add:grossini z:1];
		grossini.position = cpv(230,200);
		id sc = [ScaleBy actionWithDuration:2 scale:5];
		id sc_back = [sc reverse];
		[grossini do: [RepeatForever actionWithAction: [Sequence actions:sc, sc_back, nil]]];

		Sprite *tamara = [Sprite spriteWithFile:@"grossinis_sister1.png"];
		[bg add:tamara z:1];
		tamara.position = cpv(430,200);
		id sc2 = [ScaleBy actionWithDuration:2 scale:5];
		id sc2_back = [sc2 reverse];
		[tamara do: [RepeatForever actionWithAction: [Sequence actions:sc2, sc2_back, nil]]];
		
		
		Label* label = [Label labelWithString:[self title] fontName:@"Marker Felt" fontSize:32];
		
		[label setPosition: cpv(x/2,y-80)];
		[self add: label];
		label.tag = kTagLabel;
		
		// menu
		MenuItemImage *item1 = [MenuItemImage itemFromNormalImage:@"b1.png" selectedImage:@"b2.png" target:self selector:@selector(backCallback:)];
		MenuItemImage *item2 = [MenuItemImage itemFromNormalImage:@"r1.png" selectedImage:@"r2.png" target:self selector:@selector(restartCallback:)];
		MenuItemImage *item3 = [MenuItemImage itemFromNormalImage:@"f1.png" selectedImage:@"f2.png" target:self selector:@selector(nextCallback:)];
		Menu *menu = [Menu menuWithItems:item1, item2, item3, nil];
		menu.position = cpvzero;
		item1.position = cpv(480/2-100,30);
		item2.position = cpv(480/2, 30);
		item3.position = cpv(480/2+100,30);
		[self add: menu z:1];

	}
	
	return self;
}

-(NSString*) title
{
	return @"No title";
}

-(void) restartCallback: (id) sender
{
	Scene *s = [Scene node];
	[s add: [restartAction() node]];
	[[Director sharedDirector] replaceScene: s];
}

-(void) nextCallback: (id) sender
{
	Scene *s = [Scene node];
	[s add: [nextAction() node]];
	[[Director sharedDirector] replaceScene: s];
}

-(void) backCallback: (id) sender
{
	Scene *s = [Scene node];
	[s add: [backAction() node]];
	[[Director sharedDirector] replaceScene: s];
}

- (void) dealloc
{
	[super dealloc];
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
	[window setMultipleTouchEnabled:NO];
	
	// must be called before any othe call to the director
//	[Director useFastDirector];
	
	[[Director sharedDirector] setDepthBufferFormat:kDepthBuffer24];
	
	// before creating any layer, set the landscape mode
	[[Director sharedDirector] setLandscape: YES];
	[[Director sharedDirector] setAnimationInterval:1.0/60];
	[[Director sharedDirector] setDisplayFPS:YES];
	
	// create an openGL view inside a window
	[[Director sharedDirector] attachInView:window];	
	[window makeKeyAndVisible];	
	
	Scene *scene = [Scene node];
	[scene add: [nextAction() node]];	
	
	[[Director sharedDirector] runWithScene: scene];
}

- (void) dealloc
{
	[window dealloc];
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
