package data;

import haxe.Json;

typedef Rect = { x:Int, y:Int, w:Int, h:Int };
typedef RectRaw = { >Rect, ?end:Int };

class HitboxParser
{
    static public function parse(file:String, offsetX:Int, offsetY:Int):Map<String, Array<Null<Rect>>>
    {
        var fileData = openfl.Assets.getText(file);
        if (fileData != null)
            file = fileData;
        
        var map = new Map<String, Array<Null<Rect>>>();
        var data = Json.parse(file);
        for (type in Reflect.fields(data))
        {
            map[type] = [];
            var boxes = Reflect.field(data, type);
            for (frame in Reflect.fields(boxes))
            {
                var rect:RectRaw = cast Reflect.field(boxes, frame);
                var i = Std.parseInt(frame);
                
                if (Std.string(i) != frame)
                    throw 'invalid frame:$frame';
                
                rect.x += offsetX;
                rect.y += offsetY;
                
                while(i > map[type].length)
                    map[type].push(null);
                
                var end = rect.end != null ? rect.end : i;
                do
                {
                    map[type].push(rect);
                }
                while(++i <= end);
            }
        }
        
        return map;
    }
}