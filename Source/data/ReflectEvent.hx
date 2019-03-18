package data;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.math.FlxVector;

class ReflectEvent
{
    /** The ball's animation */
    public var ballDirection(default, null):Int;
    /** the direction the ball is bounced */
    public var ballVelocity(default, null):FlxVector;
    /** the direction the attacker is bounced */
    public var attackerDirection(default, null):Int;
    public var attacker(default, null):FlxObject;
    public var ballMove(default, null):Null<FlxVector>;
    public var attackerMove(default, null):Null<FlxVector>;
    
    public function new
        ( ballDirection:Int
        , ballVelocity:FlxVector
        , attacker:FlxObject
        , ?ballMove:FlxVector
        , ?attackerMove:FlxVector
        , attackerDirection:Int = FlxObject.NONE
        )
    {
        this.ballDirection     = ballDirection;
        this.ballVelocity      = ballVelocity;
        this.attackerDirection = attackerDirection;
        this.attacker          = attacker;
        this.ballMove          = ballMove;
        this.attackerMove      = attackerMove;
        trace(toString());
    }
    
    public function destroy():Void
    {
        FlxDestroyUtil.destroy(ballVelocity);
        FlxDestroyUtil.destroy(ballMove);
        FlxDestroyUtil.destroy(attackerMove);
    }
    
    public function toString():String
    {
        return '\nball[${dirToString(ballDirection)}]$ballVelocity +$ballMove'
            + '\nattacker[${dirToString(attackerDirection)}]+$attackerMove';
    }
    
    inline static function dirToString(dir:Int):String
    {
        var str = "";
        if (dir & FlxObject.UP    > 0) str += "U";
        if (dir & FlxObject.DOWN  > 0) str += "D";
        if (dir & FlxObject.LEFT  > 0) str += "L";
        if (dir & FlxObject.RIGHT > 0) str += "R";
        
        return str;
    }
        
    static public function vectorFromDiagonal(x:Int, y:Int, speed:Float):FlxVector
    {
        return FlxVector.get(x, y).scale(speed / FlxMath.SQUARE_ROOT_OF_TWO);
    }
}