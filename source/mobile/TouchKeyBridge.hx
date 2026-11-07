package mobile;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
#if android
import flixel.input.android.FlxAndroidKey;
#end

class TouchKeyBridge
{
	public static var frame(default, null):Int = 0;
	public static var backKeys:Array<Int> = [FlxKey.ESCAPE];

	static var sources:Array<TouchKeySource> = [];
	static var held:Array<Int> = [];
	static var ready:Bool = false;

	public static function register(source:TouchKeySource):Void
	{
		init();
		if (!sources.contains(source))
			sources.push(source);
	}

	public static function unregister(source:TouchKeySource):Void
	{
		sources.remove(source);
	}

	public static function init():Void
	{
		if (ready)
			return;

		ready = true;

		#if android
		FlxG.android.preventDefaultKeys = [FlxAndroidKey.BACK];
		#end

		TouchInput.init();
		FlxG.signals.preUpdate.add(onPreUpdate);
		FlxG.signals.preStateSwitch.add(clear);
	}

	public static function isActive(lastUpdateFrame:Int):Bool
	{
		return lastUpdateFrame == frame - 1;
	}

	static function onPreUpdate():Void
	{
		frame++;
		TouchInput.beginFrame();
		sync();
		TouchInput.endFrame();
	}

	static function sync():Void
	{
		var wanted:Array<Int> = [];
		for (source in sources.copy())
			source.collectKeys(wanted);

		#if android
		if (FlxG.android.pressed.BACK)
			for (key in backKeys)
				if (!wanted.contains(key))
					wanted.push(key);
		#end

		for (code in held.copy())
		{
			if (!wanted.contains(code))
			{
				setKey(code, false);
				held.remove(code);
			}
		}

		for (code in wanted)
		{
			if (!held.contains(code))
			{
				setKey(code, true);
				held.push(code);
			}
		}
	}

	static function clear():Void
	{
		held = [];
		backKeys = [FlxKey.ESCAPE];
	}

	static function setKey(code:Int, down:Bool):Void
	{
		if (code < 0)
			return;

		var key = @:privateAccess FlxG.keys._keyListMap.get(code);
		if (key == null)
			return;

		if (down)
			key.press();
		else
			key.release();
	}
}
