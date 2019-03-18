package art;

import flixel.FlxG;
import flixel.FlxObject;

class Level extends flixel.tile.FlxTilemap
{
    public function new ()
    {
        super();
        
        loadMapFromCSV(replaceHex("assets/data/level.csv"), "assets/art/tiles.png", 8, 8, null, 0, 1, 2);
        setTileProperties(2, FlxObject.UP);
    }
    
    inline function replaceHex(mapName:String):String
    {
        var map = openfl.Assets.getText(mapName);
        if (map == null)
            map = mapName;
        
        map = replaceTiles(map, "a" , "10");
        map = replaceTiles(map, "b" , "11");
        map = replaceTiles(map, "c" , "12");
        map = replaceTiles(map, "d" , "13");
        map = replaceTiles(map, "e" , "14");
        map = replaceTiles(map, "f" , "15");
        return map;
    }
    
    inline function replaceTiles(map:String, old:String, replacer:String):String
    {
        return map.split(old).join(replacer);
    }
    
    public function initWorld():Void
    {
        FlxG.worldBounds.set(x, y, width, height);
        FlxG.camera.minScrollX = x;
        FlxG.camera.minScrollY = y;
        FlxG.camera.maxScrollX = x + width;
        FlxG.camera.maxScrollY = y + height;
        trace('min:(${FlxG.camera.minScrollX}, ${FlxG.camera.minScrollY}) max:(${FlxG.camera.maxScrollX}, ${FlxG.camera.maxScrollY})');
    }
}