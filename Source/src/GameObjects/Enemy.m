//
//  Created by nickyweber on 08.01.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "Enemy.h"
#import "CCAnimation.h"
#import "LaserBeam.h"
#import "Spaceship.h"
#import "Constants.h"
#import "CCAnimationCache.h"
#import "GamePlaySceneDelegate.h"
#import "AIMovementDebug.h"
#import "EnemyShot.h"
#import "AIMovement.h"
#import "PointLoot.h"
#import "HealthLoot.h"
#import "ShieldLoot.h"

@interface Enemy()

@property (nonatomic) EnemyStates state;
@property (nonatomic) float timeSinceLastShot;
@property (nonatomic) float shotsPerSecond;
@property (nonatomic) int points;
@property (nonatomic) float speedfactor;
@property (nonatomic) NSUInteger level;

@end

@implementation Enemy

- (id)initEnemyWithDelegate:(id <GamePlaySceneDelegate>)aDelegate level:(NSUInteger)level
{
	self = [super initWithImageNamed:@"Sprites/Enemy/Enemy_1.png"];
	if (self)
	{
		NSAssert(aDelegate != nil, @"Delegate has to be set!");
		NSAssert([aDelegate conformsToProtocol:@protocol(GamePlaySceneDelegate)], @"Delegate has to conform to GamePlaySceneDelegateProtocol!");

		self.delegate = aDelegate;
		self.state = EnemyStateNormal;
        self.level = level;

		[self addBoundingBoxWithRect:CGRectMake(0.0, 0.0, 64.0, 44.0)];

        [self setupStats];

        [self setupAnimations];
	}

	return self;
}

- (void)setupStats
{
    double factor = 1.0 / GAME_LEVEL_MAX * _level;

    self.aiMovement = [[AIMovement alloc] initWithLevel:_level];

    self.timeSinceLastShot = 100.0; //(float) (3.0 * CCRANDOM_0_1());
    self.shotsPerSecond = [self shotsPerSecondForLevel];

    self.speedfactor = (float) (50.0 + 50.0 * factor);
    self.points = (int) (75 + 200 * factor);
    self.health = (int) (50 + 15 * factor);

    // NSLog(@"Level: %d, p: %d, h: %d, s: %.2f, sps: %.2f, f: %.2f", _level, _points, _health, _speedfactor, _shotsPerSecond, factor);
}

- (float)shotsPerSecondForLevel
{
    switch (_level)
    {
        case 1 :
            return 0.333;
        case 2 :
            return 0.5;
        case 3 :
            return 0.75;
        case 4 :
            return 1.0;
        case 5 :
            return 1.5;
        case 6 :
            return 2.0;
        case 7 :
            return 3.0;
        default: return 0.5;
    }
}

- (void)setupAnimations
{
    CCAnimation *spaceshipAnimation = [CCAnimation animation];

    [spaceshipAnimation addSpriteFrameWithFilename:@"Sprites/Enemy/Enemy_1.png"];
    [spaceshipAnimation addSpriteFrameWithFilename:@"Sprites/Enemy/Enemy_2.png"];
    [spaceshipAnimation addSpriteFrameWithFilename:@"Sprites/Enemy/Enemy_3.png"];
    [spaceshipAnimation addSpriteFrameWithFilename:@"Sprites/Enemy/Enemy_2.png"];
    spaceshipAnimation.delayPerUnit = (float) (TIME_CONSTANT_ANIMATION_DURATION_MULTIPLIER / 5.0);

    CCActionAnimate *spaceshipAnimationAction = [CCActionAnimate actionWithAnimation:spaceshipAnimation];
    spaceshipAnimationAction.duration = 1.0 * TIME_CONSTANT_ANIMATION_DURATION_MULTIPLIER;
    spaceshipAnimation.restoreOriginalFrame = YES;
    self.standardAnimation = [CCActionRepeatForever actionWithAction:spaceshipAnimationAction];

    [self runAction:self.standardAnimation];

    CCAnimation *explosionAnimation = [CCAnimation animation];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_1.png"];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_2.png"];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_3.png"];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_4.png"];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_5.png"];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_6.png"];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_7.png"];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_8.png"];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_9.png"];
    [explosionAnimation addSpriteFrameWithFilename:@"Sprites/Explosion/Explosion_10.png"];
    explosionAnimation.delayPerUnit = (float) (TIME_CONSTANT_ANIMATION_DURATION_MULTIPLIER / 1.3 / explosionAnimation.frames.count);

    [[CCAnimationCache sharedAnimationCache] addAnimation:explosionAnimation name:@"Explosion"];

    self.explosionAnimationAction = [CCActionAnimate actionWithAnimation:explosionAnimation];
}

- (void)updateStateWithTimeDelta:(CCTime)aTimeDelta andGameObjects:(NSArray *)gameObjects
{
	for (GameObject <WeaponProjectileProtocol> *gameObject in gameObjects)
	{
		if ([gameObject conformsToProtocol:@protocol(WeaponProjectileProtocol)])
		{
//			NSLog(@"1: %f.1 %f.1 %f.1 %f.1", rect1.origin.x, rect1.origin.y, rect1.size.width, rect1.size.height);
//			NSLog(@"2: %f.1 %f.1 %f.1 %f.1", rect2.origin.x, rect2.origin.y, rect2.size.width, rect2.size.height);

			if ([self detectCollisionWithGameObject:gameObject]
				&& gameObject.isActive
				&& ! [gameObject damagesSpaceship])
			{
				[self takeDamage:[gameObject damage]];

				[gameObject weaponHitTarget];
			}
		}
	}

	[self fireAtPlayer];
	self.timeSinceLastShot += aTimeDelta;

    CGPoint newPosition = [_aiMovement positionWithTimeDelta:aTimeDelta
                                                oldPoisition:self.position
                                                 speedfactor:_speedfactor];
	if (newPosition.y <= -50.0)
	{
		[self despawn];
	}
	else
	{
		self.position = newPosition;
	}
}

- (void)explode
{
	self.isActive = NO;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"TargetDestroyed"
														object:self];


    id sequence = [CCActionSequence actions:[CCActionCallFunc actionWithTarget:self selector:@selector(dropLoot)],
                                            _explosionAnimationAction,
                                            [CCActionCallFunc actionWithTarget:self selector:@selector(despawn)],
                                            nil];
    [self stopAction:_standardAnimation];
	[self runAction:sequence];
}

- (void)dropLoot
{
    int rng = arc4random() % 1000 + 1;
    NSLog(@"RNG: %d", rng);
    if (rng <= 200);
    {
        GameObject *loot;

        int lootType = arc4random()  % 3 +1;
        switch (lootType)
        {
            case 1: loot = [[HealthLoot alloc] initWithDelegate:_delegate]; break;
            case 2: loot = [[ShieldLoot alloc] initWithDelegate:_delegate]; break;
            default: loot = [[PointLoot alloc] initWithDelegate:_delegate]; break;
        }

        NSLog(@"Dropping: %@", [loot class]);

        loot.position = self.position;
        [_delegate addGameEntity:loot];
    }
}

- (void)takeDamage:(int)damageTaken
{
	self.health -= damageTaken;

	if (_health <= 0)
	{
		[self explode];

		[_delegate addPoints:_points];
	}
	else
	{
		self.hitAnimation = [CCAnimation animation];

		[_hitAnimation addSpriteFrameWithFilename:@"Sprites/Enemy/Enemy_hit.png"];
        _hitAnimation.delayPerUnit = 0.1;

        self.hitAnimationAction = [CCActionAnimate actionWithAnimation:_hitAnimation];
        _hitAnimationAction.duration = 0.1 * TIME_CONSTANT_ANIMATION_DURATION_MULTIPLIER;
        _hitAnimation.restoreOriginalFrame = YES;

		[self runAction:_hitAnimationAction];
	}
}

- (void)fireAtPlayer
{
	if ([self areCannonsReady])
	{
        EnemyShot *aShot = [[EnemyShot alloc] initEnemyShotWithStartPosition:self.position andTarget:[_delegate spaceship] level:NULL];



		// NSLog(@"*********** FIRING FROM %f.2 %f.2 !!! ***************", aShot.position.x, aShot.position.y);
		[_delegate addGameEntity:aShot];
	}

/*
    if ([self areCannonsReady])
	{
		HomingMissile *homingMissile = [HomingMissile enemyHomingMissileWithStartPosition:self.position
																		  andTargetObject:[delegate spaceship]
																				 delegate:self.delegate];

		// NSLog(@"*********** FIRING FROM %f.2 %f.2 !!! ***************", aShot.position.x, aShot.position.y);

		[delegate addGameEntity:homingMissile];
	}
*/
}

- (BOOL)areCannonsReady
{
    // NSLog(@"-> %.2f / %.2f", _timeSinceLastShot, (1.0 / _shotsPerSecond) );

	if (_timeSinceLastShot >= (1.0 / _shotsPerSecond))
	{
		self.timeSinceLastShot = 0.0;
		return YES;
	}
	
	return NO;
}

@end