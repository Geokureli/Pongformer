package art;

import flixel.math.FlxVector;
import data.ReflectEvent;
import data.HitboxParser;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;

class Hero extends art.SkidSprite
    implements IReflector
{
    inline static var TILE_SIZE = 8;
    inline static var RESPAWN_TIME = 1.0;
    
    inline static var MAX_HEIGHT = TILE_SIZE * 4.5;
    inline static var MIN_HEIGHT = TILE_SIZE * 1.5;
    inline static var TIME_TO_MAX = 0.35;
    inline static var JUMP_WIDTH = TILE_SIZE * 5;
    inline static var COYOTE_TIME = 0;

    inline static var JUMP_SPEED = -2 * MAX_HEIGHT / TIME_TO_MAX;
    inline static var GRAVITY = 2 * MAX_HEIGHT / TIME_TO_MAX / TIME_TO_MAX;
    inline static var FAST_GRAVITY = JUMP_SPEED * JUMP_SPEED / MIN_HEIGHT / 2;
    
    inline static var X_SPEED = JUMP_WIDTH / TIME_TO_MAX / 2;
    inline static var X_STOP_TIME = .125;
    inline static var X_ACCEL = X_SPEED / X_STOP_TIME;
    
    
    public var stunTime(default, null):Float = 0.2;
    public var deflection(default, null):Deflection = NONE;
    public var onCoyoteGround(get, never):Bool;
    public var centerX(get, never):Float;
    public var centerY(get, never):Float;
    public var ballHitbox(default, null):FlxObject;
    
    var hitboxData:Map<String, Array<Null<Rect>>>;
    var attackBox(default, null):FlxObject;
    var bodyBox(default, null):FlxObject;
    
    var stunTimer = 0.0;
    var spawnPoint = FlxPoint.get();
    var coyoteTimer = 0.0;
    var ball:Ball;
    
    var keys:Map<Key, Array<FlxKey>> = new Map();
    var keyStates:Map<Key, FlxInputState> = new Map();
    var npcMode = false;
    var touchingBall:Bool = false;
    
    public function new (ball:Ball, isPlayer1:Bool, ?isPvp:Bool = false, ?graphic:FlxGraphicAsset)
    {
        super();
        
        this.ball = ball;
        
        if (graphic == null)
            graphic = "assets/art/hero.png";
        
        loadGraphic(graphic, true, 15, 26);
        animation.add("idle", [0]);
        animation.add("jump", [4]);
        animation.add("fall", [5]);
        animation.add("walk", [0, 1, 2, 3], 8);
        animation.add("jump_down", [6]);
        animation.add("jump_up", [7]);
        animation.play("idle");
        
        width = 7;
        centerOffsets();
        height = 24;
        origin.set(width / 2, height / 2);
        
        if (isPvp || isPlayer1)
        {
            hitboxData = HitboxParser.parse("assets/data/hitboxes.json", -Std.int(offset.x), -Std.int(offset.y));
            ballHitbox = new FlxObject(0, 0, frameWidth, frameHeight);
            bodyBox = new FlxObject();
            attackBox = new FlxObject();
            
            if (FlxG.debugger.drawDebug)
            {
                // FlxG.state.add(ballHitbox);
                // FlxG.state.add(bodyBox);
                FlxG.state.add(attackBox);
            }
        }
        else
        {
            ballHitbox = this;
        }
        
        x = isPlayer1 ? 40 : FlxG.width - 40 - width;
        y = FlxG.height - height - 16;
        getPosition(spawnPoint);
        
        if (isPlayer1)
        {
            if (isPvp)
                setKeys([A], [D], [W], [S]);
            else
                setKeys([A, LEFT], [D, RIGHT], [W, UP], [S, DOWN]);
        }
        else
            setKeys([LEFT], [RIGHT], [UP], [DOWN]);
        
        acceleration.y = GRAVITY;
        drag.x = X_ACCEL;
        maxVelocity.x = X_SPEED;
    }
    
    /**
     * Sets which keys perform various actions
     */
    public function setKeys(left:Array<FlxKey>, right:Array<FlxKey>, up:Array<FlxKey>, down:Array<FlxKey>):Void
    {
        keys[Key.LEFT ] = left;
        keys[Key.RIGHT] = right;
        keys[Key.UP   ] = up;
        keys[Key.DOWN ] = down;
        
        keyStates[Key.LEFT ] = RELEASED;
        keyStates[Key.RIGHT] = RELEASED;
        keyStates[Key.UP   ] = RELEASED;
        keyStates[Key.DOWN ] = RELEASED;
    }
    
    public function stun(time:Float):Void
    {
        stunTimer = time;
    }
    
    override function update(elapsed:Float)
    {
        if (stunTimer > 0)
        {
            stunTimer -= elapsed;
            return;
        }
        
        updateKeys();
        
        acceleration.x = X_ACCEL * ((pressed(RIGHT) ? 1 : 0) - (pressed(LEFT) ? 1 : 0));
        
        coyoteTimer += elapsed;
        if (isTouching(FlxObject.FLOOR))
            coyoteTimer = 0;
        
        if (onCoyoteGround)
        {
            if (justTouched(FlxObject.FLOOR))
            {
                acceleration.y = GRAVITY;
                deflection = NONE;
            }
            
            if (npcMode ? pressed(UP) : justPressed(UP))
                velocity.y = JUMP_SPEED;
        }
        else
        {
            if (justPressed(UP))
            {
                deflection = UP;
            }
            else if (justPressed(DOWN))
            {
                deflection = DOWN;
            }
            else if (!pressed(UP) && !pressed(DOWN))
            {
                deflection = NONE;
            }
        }
        
        updateAnim();
        
        super.update(elapsed);
        
        updateHitboxes();
        
        if (y + height > FlxG.height && moves)
            respawn();
    }
    
    function updateKeys():Void
    {
        inline function updateKey(key:Key)
        {
            keyStates[key] = 
                if(FlxG.keys.anyJustPressed(keys[key]))        JUST_PRESSED;
                else if(FlxG.keys.anyPressed(keys[key]))       PRESSED;
                else if(FlxG.keys.anyJustReleased(keys[key]))  JUST_RELEASED;
                else                                           RELEASED; 
        }
        
        updateKey(LEFT );
        updateKey(RIGHT);
        updateKey(UP   );
        updateKey(DOWN );
    }
    
    function updateAnim():Void
    {
        if (isTouching(FlxObject.FLOOR))
        {
            if (acceleration.x != 0)
            {
                animation.play("walk");
                flipX = acceleration.x < 0;
            }
            else
                animation.play("idle");
        }
        else
        {
            if (wasTouching & FlxObject.FLOOR > 0)
                flipX = ball.centerX < centerX;
            
            if (deflection == UP)
                animation.play("jump_up");
            else if (deflection == DOWN)
                animation.play("jump_down");
            else
                animation.play(velocity.y > 0 ? "fall" : "jump");
        }
    }
    
    function updateHitboxes():Void
    {
        // update hitboxes
        if (hitboxData != null)
        {
            updateHitboxFromData("body"  , bodyBox);
            updateHitboxFromData("attack", attackBox);
            ballHitbox.x = x - offset.x;
            ballHitbox.y = y - offset.y;
        }
    }
    
    inline function updateHitboxFromData(rectName:String, box:FlxObject):Void
    {
        var rect = hitboxData[rectName][animation.frameIndex];
        // trace('$rectName[${animation.frameIndex}] ' 
        //     + (rect == null ? null : '${rect.x} ${rect.x} ${rect.x} ${rect.x}'));
        if (rect == null)
        {
            box.exists = false;
        }
        else
        {
            box.x = x + rect.x;
            box.y = y + rect.y;
            box.width  = rect.w;
            box.height = rect.h;
            box.exists = true;
        }
    }
    
    public function reflect(ball:Ball):Null<ReflectEvent>
    {
        inline function getArea(rect:FlxRect):Float
        {
            if (rect == null)
                return 0;
            
            var area = rect.width * rect.height;
            rect.putWeak();
            return area;
        }
        
        var bodyOverlap:Null<FlxRect> = null;
        
        if (bodyBox != null)
        {
            bodyOverlap = FlxRect.weak(ball.x, ball.y, ball.width, ball.height)
                .intersection(FlxRect.weak(bodyBox.x, bodyBox.y, bodyBox.width, bodyBox.height));
            
            if (bodyOverlap.width * bodyOverlap.height == 0)
            {
                bodyOverlap.put();
                bodyOverlap = null;
            }
        }
        
        if (attackBox.exists)
        {
            var attackArea = 
                getArea(FlxRect.weak(ball.x, ball.y, ball.width, ball.height)
                    .intersection(FlxRect.weak(attackBox.x, attackBox.y, attackBox.width, attackBox.height))
                );
            
            if (attackArea > 0 && attackArea > getArea(bodyOverlap) && (ball.y > attackBox.y || deflection == UP))
            {
                switch (deflection)
                {
                    case UP: return new ReflectEvent
                        ( FlxObject.UP
                        , ReflectEvent.vectorFromDiagonal(flipX ? -1 : 1, -1, ball.speed)
                        , this
                        );
                    case DOWN: return new ReflectEvent
                        ( FlxObject.DOWN
                        , ReflectEvent.vectorFromDiagonal(velocity.x < 0 ? -1 : 1, 1, ball.speed)
                        , this
                        , null
                        , FlxVector.get(0, attackBox.y - (ball.y - attackBox.height))
                        , FlxObject.UP
                        );
                    default:
                        throw "Unexpected deflection: NONE";
                }
                return null;
            }
        }
        
        if (bodyOverlap == null)
            return null;
        
        if (bodyOverlap.width <= bodyOverlap.height)
        {
            var vel:FlxVector;
            switch (deflection)
            {
                case UP  :
                    vel = ReflectEvent.vectorFromDiagonal(-FlxMath.signOf(ball.velocity.x), -1, ball.speed);
                case DOWN:
                    vel = ReflectEvent.vectorFromDiagonal(-FlxMath.signOf(ball.velocity.x), 1, ball.speed);
                case NONE:
                    vel = FlxVector.get(0, (ball.centerY - centerY) / height * 2);
                    if (vel.y >  1) vel.y =  1;
                    if (vel.y < -1) vel.y = -1;
                    
                    vel.x
                        = (ball.velocity.x > 0 ? -1 : 1)
                        * Math.sqrt(2 - vel.y * vel.y);
                    vel.scale(ball.speed / FlxMath.SQUARE_ROOT_OF_TWO);
            }
            trace("left");
            return new ReflectEvent
                ( ball.velocity.x > 0 ? FlxObject.LEFT : FlxObject.RIGHT
                , vel
                , this
                , FlxVector.get(bodyBox.x + (ball.velocity.x < 0 ? bodyBox.width : -ball.width) - ball.x)
                );
        }
        
        // TOP/BOTTOM
        
        if (centerY <= ball.centerY)
        {
            // player is above
            return new ReflectEvent
                ( FlxObject.DOWN
                , ReflectEvent.vectorFromDiagonal(velocity.x > 0 ? 1 : -1, 1, ball.speed)
                , this
                , null
                , FlxVector.get(0, bodyOverlap.height)
                , FlxObject.UP
                );
        }
        
        // player is below
        return new ReflectEvent
            ( FlxObject.UP
            , ReflectEvent.vectorFromDiagonal(flipX ? -1 : 1, -1, ball.speed)
            , this
            , null
            , FlxVector.get(0, bodyOverlap.height)
            , FlxObject.DOWN
            );
    }
    
    public function resolveReflect(data:ReflectEvent):Void
    {
        if (data.attackerMove != null)
        {
            trace(data.attackerMove);
            x += data.attackerMove.x;
            y += data.attackerMove.y;
        }
        
        if (data.attackerDirection == FlxObject.DOWN)
            velocity.y = 0;
        else if (data.attackerDirection == FlxObject.UP)
            velocity.y = JUMP_SPEED;
    }
    
    public function respawn():Void
    {
        moves = false;
        
        FlxFlicker.flicker
            ( this
            , RESPAWN_TIME
            , 0.04
            , true
            , true
            ,   (_) ->
                {
                    moves = true;
                    reset(spawnPoint.x, spawnPoint.y);
                }
            );
    }
    
    inline function pressed(key:Key):Bool
    {
        return keyStates[key] == PRESSED || justPressed(key);
    }
    
    inline function justPressed(key:Key):Bool
    {
        return keyStates[key] == JUST_PRESSED;
    }
    
    inline function get_onCoyoteGround()
    {
        return coyoteTimer < COYOTE_TIME || isTouching(FlxObject.FLOOR);
    }
    
    inline function get_centerX() { return x + origin.x; }
    inline function get_centerY() { return y + origin.y; }
}

enum Key
{
    UP;
    DOWN;
    LEFT;
    RIGHT;
}

enum Deflection
{
    UP;
    DOWN;
    NONE;
}