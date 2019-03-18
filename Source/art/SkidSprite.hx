package art;

import flixel.math.FlxMath;
import flixel.FlxG;

class SkidSprite extends flixel.FlxSprite {
    
    var skidDrag:Bool = true;
    
    override function updateMotion(elapsed:Float) { 
        
        if(skidDrag)
            updateMotionSkidDrag(elapsed);
        else
            super.updateMotion(elapsed);
    }
    
    inline function updateMotionSkidDrag(elapsed:Float) {
        
        var velocityDelta = 0.5 * (computeVelocity(angularVelocity, angularAcceleration, angularDrag, maxAngular, elapsed) - angularVelocity);
        angularVelocity += velocityDelta; 
        angle += angularVelocity * elapsed;
        angularVelocity += velocityDelta;
        
        velocityDelta = 0.5 * (computeVelocity(velocity.x, acceleration.x, drag.x, maxVelocity.x, elapsed) - velocity.x);
        velocity.x += velocityDelta;
        x += velocity.x * elapsed;
        velocity.x += velocityDelta;
        
        velocityDelta = 0.5 * (computeVelocity(velocity.y, acceleration.y, drag.y, maxVelocity.y, elapsed) - velocity.y);
        velocity.y += velocityDelta;
        y += velocity.y * elapsed;
        velocity.y += velocityDelta;
    }
    
    public static function computeVelocity(velocity:Float, acceleration:Float, drag:Float, max:Float, elapsed:Float):Float
    {
        if (acceleration != 0)
        {
            velocity += acceleration * elapsed;
        }
        
        if (drag != 0 && (acceleration == 0 || !FlxMath.sameSign(velocity, acceleration)))
        {
            var drag:Float = drag * elapsed;
            if (velocity - drag > 0)
            {
                velocity -= drag;
            }
            else if (velocity + drag < 0)
            {
                velocity += drag;
            }
            else
            {
                velocity = 0;
            }
        }
        
        if ((velocity != 0) && (max != 0))
        {
            if (velocity > max)
            {
                velocity = max;
            }
            else if (velocity < -max)
            {
                velocity = -max;
            }
        }
        return velocity;
    }
}