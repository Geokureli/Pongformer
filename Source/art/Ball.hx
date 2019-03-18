package art;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;

class Ball extends FlxSprite
{
    static inline public var SIZE = 8;
    static inline public var CENTER = SIZE / 2;
    static inline public var EDGE = 8;
    static inline var START_SPEED = 75;
    
    public var speed:Float;
    public var centerX(get, never):Float;
    public var centerY(get, never):Float;
    public var lastHit(default, null):Null<FlxObject>;
    var hit:Null<FlxObject>;
    
    var stunTimer = 0.0;
    
    public function new()
    {
        super();
        
        loadGraphic("assets/art/ball.png", true, 10, 10);
        animation.add("idle", [0]);
        animation.add(Std.string(FlxObject.LEFT ), [1, 0], 30, false);
        animation.add(Std.string(FlxObject.RIGHT), [2, 0], 30, false);
        animation.add(Std.string(FlxObject.UP   ), [3, 0], 30, false);
        animation.add(Std.string(FlxObject.DOWN ), [4, 0], 30, false);
        width = 8;
        height = 8;
        offset.set(1, 1);
        
        setPosition((FlxG.width - SIZE) / 2, (FlxG.height - SIZE) / 2);
        moves = false;
        new FlxTimer().start
            ( 1.0
            ,   (_) ->
                {
                    moves = true;
                    respawn(true, FlxG.random.bool(50));
                }
            );
    }
    
    public function respawn(now:Bool, moveRight:Bool):Void
    {
        if (now)
        {
            stunTimer = 0;
            setPosition((FlxG.width - SIZE) / 2, (FlxG.height - SIZE) / 2);
            speed = START_SPEED;
            velocity.y = FlxG.random.float(-1, 1);
            velocity.x = Math.sqrt(2 - velocity.y * velocity.y);
            velocity.scale(speed / FlxMath.SQUARE_ROOT_OF_TWO);
            
            if (!moveRight)
                velocity.x *= -1;
        }
        else
        {
            moves = false;
            
            FlxFlicker.flicker
                ( this
                , 1
                , 0.04
                , true
                , true
                ,   (_) ->
                    {
                        respawn(true, moveRight);
                        new FlxTimer().start(1.0, (_) -> { moves = true; });
                    }
                );
        }
    }
    
    override function update(elapsed:Float) {
        
        if (stunTimer > 0)
        {
            stunTimer -= elapsed;
            if (stunTimer <= 0)
                moves = true;
            else
                return;
        } 
        
        super.update(elapsed);
        lastHit = hit;
        hit = null;
        
        if (y < EDGE)
        {
            velocity.y *= -1;
            y = EDGE;
            
            shakeY();
            playAnim(FlxObject.UP);
        }
        else if (y + height > FlxG.height - EDGE)
        {
            velocity.y *= -1;
            y = FlxG.height - EDGE - height;
            shakeY();
            playAnim(FlxObject.DOWN);
        }
    }
    
    public function onHit(sprite:FlxSprite):Void
    {
        if (Std.is(sprite, IReflector))
        {
            var reflector:IReflector = cast sprite;
            var hitEvent = reflector.reflect(this);
            if (hitEvent == null)
                return;
            
            hit = hitEvent.attacker;
            if (lastHit == hit)
                return;
            
            reflector.resolveReflect(hitEvent);
            
            if (hitEvent.ballMove != null)
            {
                x += hitEvent.ballMove.x;
                y += hitEvent.ballMove.y;
            }
            
            velocity.copyFrom(hitEvent.ballVelocity);
            stunTimer += reflector.stunTime;
            moves = false;
            reflector.stun(reflector.stunTime);
            animation.play(Std.string(hitEvent.ballDirection));
            hitEvent.destroy();
        }
        else if (lastHit != sprite)
        {
            velocity.y = (y - sprite.y + (height - sprite.height) / 2) / sprite.height * 2 * Math.abs(velocity.x);
            velocity.x *= -1;
        }
        
        shake();
    }
    
    function shake(intesnity:Float = 0.01, duration:Float = 0.125, ?axes):Void
    {
        FlxG.camera.shake(intesnity, duration, null, true, axes);
    }
    
    function shakeX(intesnity:Float = 0.01, duration:Float = 0.125):Void
    {
        shake(intesnity, duration, X);
    }
    
    function shakeY(intesnity:Float = 0.01, duration:Float = 0.125):Void
    {
        shake(intesnity, duration, Y);
    }
    
    function playAnim(dir:Int):Void
    {
        animation.play(Std.string(dir));
    }
    
    inline function get_centerX() { return x + CENTER; }
    inline function get_centerY() { return y + CENTER; }
}