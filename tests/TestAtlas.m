//
// Atlas Demo
// a cocos2d example
//

// cocos import
#import "cocos2d.h"

// local import
#import "TestAtlas.h"
static int sceneIdx=-1;
static NSString *transitions[] = {
			@"Atlas1",
			@"Atlas2",
			@"Atlas3",
};

Class nextAction()
{
	
	sceneIdx++;
	sceneIdx = sceneIdx % ( sizeof(transitions) / sizeof(transitions[0]) );
	NSString *r = transitions[sceneIdx];
	Class c = NSClassFromString(r);
	return c;
}

Class backAction()
{
	sceneIdx--;
	int total = ( sizeof(transitions) / sizeof(transitions[0]) );
	if( sceneIdx < 0 )
		sceneIdx += total;	
	
	NSString *r = transitions[sceneIdx];
	Class c = NSClassFromString(r);
	return c;
}

Class restartAction()
{
	NSString *r = transitions[sceneIdx];
	Class c = NSClassFromString(r);
	return c;
}


@implementation AtlasDemo
-(id) init
{
	[super init];


	CGRect s = [[Director sharedDirector] winSize];
		
	Label* label = [Label labelWithString:[self title] dimensions:CGSizeMake(s.size.width, 40) alignment:UITextAlignmentCenter fontName:@"Arial" fontSize:32];
	[self add: label];
	[label setPosition: cpv(s.size.width/2, s.size.height-50)];
	
	MenuItemImage *item1 = [MenuItemImage itemFromNormalImage:@"b1.png" selectedImage:@"b2.png" target:self selector:@selector(backCallback:)];
	MenuItemImage *item2 = [MenuItemImage itemFromNormalImage:@"r1.png" selectedImage:@"r2.png" target:self selector:@selector(restartCallback:)];
	MenuItemImage *item3 = [MenuItemImage itemFromNormalImage:@"f1.png" selectedImage:@"f2.png" target:self selector:@selector(nextCallback:)];
	
	Menu *menu = [Menu menuWithItems:item1, item2, item3, nil];
	
	menu.position = cpvzero;
	item1.position = cpv( s.size.width/2 - 100,30);
	item2.position = cpv( s.size.width/2, 30);
	item3.position = cpv( s.size.width/2 + 100,30);
	[self add: menu z:-1];	

	return self;
}

-(void) dealloc
{
	[super dealloc];
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

-(NSString*) title
{
	return @"No title";
}
@end

#pragma mark Example Atlas 1

@implementation Atlas1


-(id) init
{
	if( ![super init] )
		return nil;
	
	textureAtlas = [[TextureAtlas textureAtlasWithFile: @"atlastest.png" capacity:3] retain];

	ccQuad2 texCoords[] = {
		{0.0,0.2,	0.5,0.2,	0.0,0.0,	0.5,0.0},
		{0.2,0.6,	0.6,0.6,	0.2,0.2,	0.6,0.2},
		{0.0,1.0,	1.0,1.0,	0.0,0.0,	1.0,0.0},
	};
	
	ccQuad3	vertices[] = {
		{40,40,0,		120,80,0,		40,160,0,		160,160,0},
		{240,80,0,		480,80,0,		180,120,0,		420,120,0},
		{240,140,0,		360,200,0,		240,250,0,		360,310,0},
	};
	
	for( int i=0;i<3;i++) {
		[textureAtlas updateQuadWithTexture: &texCoords[i] vertexQuad: &vertices[i] atIndex:i];
	}
	
	return self;
}

-(void) dealloc {
	[textureAtlas release];
	[super dealloc];
}


-(void) draw {
	glEnableClientState( GL_VERTEX_ARRAY);
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
	
	glEnable( GL_TEXTURE_2D);
	
	[textureAtlas drawNumberOfQuads:3];
		
	glDisable( GL_TEXTURE_2D);
	
	glDisableClientState(GL_VERTEX_ARRAY );
	glDisableClientState( GL_TEXTURE_COORD_ARRAY );
}
					
-(NSString *) title
{
	return @"Atlas: TextureAtlas";
}
@end

#pragma mark Example Atlas 2

@implementation Atlas2
-(id) init {
	if( ![super init] )
		return nil;
	
	
	LabelAtlas *label = [LabelAtlas labelAtlasWithString:@"123 Test" charMapFile:@"tuffy_bold_italic-charmap.png" itemWidth:48 itemHeight:64 startCharMap:' '];
	
	[self add:label];
	label.position = cpv(10,100);

	return self;
	
}
-(NSString *) title
{
	return @"Atlas: LabelAtlas";
}
@end

#pragma mark Example Atlas 3

@implementation Atlas3
-(id) init {
	if( ![super init] )
		return nil;
	
	TileMapAtlas *tilemap = [TileMapAtlas tileMapAtlasWithTileFile:@"tiles.png" mapFile:@"levelmap.tga" tileWidth:16 tileHeight:16];
	[self add:tilemap];
	
	tilemap.position = cpv(0,-200);
	
	id s = [ScaleBy actionWithDuration:8 scale:0.5];
	id scaleBack = [s reverse];
	id go = [MoveBy actionWithDuration:4 position:cpv(-400,0)];
	id goBack = [go reverse];
	
	id seq = [Sequence actions: s,
							go,
							scaleBack,
							goBack,
							nil];
	
	[tilemap do:seq];
		
	return self;
	
}

-(NSString *) title
{
	return @"Atlas: TileMapAtlas";
}

@end


// CLASS IMPLEMENTATIONS
@implementation AppController

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	// before creating any layer, set the landscape mode
	[[Director sharedDirector] setLandscape: YES];
	[[Director sharedDirector] setAnimationInterval:1.0/60];
	[[Director sharedDirector] setDisplayFPS:YES];

	Scene *scene = [Scene node];
	[scene add: [nextAction() node]];
			 
	[[Director sharedDirector] runScene: scene];
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

@end
