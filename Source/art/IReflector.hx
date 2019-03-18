package art;

import data.ReflectEvent;

interface IReflector
{
    function reflect(ball:Ball):Null<ReflectEvent>;
    function resolveReflect(event:ReflectEvent):Void;
    function stun(time:Float):Void;
    var stunTime(default, null):Float;
}    