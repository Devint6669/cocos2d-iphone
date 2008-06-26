/* cocos2d-iphone
 *
 * Copyright (C) 2008 Ricardo Quesada
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3 or (it is your choice) any later
 * version. 
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
 *
 */


#import "IntervalAction.h"
#import "Sprite.h"
#import "CocosNode.h"

//
// IntervalAction
//
@implementation IntervalAction

@synthesize duration;

-(id) init
{
	NSException* myException = [NSException
								exceptionWithName:@"IntervalActionInit"
								reason:@"Init not supported. Use InitWithDuration"
								userInfo:nil];
	@throw myException;
	
}

+(id) actionWithDuration: (double) d
{
	return [[[self alloc] initWithDuration:d ] autorelease];
}

-(id) initWithDuration: (double) d
{
	if( ![super init] )
		return nil;
	
	duration = d;
	elapsed = 0.0;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] ];
    return copy;
}


- (BOOL) isDone
{
	return (elapsed >= duration);
}

-(void) step
{
	elapsed += [self getDeltaTime];
	[self update: MIN(1, elapsed/duration)];
}

- (double) getDeltaTime
{
	struct timeval now;
	double delta;	
	
	if( gettimeofday( &now, NULL) != 0 ) {
		NSException* myException = [NSException
									exceptionWithName:@"GetTimeOfDay"
									reason:@"GetTimeOfDay abnormal error"
									userInfo:nil];
		@throw myException;
	}
	
	delta = (lastUpdate.tv_sec - now.tv_sec) + (lastUpdate.tv_usec - now.tv_usec) / 1000000.0;
	
	memcpy( &lastUpdate, &now, sizeof(lastUpdate) );
	return -delta;
}

-(void) start
{
	if( gettimeofday( &lastUpdate, NULL) != 0 ) {
		NSException* myException = [NSException
									exceptionWithName:@"GetTimeOfDay"
									reason:@"GetTimeOfDay abnormal error"
									userInfo:nil];
		@throw myException;
	}
	
	elapsed = 0.0;
}

- (IntervalAction*) reverse
{
	NSException* myException = [NSException
								exceptionWithName:@"ReverseActionNotImplemented"
								reason:@"Reverse Action not implemented"
								userInfo:nil];
	@throw myException;	
}
@end

//
// Sequence
//
@implementation Sequence
+(id) actionOne: (IntervalAction*) one two: (IntervalAction*) two
{	
	return [[[self alloc] initOne:one two:two ] autorelease];
}

+(id) actions: (IntervalAction*) action1, ...
{
	va_list params;
	va_start(params,action1);
	
	IntervalAction *now;
	IntervalAction *prev = action1;
	
	while( action1 ) {
		now = va_arg(params,IntervalAction*);
		if ( now )
			prev = [Sequence actionOne: prev two: now];
		else
			break;
	}
	va_end(params);
	return prev;
}

-(id) initOne: (IntervalAction*) one_ two: (IntervalAction*) two_
{
	NSAssert( one_!=nil, @"Sequence: argument one must be non-nil");
	NSAssert( two_!=nil, @"Sequence: argument two must be non-nil");

	IntervalAction *one = [[one_ copy] autorelease];
	IntervalAction *two = [[two_ copy] autorelease];
		
	double d = [one duration] + [two duration];
	[super initWithDuration: d];
	
	actions = [[NSArray arrayWithObjects: one, two, nil] retain];
	
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initOne: [actions objectAtIndex:0] two: [actions objectAtIndex:1] ];
    return copy;
}

-(void) dealloc
{
//	NSLog( @"deallocing %@", self);
	[actions release];
	[super dealloc];
}

-(void) start
{
	[super start];
	for( Action * action in actions )
		action.target = target;
	
	split = [[actions objectAtIndex:0] duration] / duration;
	last = -1;
}

-(void) update: (double) t
{
	int found = 0;
	double new_t = 0.0;
	
	if( t >= split ) {
		found = 1;
		if ( split == 1 )
			new_t = 1;
		else
			new_t = (t-split) / (1 - split );
	} else {
		found = 0;
		if( split != 0 )
			new_t = t / split;
		else
			new_t = 1;
	}
	
	if (last == -1 && found==1)	{
		[[actions objectAtIndex:0] start];
		[[actions objectAtIndex:0] update:1];
		[[actions objectAtIndex:0] stop];
	}

	if (last != found ) {
		if( last != -1 ) {
			[[actions objectAtIndex: last] update: 1];
			[[actions objectAtIndex: last] stop];
		}
		[[actions objectAtIndex: found] start];
	}
	[[actions objectAtIndex:found] update: new_t];
	last = found;
}

- (IntervalAction *) reverse
{
	return [Sequence actionOne: [[actions objectAtIndex:1] reverse] two: [[actions objectAtIndex:0] reverse ] ];
}
@end

//
// Repeat
//
@implementation Repeat
+(id) actionWithAction: (IntervalAction*) action times: (unsigned int) t
{
	return [[[self alloc] initWithAction: action times: t] autorelease];
}

-(id) initWithAction: (IntervalAction*) action times: (unsigned int) t
{
	int d = [action duration] * t;
	if(! [super initWithDuration: d ] )
		return nil;
	times = t;
	other = [action copy];
	total = 0;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithAction: other times: times];
    return copy;
}


-(void) dealloc
{
	[other release];
	[super dealloc];
}

-(void) start
{
	[super start];
	other.target = target;
	[other start];
}

-(void) step
{
	[other step];
	if( [other isDone] ) {
		total++;
		[self start];
	}
}
-(BOOL) isDone
{
	// times == 0, Always repeat
	if( !times )
		return NO;
	return ( total == times );
}
@end

//
// Spawn
//
@implementation Spawn
+(id) actions: (IntervalAction*) action1, ...
{
	va_list params;
	va_start(params,action1);
	
	IntervalAction *now;
	IntervalAction *prev = action1;
	
	while( action1 ) {
		now = va_arg(params,IntervalAction*);
		if ( now )
			prev = [Spawn actionOne: prev two: now];
		else
			break;
	}
	va_end(params);
	return prev;
}

+(id) actionOne: (IntervalAction*) one two: (IntervalAction*) two
{	
	return [[[self alloc] initOne:one two:two ] autorelease];
}

-(id) initOne: (IntervalAction*) one_ two: (IntervalAction*) two_
{
	NSAssert( one_!=nil, @"Spawn: argument one must be non-nil");
	NSAssert( two_!=nil, @"Spawn: argument two must be non-nil");

	double d1 = [one_ duration];
	double d2 = [two_ duration];	
	
	[super initWithDuration: fmax(d1,d2)];

	one = [[one_ copy] autorelease];
	two = [[two_ copy] autorelease];

	if( d1 > d2 )
		two = [Sequence actions: two_, [DelayTime actionWithDuration: (d1-d2)], nil];
	else if( d1 < d2)
		one = [Sequence actions: one_, [DelayTime actionWithDuration: (d2-d1)], nil];
	
	[one retain];
	[two retain];
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initOne: one two: two];
    return copy;
}

-(void) dealloc
{
	//	NSLog( @"deallocing %@", self);
	[one release];
	[two release];
	[super dealloc];
}

-(void) start
{
	[super start];
	[target do: one];
	[target do: two];
}

-(BOOL) isDone
{
	return [one isDone] && [two isDone];	
}
-(void) update: (double) t
{
	// ignore. not needed
}

- (IntervalAction *) reverse
{
	return [Spawn actionOne: [one reverse] two: [two reverse ] ];
}
@end

//
// RotateTo
//
@implementation RotateTo
+(id) actionWithDuration: (double) t angle:(float) a
{	
	return [[[self alloc] initWithDuration:t angle:a ] autorelease];
}

-(id) initWithDuration: (double) t angle:(float) a
{
	if( ! [super initWithDuration: t] )
		return nil;
	[super initWithDuration: t];
	
	angle = a;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] angle: angle];
    return copy;
}

-(void) start
{
	[super start];
	startAngle = target.rotation;
	angle -= startAngle;
	if (angle > 180)
		angle = -360 + angle;
	if (angle < -180)
		angle = 360 + angle;
}
-(void) update: (double) t
{
	target.rotation = startAngle + angle * t;
}
@end


//
// RotateBy
//
@implementation RotateBy
+(id) actionWithDuration: (double) t angle:(float) a
{	
	return [[[self alloc] initWithDuration:t angle:a ] autorelease];
}

-(id) initWithDuration: (double) t angle:(float) a
{
	if( ! [super initWithDuration: t] )
		return nil;
	[super initWithDuration: t];

	angle = a;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] angle: angle];
    return copy;
}

-(void) start
{
	[super start];
	startAngle = [target rotation];
}

-(void) update: (double) t
{	
	// XXX: shall I add % 360
	target.rotation = (startAngle + angle * t );
}

-(IntervalAction*) reverse
{
	return [RotateBy actionWithDuration: duration angle: -angle];
}

@end

//
// MoveTo
//
@implementation MoveTo
+(id) actionWithDuration: (double) t position: (CGPoint) p
{	
	return [[[self alloc] initWithDuration:t position:p ] autorelease];
}

-(id) initWithDuration: (double) t position: (CGPoint) p
{
	if( ![super initWithDuration: t] )
		return nil;
	
	endPosition = p;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] position: endPosition];
    return copy;
}

-(void) start
{
	[super start];
	startPosition = [target position];
	delta.x = endPosition.x - startPosition.x;
	delta.y = endPosition.y - startPosition.y;	
}

-(void) update: (double) t
{	
	target.position = CGPointMake( (startPosition.x + delta.x * t ), (startPosition.y + delta.y * t ) );
}
@end

//
// MoveBy
//
@implementation MoveBy
+(id) actionWithDuration: (double) t position: (CGPoint) p
{	
	return [[[self alloc] initWithDuration:t position:p ] autorelease];
}

-(id) initWithDuration: (double) t position: (CGPoint) p
{
	if( ![super initWithDuration: t] )
		return nil;

	delta = p;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] position: delta];
    return copy;
}

-(void) start
{
	CGPoint dTmp = delta;
	[super start];
	delta = dTmp;
}

-(IntervalAction*) reverse
{
	return [MoveBy actionWithDuration: duration position: CGPointMake( -delta.x, -delta.y)];
}
@end

//
// JumpBy
//
@implementation JumpBy
+(id) actionWithDuration: (double) t position: (CGPoint) pos height: (double) h jumps:(int)j
{
	return [[[self alloc] initWithDuration: t position: pos height: h jumps:j] autorelease];
}

-(id) initWithDuration: (double) t position: (CGPoint) pos height: (double) h jumps:(int)j
{
	[super initWithDuration:t];
	delta = pos;
	height = h;
	jumps = j;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] position: delta height:height jumps:jumps];
    return copy;
}

-(void) start
{
	[super start];
	startPosition = target.position;
}

-(void) update: (double) t
{
	double y = height * fabs( sinf(t * M_PI * jumps ) );
	y += delta.y * t;
	double x = delta.x * t;
	target.position = CGPointMake( startPosition.x + x, startPosition.y + y );
}

-(IntervalAction*) reverse
{
	return [JumpBy actionWithDuration: duration position: CGPointMake(-delta.x,-delta.y) height: height jumps:jumps];
}
@end

//
// JumpTo
//
@implementation JumpTo
-(void) start
{
	[super start];
	delta = CGPointMake( delta.x - startPosition.x, delta.y - startPosition.y );
}
@end

//
// ScaleTo
//
@implementation ScaleTo
+(id) actionWithDuration: (double) t scale:(float) s
{
	return [[[self alloc] initWithDuration: t scale:s] autorelease];
}

-(id) initWithDuration: (double) t scale:(float) s
{
	if( ![super initWithDuration: t] )
		return nil;
	
	endScale = s;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] scale: endScale];
    return copy;
}

-(void) start
{
	[super start];
	startScale = [target scale];
	delta = endScale - startScale;
}

-(void) update: (double) t
{	
	[target setScale: (startScale + delta * t ) ];	
}
@end

//
// ScaleBy
//
@implementation ScaleBy
-(void) start
{
	[super start];
	delta = startScale * endScale - startScale;
}

-(IntervalAction*) reverse
{
	return [ScaleBy actionWithDuration: duration scale: 1/endScale];
}
@end

//
// Blink
//
@implementation Blink
+(id) actionWithDuration: (double) t blinks: (int) b
{
	return [[[ self alloc] initWithDuration: t blinks: b] autorelease];
}

-(id) initWithDuration: (double) t blinks: (int) b
{
	[super initWithDuration: t];
	times = b;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] blinks: times];
    return copy;
}

-(void) update: (double) t
{
	double slice = 1.0f / times;
	double m = fmod(t, slice);
	target.visible = (m > slice/2) ? YES : NO;
}

-(IntervalAction*) reverse
{
	// return 'self'
	return [Blink actionWithDuration: duration blinks: times];
}
@end

//
// FadeIn
//
@implementation FadeIn
-(void) update: (double) t
{
	[(id<CocosNodeOpacity>) target setOpacity: 255 *t];
}
-(IntervalAction*) reverse
{
	return [FadeOut actionWithDuration: duration];
}
@end

//
// FadeOut
//
@implementation FadeOut
-(void) update: (double) t
{
	[(id<CocosNodeOpacity>) target setOpacity: 255 *(1-t)];
}
-(IntervalAction*) reverse
{
	return [FadeOut actionWithDuration: duration];
}
@end

//
// FadeTo
//
@implementation FadeTo
+(id) actionWithDuration: (double) t opacity: (GLubyte) o
{
	return [[[ self alloc] initWithDuration: t opacity: o] autorelease];
}

-(id) initWithDuration: (double) t opacity: (GLubyte) o
{
	[super initWithDuration: t];
	toOpacity = o;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] opacity: toOpacity];
    return copy;
}

-(void) start
{
	[super start];
	fromOpacity = [(id<CocosNodeOpacity>)target opacity];
}

-(void) update: (double) t
{
	[(id<CocosNodeOpacity>)target setOpacity: fromOpacity + ( toOpacity - fromOpacity ) * t];
}
@end

//
// Accelerate
//
@implementation Accelerate
+ (id) actionWithAction: (IntervalAction*) action rate: (float) r
{
	return [[[self alloc] initWithAction:action rate:r ] autorelease];
}

- (id) initWithAction: (IntervalAction*) action rate: (float) r
{	
	NSAssert( action!=nil, @"Accelerate: argument action must be non-nil");

	if( ! [super initWithDuration: [action duration]] )
		return nil;
	
	other = [action copy];
	rate = r;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithAction: other rate: rate];
    return copy;
}

- (void) dealloc
{
//	NSLog( @"deallocing %@", self);
	[other release];
	[super dealloc];
}

- (void) start
{
	[super start];
	other.target = target;
	[other start];
}

- (void) update: (double) t
{
	[other update: pow(t,rate) ];
}

- (IntervalAction*) reverse
{
	return [Accelerate actionWithAction: [other reverse] rate: 1/rate];
}
@end

//
// AccelDeccel
//
@implementation AccelDeccel
+(id) actionWithAction: (IntervalAction*) action
{
	return [[[self alloc] initWithAction: action ] autorelease ];
}

-(id) initWithAction: (IntervalAction*) action
{
	NSAssert( action!=nil, @"AccelDeccel: argument action must be non-nil");

	[super initWithDuration: action.duration ];
	other = [action copy];
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithAction: other];
    return copy;
}

-(void) dealloc
{
	[other release];
	[super dealloc];
}

-(void) start
{
	[super start];
	other.target = target;
	[other start];
}

-(void) update: (double) t
{
	double ft = (t-0.5f) * 12;
	double nt = 1.0f/( 1.0f + exp(-ft) );
	[other update: nt];	
}

-(IntervalAction*) reverse
{
	return [AccelDeccel actionWithAction: [other reverse]];
}
@end

//
// Speed
//
@implementation Speed
+(id) actionWithAction: (IntervalAction*) action speed:(double) s
{
	return [[[self alloc] initWithAction: action speed:s] autorelease ];
}

-(id) initWithAction: (IntervalAction*) action speed:(double) s
{
	NSAssert( action!=nil, @"Speed: argument action must be non-nil");

	[super initWithDuration: action.duration / s ];
	other = [action copy];
	speed = s;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	Action *copy = [[[self class] allocWithZone: zone] initWithAction: other speed: speed];
    return copy;
}

-(void) dealloc
{
	[other release];
	[super dealloc];
}

-(void) start
{
	[super start];
	other.target = target;
	[other start];
}

-(void) update: (double) t
{
	[other update: t];
}

-(IntervalAction*) reverse
{
	return [Speed actionWithAction: [other reverse] speed:speed];
}
@end

//
// DelayTime
//
@implementation DelayTime
-(void) update: (double) t
{
	return;
}

-(id)reverse
{
	return [DelayTime actionWithDuration:duration];
}
@end

//
// ReverseTime
//

@implementation ReverseTime
+(id) actionWithAction: (IntervalAction*) action
{
	return [[[super alloc] initWithAction:action] autorelease];
}

-(id) initWithAction: (IntervalAction*) action
{
	[super initWithDuration: [action duration]];
	other = [action copy];
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	return [[[self class] allocWithZone: zone] initWithAction: other];
}

-(void) dealloc
{
	[other release];
	[super dealloc];
}

-(void) start
{
	[super start];
	other.target = target;
	[other start];
}

-(void) stop
{
	[other stop];
	[super stop];
}

-(void) update:(double)t
{
	[other update:1-t];
}

-(IntervalAction*) reverse
{
	return [[other copy] autorelease];
}
@end

@implementation Animate
+(id) actionWithAnimation: (Animation*) a
{
	return [[[self alloc] initWithAnimation: a] autorelease];
}

-(id) initWithAnimation: (Animation*) a
{
	NSAssert( a!=nil, @"Animate: argument Animation must be non-nil");

	if( ! [super initWithDuration: [[a frames] count] * [a delay]] )
		return nil;
	animation = [a retain];
	origFrame = nil;
	return self;
}

-(id) copyWithZone: (NSZone*) zone
{
	return [[[self class] allocWithZone: zone] initWithAnimation: animation];
}

-(void) dealloc
{
	[animation release];
	[origFrame release];
	[super dealloc];
}

-(void) start
{
	[super start];
	Sprite *s = (Sprite*) target;

	[[s texture] retain];
	[origFrame release];
	origFrame = [s texture];
}

-(void) stop
{
	Sprite *s = (Sprite*) target;

	// XXX TODO should I retain ?
	[origFrame retain];
	[[s texture] release];
	[s setTexture: origFrame];
	
	[super stop];
}

-(void) update: (double) t
{
	int idx=0;
	
	double slice = 1.0f / [[animation frames] count];
	
	if(t !=0 )
		idx = t/ slice;

	NSLog(@"idx: %d", idx);
	
	Sprite *s = (Sprite*) target;
	if ( s.texture != [[animation frames] objectAtIndex: idx] ) {
		// XXX TODO should I retain ?
		id obj = [[animation frames] objectAtIndex:idx];
		[obj retain];
		[[s texture] release];
		[s setTexture: obj];
	}
}
@end

