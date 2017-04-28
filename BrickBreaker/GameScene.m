//
//  GameScene.m
//  BrickBreaker
//
//  Created by Ethan Peacock on 12/18/14.
//  Copyright (c) 2014 EthanPeacock. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene
{
    SKSpriteNode *_paddle;
    CGPoint _touchLocation;
    CGFloat _ballSpeed;
    SKNode *_brickLayer;
    
}

static const uint32_t kBallCategory    = 0x1 << 0;
static const uint32_t kPaddleCategory  = 0x1 << 1;
static const uint32_t   kBrickCategory = 0x1 << 2;

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    
    
    //getting correct frame size!!!!!!!!!
    self.size = self.view.frame.size;
    
    
    self.backgroundColor = [SKColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    
    //turnoff gravity
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    
    //set contact delegate
    self.physicsWorld.contactDelegate = self;
    
    //setting up edge
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    
    [self createBallWithLocation:CGPointMake(self.size.width * 0.5, self.size.height * 0.5) andVelocity:CGVectorMake(40, 180)];
    
    // set up brick layer
    _brickLayer = [SKNode node];
    _brickLayer.position = CGPointMake(0, self.size.height);
    [self addChild:_brickLayer];
    
    // adding some bricks.
    for (int row = 0; row < 5; row++) {
        for (int col = 0; col < 7; col++) {
            SKSpriteNode *brick = [SKSpriteNode spriteNodeWithImageNamed:@"NeonGreenBrick"];
            brick.position = CGPointMake(2 + (brick.size.width * 0.5) + ((brick.size.width + 3) * col)
                                         , -(2 + (brick.size.height * 0.5) + ((brick.size.height + 3) * row)));
            
            brick.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:brick.size];
            
            brick.physicsBody.categoryBitMask = kBrickCategory;
            //fixing bricks in place
            brick.physicsBody.dynamic = NO;
            
            
            [_brickLayer addChild:brick];
        }
    }    
    
    
    
    
    
    _paddle = [SKSpriteNode spriteNodeWithImageNamed:@"GPaddle"];
    _paddle.position = CGPointMake(self.size.width * 0.5, 100);
    _paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_paddle.size];
    _paddle.physicsBody.dynamic = NO;
    _paddle.physicsBody.categoryBitMask = kPaddleCategory;
    [self addChild:_paddle];
    
    // set initial values
    _ballSpeed = 300.0;
}

-(SKSpriteNode*)createBallWithLocation:(CGPoint)position andVelocity:(CGVector)velocity {
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"gball"];
    ball.name = @"ball";
    ball.position = position;
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ball.size.width * 0.5];
    ball.physicsBody.friction = 0.0;
    ball.physicsBody.linearDamping = 0.0;
    ball.physicsBody.restitution = 1.0;
    ball.physicsBody.velocity = velocity;
    ball.physicsBody.categoryBitMask = kBallCategory;
    ball.physicsBody.contactTestBitMask = kPaddleCategory | kBrickCategory;
    [self addChild:ball];
    
    

    
    
    
    return ball;
    
    
    
}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstbody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask) {
        firstbody = contact.bodyB;
        secondBody = contact.bodyA;
    } else {
        firstbody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    
    if (firstbody.categoryBitMask == kBallCategory && secondBody.categoryBitMask == kBrickCategory) {
        [self addExplosion:firstbody.node.position withName:@"GreenBreak"];
        [self addExplosion:secondBody.node.position withName:@"GreenBrickBreak"];
        [secondBody.node runAction:[SKAction removeFromParent]];
    }
    
    
    
    

    if (firstbody.categoryBitMask == kBallCategory && secondBody.categoryBitMask == kPaddleCategory) {
        if (firstbody.node.position.y > secondBody.node.position.y) {
        //get contact point in paddle coordinates
        CGPoint pointInPaddle = [secondBody.node convertPoint:contact.contactPoint fromNode:self];
        //get contact position as a percentage of the paddle's width
        CGFloat x = (pointInPaddle.x + secondBody.node.frame.size.width * 0.5) / secondBody.node.frame.size.width;
        // cap percentage and flip it
        CGFloat multiplier = 1.0 - fmaxf(fminf(x, 1.0), 0.0);
        //calculate angle based on ball and position in paddle.
        CGFloat angle = (M_PI_2 * multiplier) + M_PI_4;
        //convert angle to vector.
        CGVector direction = CGVectorMake(cosf (angle), sinf(angle));
        // set ball's velocity based on direction and speed
        firstbody.velocity = CGVectorMake(direction.dx * _ballSpeed, direction.dy * _ballSpeed);
        }
    }
}

-(void)addExplosion:(CGPoint)position withName:(NSString*)name
{
    NSString *explostionPath = [[NSBundle mainBundle]pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explostionPath];
    
    explosion.position = position;
    [self addChild:explosion];
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    [explosion runAction:removeExplosion];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    for (UITouch *touch in touches) {
        _touchLocation = [touch locationInNode:self];
    }
}


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *touch in touches) {
        //calculate how far touch has moved on x axis
        CGFloat xMovment = [touch locationInNode:self].x - _touchLocation.x;
        //move paddle distance of touch
        _paddle.position = CGPointMake(_paddle.position.x + xMovment, _paddle.position.y);
        
        
        CGFloat paddleMinX = -_paddle.size.width * 0.25;
        CGFloat paddleMaxX = self.size.width + (_paddle.size.width * 0.25);
        
        
        //cap paddles position so it remains on screen
        if (_paddle.position.x < paddleMinX) {
            _paddle.position = CGPointMake(paddleMinX, _paddle.position.y);
        }
        if (_paddle.position.x > paddleMaxX) {
            _paddle.position = CGPointMake(paddleMaxX, _paddle.position.y);
        }
        
        
        _touchLocation = [touch locationInNode:self];
    }
}




-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
