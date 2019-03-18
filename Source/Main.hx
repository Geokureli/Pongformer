package;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.system.FlxSplash;

import art.CenterText;
import art.SplashState;

class Main extends openfl.display.Sprite
{
    public function new()
    {
        super();
        
        var zoom = 4;
        
        SplashState.nextState = MenuState;
        
        addChild(new flixel.FlxGame
            ( Std.int(stage.stageWidth  / zoom)
            , Std.int(stage.stageHeight / zoom)
            // , SplashState
            , SplashState.nextState
            , 1
            )
        );
    }
}

class MenuState extends flixel.FlxState
{
    var options:Array<CenterText> = [];
    var selected:Int = -1;
    
    override function create()
    {
        super.create();
        
        FlxG.cameras.bgColor = FlxG.stage.color;
        
        add(new CenterText(20, "Pong-Former", 24));
        
        var text;
        add(text = new CenterText(72, "Player Vs COM", 16));
        text.borderColor = 0xFFFFFFFF;
        text.borderSize = 2;
        text.color = 0x808080;
        options.push(text);
        
        add(text = new CenterText(96, "2 Player", 16));
        text.borderColor = 0xFFFFFFFF;
        text.borderSize = 2;
        text.color = 0x808080;
        options.push(text);
        
        selectText(0);
        
        add(new CenterText(FlxG.height - 32, "Intructions: WASD and Arrow keys", 8));
        add(new CenterText(FlxG.height - 16, "A game by George", 8));
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (FlxG.keys.anyJustPressed([FlxKey.S, FlxKey.DOWN, FlxKey.W, FlxKey.UP]))
            selectText(selected + 1);
        
        if (FlxG.keys.anyJustReleased([FlxKey.Z, FlxKey.X, FlxKey.SPACE, FlxKey.ENTER]))
            FlxG.switchState(new GameState(selected == 1));
    }
    
    function selectText(i:Int):Void
    {
        if (selected != -1)
            options[selected].borderStyle = FlxTextBorderStyle.NONE;
        
        selected = i % 2;
        
        options[selected].borderStyle = FlxTextBorderStyle.OUTLINE;
    }
}

class Splash extends FlxSplash
{
    override public function create():Void
    {
        FlxG.cameras.bgColor = FlxG.stage.color;
        
        super.create();
        
        FlxG.cameras.bgColor = FlxG.stage.color;
    }
}