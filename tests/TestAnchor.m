//
// Anchor Demo
// a cocos2d example
//

// cocos import
#import "cocos2d.h"

// local import
#import "TestAnchor.h"
static int sceneIdx=-1;
static NSString *transitions[] = {
			@"Anchor1",
			@"Anchor2",
			@"Anchor3",
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


@implementation AnchorDemo
-(id) init
{
	[super init];

	grossini = [[Sprite spriteFromFile:@"grossini.png"] retain];
	tamara = [[Sprite spriteFromFile:@"grossinis_sister1.png"] retain];
	
	[self add: grossini z:1];
	[self add: tamara z:2];

	CGRect s = [[Director sharedDirector] winSize];
	
	[grossini setPosition: cpv(60, s.size.height/3)];
	[tamara setPosition: cpv(60, 2*s.size.height/3)];
	
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
	[grossini release];
	[tamara release];
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

-(void) centerSprites
{
	CGRect s = [[Director sharedDirector] winSize];
	
	[grossini setPosition: cpv(s.size.width/3, s.size.height/2)];
	[tamara setPosition: cpv(2*s.size.width/3, s.size.height/2)];
}
-(NSString*) title
{
	return @"No title";
}
@end

@implementation Anchor1
-(void) onEnter
{
	[super onEnter];
	
	[self centerSprites];
	
	id a1 = [RotateBy actionWithDuration:2 angle:360];
	id a2 = [ScaleBy actionWithDuration:2 scale:2];

	id action1 = [Repeat actionWithAction:
				  [Sequence actions: a1, a2, [a2 reverse], nil]
									times:-1];
	id action2 = [Repeat actionWithAction:
				  [Sequence actions: [a1 copy], [a2 copy], [a2 reverse], nil]
									times:-1];
	
	tamara.transformAnchor = cpvzero;
	
	[tamara do: action1];
	[grossini do:action2];
}
-(NSString *) title
{
	return @"transformAnchor";
}
@end

@implementation Anchor2
-(void) onEnter
{
	[super onEnter];
	
	[self centerSprites];

	Sprite *sp1 = [Sprite spriteFromFile:@"grossini.png"];
	Sprite *sp2 = [Sprite spriteFromFile:@"grossinis_sister1.png"];
	
	sp1.scale = 0.25;
	sp2.scale = 0.25;
	
	[tamara add:sp1];
	[grossini add:sp2];
	
	id a1 = [RotateBy actionWithDuration:2 angle:360];
	id a2 = [ScaleBy actionWithDuration:2 scale:2];
	
	id action1 = [Repeat actionWithAction:
				  [Sequence actions: a1, a2, [a2 reverse], nil]
									times:-1];
	id action2 = [Repeat actionWithAction:
				  [Sequence actions: [a1 copy], [a2 copy], [a2 reverse], nil]
									times:-1];
	
	tamara.transformAnchor = cpvzero;
	
	[tamara do: action1];
	[grossini do:action2];	
}
-(NSString *) title
{
	return @"transformAnchor and children";
}
@end
@implementation Anchor3
-(void) onEnter
{
	[super onEnter];

	tamara.visible = NO;

	[self centerSprites];
	
	Sprite *sp1 = [Sprite spriteFromFile:@"grossinis_sister1.png"];
	Sprite *sp2 = [Sprite spriteFromFile:@"grossinis_sister2.png"];
	
	sp1.position = cpv(20,80);
	sp2.position = cpv(70,50);
	
	[grossini add:sp1 z:-1];
	[grossini add:sp2 z:1];
	
	id a1 = [RotateBy actionWithDuration:4 angle:360];
	id action1 = [Repeat actionWithAction:a1 times:-1];
	[grossini do:action1];	
	
	
}
-(NSString *) title
{
	return @"z order";
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

@end
