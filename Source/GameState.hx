package ;

import art.*;
import Main.MenuState;

import flixel.text.FlxText;
import flixel.effects.FlxFlicker;
import flixel.FlxG;
import flixel.util.FlxTimer;

class GameState extends flixel.FlxState
{
    static inline var DEATH_Y = 1000;
    static inline var END_POINTS = 10;
    
    var isPvp:Bool;
    var level:Level;
    var player1:Hero;
    var player2:Hero;
    var ball:Ball;
    var pointsText1:FlxText;
    var pointsText2:FlxText;
    
    public function new (isPvp:Bool = false)
    {
        this.isPvp = isPvp;
        
        super();
    }
    
    override public function create():Void
    {
        FlxG.cameras.bgColor = 0xff76428a;
        
        FlxG.debugger.drawDebug = true;
        // FlxG.mouse.useSystemCursor = true;
        
        // add(level = new Level(true, false, true));
        add(level = new Level());
        level.initWorld();
        
        // Create player
        add(ball = new Ball());
        add(player1 = new Hero(ball, true, isPvp));
        if (isPvp)
            add(player2 = new Hero(ball, false));
        else
            add(player2 = new Enemy
                ( ball
                // , cast add(new flixel.FlxSprite())
                )
            );
        
        add(pointsText1 = new FlxText(16, 16, 100, "0", 16));
        add(pointsText2 = new FlxText(FlxG.width - 16, 16, 100, "0", 16));
        pointsText2.x -= pointsText2.width;
        pointsText2.alignment = flixel.text.FlxText.FlxTextAlign.RIGHT;
    }
    
    override public function update(elapsed:Float):Void
    {
        FlxG.collide(level, player1);
        FlxG.collide(level, player2);
        
        super.update(elapsed);
        
        if (ball.moves)
        {
            if (ball.velocity.x < 0)
            {
                if (ball.x < Ball.EDGE)
                {
                    var points = Std.parseInt(pointsText2.text) + 1;
                    pointsText2.text = '$points';
                    FlxFlicker.flicker(pointsText2, 1.0, 0.125);
                    
                    if (points == END_POINTS)
                    {
                        pointsText2.text = 'Winner!';
                        onVictory();
                        
                    }
                    else
                        ball.respawn(false, true);
                }
            }
            else
            {
                if (ball.x + ball.width > FlxG.width - Ball.EDGE)
                {
                    var points = Std.parseInt(pointsText1.text) + 1;
                    pointsText1.text = '$points';
                    FlxFlicker.flicker(pointsText1, 1.0, 0.125);
                    
                    if (points == END_POINTS)
                    {
                        pointsText1.text = 'Winner!';
                        onVictory();
                    }
                    else
                        ball.respawn(false, false);
                }
            }
            
            if (ball.overlaps(player1.ballHitbox))
                ball.onHit(player1);
            
            if (ball.overlaps(player2.ballHitbox))
                ball.onHit(player2);
        }
    }
    
    function onVictory():Void
    {
        ball.moves = false;
        alive = false;
        new FlxTimer().start(2, (_)->{ FlxG.switchState(new MenuState()); });
    }
}