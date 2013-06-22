//
//  SpellSprite.m
//  WizardWar
//
//  Created by Sean Hess on 5/17/13.
//  Copyright (c) 2013 The LAB. All rights reserved.
//

#import "SpellSprite.h"
#import "cocos2d.h"
#import "SpellFireball.h"
#import "SpellEarthwall.h"
#import "SpellVine.h"
#import "SpellMonster.h"
#import "SpellBubble.h"
#import "SpellIcewall.h"
#import "SpellWindblast.h"
#import "SpellInvisibility.h"
#import "SpellFirewall.h"
#import "SpellFist.h"
#import "SpellHelmet.h"
#import "SpellSleep.h"
#import "EffectSleep.h"
#import <ReactiveCocoa.h>

@interface SpellSprite ()
@property (nonatomic, strong) Units * units;
@property (nonatomic, strong) CCSprite * skin;
@property (nonatomic, strong) CCSpriteBatchNode * sheet;
@property (nonatomic, strong) CCAction * frameAnimation;
@property (nonatomic, strong) CCSpriteBatchNode * explosion;
@property (nonatomic) NSInteger currentAltitude;
@end

@implementation SpellSprite

+(void)loadSprites {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"LOAD SPELL SPRITES");
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"explode.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"explode-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"fireball.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"fireball-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"earthwall.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"earthwall-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"vine.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"vine-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"ogre.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"ogre-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"bubble.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"bubble-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"icewall.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"icewall-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"firewall.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"firewall-animation.plist"];
        
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"windblast.plist"];
        [[CCAnimationCache sharedAnimationCache] addAnimationsWithFile:@"windblast-animation.plist"];        
    });
}


-(id)initWithSpell:(Spell*)spell units:(Units *)units {
    if ((self=[super init])) {
        self.spell = spell;
        self.units = units;
        
        if (spell.targetSelf) {
            return self;
        }
        
        [SpellSprite loadSprites];
        
        // STATIC sprites
        if ([spell isType:[SpellFist class]] || [spell isType:[SpellHelmet class]] || [spell isType:[SpellSleep class]] ) {
            self.skin = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@.png", self.sheetName]];
            [self addChild:self.skin];
            
            if ([spell class] == [SpellSleep class]) {
                CCActionInterval * rotate = [CCRotateBy actionWithDuration:1.4 angle:360.0];
                [self.skin runAction:[CCRepeatForever actionWithAction:rotate]];
            }
        }

        // ANIMATED sprites
        else {
            self.sheet = [CCSpriteBatchNode batchNodeWithFile:[NSString stringWithFormat:@"%@.png", self.sheetName]];
            [self addChild:self.sheet];
            
            self.skin = [CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"%@-1.png", self.sheetName]];
            self.frameAnimation = self.spellAction;
            [self.skin runAction:self.frameAnimation];
            [self.sheet addChild:self.skin];            
        }
        
        
        
        
        // TODO add a cool reduce thing to make sure they both get changed or something
        
        [[RACAble(self.spell.position) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderPosition];
        }];
        
        [[RACAble(self.spell.strength) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderWallStrength];
        }];
        
        
        [[RACAble(self.spell.status) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderStatus];
        }];
        
        [[RACAble(self.spell.direction) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderDirection];
        }];
        
        [[RACAble(self.spell.effect) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderEffect];
        }];
        
        self.currentAltitude = self.spell.altitude;
        [[RACAble(self.spell.altitude) distinctUntilChanged] subscribeNext:^(id x) {
            [self renderAltitude];
        }];

        
        
        [self renderPosition];
        [self renderWallStrength];
        [self renderDirection];
        [self renderStatus];
        [self renderAltitude];
    }
    return self;
}

-(BOOL)isWall:(Spell*)spell {
    return ([self.spell isType:[SpellEarthwall class]] || [self.spell isType:[SpellIcewall class]]);
}

-(void)renderDirection {
    self.skin.flipX = (self.spell.direction < 0);
}

-(void)renderPosition {
    self.position = ccp(self.spellX, self.spellY);
}

- (CGFloat)spellY {
    CGFloat y = self.units.zeroY + 100*self.spell.altitude;

    if ([self isWall:self.spell] || [self.spell class] == [SpellFirewall class]) {
        // bump walls down
        y -= 25;
    }
    
    else if ([self.spell isType:[SpellHelmet class]]) {
        y += 30;
    }

    return y;
}

- (CGFloat)spellX {
    
    CGFloat x = [self.units toX:self.spell.position];
    
    if ([self.spell isType:[SpellHelmet class]]) {
        x -= 15*self.spell.direction;
    }
    
    return x;
}

- (void)renderAltitude { 
    if ([self.spell isType:[SpellFist class]]) {
        if (self.spell.altitude == 2) {

        }
        else if (self.spell.altitude == 1) {
            [self runAction:[CCMoveTo actionWithDuration:1.0 position:ccp(self.spellX, self.units.zeroY + 120)]];
        }        
    }
}

- (void)renderWallStrength {
    if (![self isWall:self.spell]) return;
    NSString * frameName = [NSString stringWithFormat:@"%@-%i.png", self.sheetName, (self.spell.strength+1)];
    [self.skin setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:frameName]];
}

- (void)renderStatus {
    self.skin.visible = (self.spell.status == SpellStatusActive || self.spell.status == SpellStatusPrepare);
    
    if (!self.explosion && self.spell.status == SpellStatusDestroyed) {
        self.explosion = [CCSpriteBatchNode batchNodeWithFile:@"explode.png"];
        [self addChild:self.explosion];
        CCSprite * sprite = [CCSprite spriteWithSpriteFrameName:@"explode-1"];
        [sprite runAction:self.explodeAction];
        [self.explosion addChild:sprite];
    }
}

- (void)renderEffect {
    if (self.spell.targetSelf) return;
    
    if ([self.spell.effect class] == [EffectSleep class]) {
        CCFiniteTimeAction * toPos = [CCMoveTo actionWithDuration:0.2 position:ccp(self.spellX, self.spellY - 30)];
        CCFiniteTimeAction * rotate = [CCRotateTo actionWithDuration:0.2 angle:90.0];
        [self stopAction:self.self.frameAnimation];
        [self runAction:toPos];
        [self runAction:rotate];
    }
    
    else {
        [self runAction:[CCMoveTo actionWithDuration:0.2 position:ccp(self.spellX, self.spellY)]];
        [self runAction:[CCRotateTo actionWithDuration:0.2 angle:0]];
    }
}

-(NSString*)sheetName {
    if ([self.spell isType:[SpellEarthwall class]]) {
        return @"earthwall";
    }
    
    else if ([self.spell isType:[SpellVine class]]) {
        return @"vine";
    }
    
    else if ([self.spell isType:[SpellMonster class]]) {
        return @"ogre";
    }
    
    else if ([self.spell isType:[SpellBubble class]]) {
        return @"bubble";
    }
    
    else if ([self.spell isType:[SpellIcewall class]]) {
        return @"icewall";
    }
    
    else if ([self.spell isType:[SpellWindblast class]]) {
        return @"windblast";
    }
    
    else if ([self.spell isType:[SpellFirewall class]]) {
        return @"firewall";
    }

    else if ([self.spell isType:[SpellFist class]]) {
        return @"fist";
    }
    
    else if ([self.spell isType:[SpellHelmet class]]) {
        return @"helmet";
    }
    
    else if ([self.spell isType:[SpellSleep class]]) {
        return @"pillow";
    }
    
    return @"fireball";
}

-(CCAction*)spellAction {
    CCAnimation *animation = [[CCAnimationCache sharedAnimationCache] animationByName:self.castAnimationName];
    animation.restoreOriginalFrame = NO;
    
    CCActionInterval * actionInterval = [CCAnimate actionWithAnimation:animation];
    CCAction * action = actionInterval;
    
    if ([self.spell isType:[SpellFireball class]] || [self.spell isType:[SpellBubble class]] || [self.spell isType:[SpellWindblast class]] || [self.spell isType:[SpellMonster class]]) {
        action = [CCRepeatForever actionWithAction:actionInterval];
    }
    
    else if (self.spell.class == SpellFirewall.class) {
        
        // also do a start animation!
        // WOW this is a hack.
        // Why can't I just play the normal one after the first one is done?
        // I hate cocos2d
        CCAnimation * startAnimation = [[CCAnimationCache sharedAnimationCache] animationByName:@"firewall-start"];
        CCActionInterval * start = [CCAnimate actionWithAnimation:startAnimation];
        CCActionInterval * burn = [CCRepeat actionWithAction:actionInterval times:10000];
        CCSequence * startThenBurn = [CCSequence actions:start, burn, nil];
        action = startThenBurn;
    }
    
    return action;
}

-(NSString*)castAnimationName {
    return [NSString stringWithFormat:@"%@-cast", self.sheetName];
}

-(CCAction*)explodeAction {
    CCAnimation *animation = [[CCAnimationCache sharedAnimationCache] animationByName:@"explode"];
    animation.restoreOriginalFrame = NO;
    CCActionInterval * actionInterval = [CCAnimate actionWithAnimation:animation];
    return actionInterval;
}

@end
