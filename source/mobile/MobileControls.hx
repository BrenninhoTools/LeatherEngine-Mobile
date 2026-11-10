package mobile;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;
import utilities.Options;

class MobileControls
{
	public static inline var LANES:String = "lanes";
	public static inline var ARROWS:String = "arrows";

	public static final MODES:Array<String> = [LANES, ARROWS];

	public static var hitboxMode(get, never):String;
	public static var hitboxVisible(get, never):Bool;
	public static var pauseButtonVisible(get, never):Bool;

	static function get_hitboxMode():String
	{
		return Options.getData("hitboxMode") == ARROWS ? ARROWS : LANES;
	}

	static function get_hitboxVisible():Bool
	{
		return Options.getData("invisibleHitbox") != true;
	}

	static function get_pauseButtonVisible():Bool
	{
		return Options.getData("invisiblePauseButton") != true;
	}

	public static function laneColor(direction:String, index:Int, count:Int):FlxColor
	{
		var name:String = direction == null ? "" : direction.toLowerCase();
		while (name.length > 0 && name.charCodeAt(name.length - 1) >= "0".code && name.charCodeAt(name.length - 1) <= "9".code)
			name = name.substr(0, name.length - 1);
		if (StringTools.startsWith(name, "r") && name != "right")
			name = name.substr(1);

		return switch (name)
		{
			case "left": 0xFFC24B99;
			case "down": 0xFF00FFFF;
			case "up": 0xFF12FA05;
			case "right": 0xFFF9393F;
			case "square": 0xFFCCCCCC;
			case "plus": 0xFFFFD94A;
			default: FlxColor.fromHSB((index / Math.max(1, count)) * 360, 0.7, 1);
		}
	}

	public static function keyFromString(name:String):Int
	{
		var key:Int = FlxKey.fromString(name);
		return key == FlxKey.NONE ? -1 : key;
	}

	public static function createHitbox(binds:Array<String>, ?directions:Array<String>):Hitbox
	{
		return new Hitbox([for (bind in binds) keyFromString(bind)], directions);
	}

	public static function createLaneHitbox(count:Int, ?directions:Array<String>):Hitbox
	{
		return new Hitbox([for (i in 0...count) -1], directions);
	}

	public static function createPauseButton(pauseKey:Int):TouchGroup
	{
		var group:TouchGroup = new TouchGroup();
		var button:TouchButton = new TouchButton(0, 0, [pauseKey]);
		button.loadAnimated(Paths.getSparrowAtlas('mobile/pauseButton', 'shared'), 'pause', 90);
		button.setPosition(FlxG.width - button.width - 18 - ScreenUtil.gameInset(2), 18 + ScreenUtil.gameInset(1));
		if (!pauseButtonVisible)
		{
			button.idleAlpha = 0;
			button.pressedAlpha = 0;
			button.alpha = 0;
		}
		group.addButton(button);
		return group;
	}

	public static function placeBackButton(button:TouchButton):Void
	{
		button.setPosition(FlxG.width - button.width - 18 - ScreenUtil.gameInset(2), FlxG.height - button.height - 18 - ScreenUtil.gameInset(3));
	}

	public static function createBackButton():TouchGroup
	{
		var group:TouchGroup = new TouchGroup();
		var button:TouchButton = new TouchButton(0, 0, [FlxKey.ESCAPE, FlxKey.BACKSPACE]);
		button.loadAnimated(Paths.getSparrowAtlas('mobile/backButton', 'shared'), 'back', 180);
		placeBackButton(button);
		group.addButton(button);
		return group;
	}
}
