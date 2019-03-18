package art;

import flixel.math.FlxVector;
import data.ReflectEvent;
import flixel.math.FlxMath;
import flixel.input.FlxInput.FlxInputState;
import art.Hero.Key;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

class Enemy extends Hero
{
    inline static var SPEED_SCALE = 1.1;
    inline static var LEVEL_SIZE = 20;
    inline static var TILE_SIZE = Hero.TILE_SIZE;
    inline static var X_LEFT   = 24.0 * TILE_SIZE;
    inline static var X_RIGHT  = 27.0 * TILE_SIZE;
    inline static var X_EDGE  = 30.0 * TILE_SIZE;
    static var heights:Array<Float> =
        [ (LEVEL_SIZE - 1 ) * TILE_SIZE
        , (LEVEL_SIZE - 4 ) * TILE_SIZE
        , (LEVEL_SIZE - 8 ) * TILE_SIZE
        , (LEVEL_SIZE - 12) * TILE_SIZE
        , (LEVEL_SIZE - 16) * TILE_SIZE
        ];
    static var sides:Array<Float> = 
        [ X_EDGE
        , X_RIGHT
        , X_LEFT
        , X_RIGHT
        , X_RIGHT
        ];
    
    var section:Int = -1;
    var debugObj:FlxObject;
    
    public function new (ball:Ball, debugObj:FlxSprite = null)
    {
        super(ball, false, "assets/art/enemy1.png");
        
        // ballHitbox = this;
        // bodyBox = null;
        // attackBox = null;
        
        if (debugObj != null)
        {
            this.debugObj = debugObj;
            debugObj.makeGraphic(Std.int(width), Std.int(height), 0x40FF0000);
        }
        npcMode = true;
    }
    
    override function updateKeys()
    {
        if (isTouching(FlxObject.DOWN))
        {
            section = 4 - Std.int(y / FlxG.height * 6);
        }
        
        var targetSection = 2;
        
        if (ball.velocity.x > 0 && ball.moves)
        {
            // get balls height 0.5 second in the future based on current v
            var guessY = ball.y;
            if (x > ball.x)
            {
                var t = (x - ball.x) / ball.velocity.x;
                if (t > 0.5)
                    t = 0.5;
                guessY += ball.velocity.y * t;
                if (guessY < 0) guessY = 0;
                if (guessY > heights[0]) guessY = heights[0];
            }
            
            targetSection = getNearestSection(guessY);
            // if (debugObj != null)
            // {
            //     debugObj.setPosition(x, guessY);
            // }
        }
        
        if (debugObj != null)
        {
            var targetPos = getTargetPos(targetSection);
            debugObj.setPosition(targetPos.x, targetPos.y);
            targetPos.put();
        }
        
        var goingUp = false;
        var nextSection = targetSection;
        if(targetSection != 0)// accessible anywhere
        {
            if (section < targetSection)
            {
                nextSection = section + 1;
                goingUp = nextSection != 4 || ball.x + ball.velocity.x * Hero.TIME_TO_MAX >= x;
            }
            else if (section > targetSection)
                nextSection = section - 1;
        }
        
        var nextPos = getTargetPos(nextSection);
        if (nextSection == 2 && section > nextSection && ball.velocity.x > 0)
            nextPos.x = X_EDGE;
        
        press(UP, goingUp);
        press(RIGHT, nextPos.x - 2 > x);
        press(LEFT, nextPos.x + 2 < x);
        nextPos.put();
    }
    
    function getTargetPos(index:Int):FlxPoint
    {
        return FlxPoint.get
            ( sides[index] - width
            , heights[index] - height
            );
    }
    
    function getNearestSection(y:Float):Int
    {
        var i = 0;
        while(heights[i] > y)
            i++;
        return i - 1;
    }
    
    function press(key:Key, condition:Bool):Void
    {
        keyStates[key] = condition
            ? (!pressed(key) ? JUST_PRESSED : PRESSED)
            : (pressed(key) ? JUST_RELEASED : RELEASED);
    }
    
    override function reflect(ball:Ball):Null<ReflectEvent>
    {
        if (ball.velocity.x < 0)
            return null;
        
        var vel = FlxVector.get();
        switch (deflection)
        {
            case UP  :
                vel.set(-1, -1).scale(ball.speed / FlxMath.SQUARE_ROOT_OF_TWO);
            case DOWN:
                vel.set(-1, 1).scale(ball.speed / FlxMath.SQUARE_ROOT_OF_TWO);
            case NONE:
                vel.y = (ball.centerY - centerY) / height * 2;
                if (vel.y >  1) vel.y =  1;
                if (vel.y < -1) vel.y = -1;
                
                vel.x = -Math.sqrt(2 - vel.y * vel.y);
                vel.scale(ball.speed / FlxMath.SQUARE_ROOT_OF_TWO);
        }
        return new ReflectEvent(FlxObject.LEFT, vel, this);
    }
    
    override function resolveReflect(data:ReflectEvent)
    {
        super.resolveReflect(data);
        
        ball.speed *= SPEED_SCALE;
        ball.velocity.x *= SPEED_SCALE;
        ball.velocity.y *= SPEED_SCALE;
    }
}