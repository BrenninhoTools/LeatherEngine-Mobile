package mobile;

import flixel.FlxG;
import utilities.Options;
#if android
import lime.system.JNI;
#end

#if ios
@:cppFileCode('extern "C" void leather_ios_vibrate(double intensity);')
#end
class HapticsUtil
{
	public static inline var MIN_INTENSITY:Float = 0;
	public static inline var MAX_INTENSITY:Float = 5;
	public static inline var STEP:Float = 0.1;

	public static var enabled(get, never):Bool;
	public static var intensity(get, never):Float;

	static var lastFrame:Int = -1;

	#if android
	static var jniVibrate:Dynamic;
	#end

	static function get_enabled():Bool
	{
		return Options.getData("haptics") == true;
	}

	static function get_intensity():Float
	{
		var value:Null<Float> = Options.getData("hapticsIntensity");
		if (value == null || Math.isNaN(value))
			return 1;

		return Math.max(MIN_INTENSITY, Math.min(MAX_INTENSITY, value));
	}

	public static function vibrate(strength:Float = 1):Void
	{
		if (!enabled)
			return;

		play(intensity * strength);
	}

	public static function play(value:Float):Void
	{
		if (value <= 0 || FlxG.game == null)
			return;

		var frame:Int = FlxG.game.ticks;
		if (frame == lastFrame)
			return;
		lastFrame = frame;

		var amount:Float = Math.min(1, value / MAX_INTENSITY);

		#if android
		try
		{
			if (jniVibrate == null)
				jniVibrate = JNI.createStaticMethod("com/leather128/funkin/mobile/HapticsUtil", "vibrate", "(II)V");

			var duration:Int = Std.int(8 + 35 * amount);
			var amplitude:Int = Std.int(Math.max(1, Math.round(255 * amount)));
			jniVibrate(duration, amplitude);
		}
		catch (e:Dynamic) {}
		#elseif ios
		untyped __cpp__('leather_ios_vibrate({0})', amount);
		#end
	}
}

class HapticsIntensityOption extends ui.Option
{
	var Cool_Name:String;
	var value:Float;
	var holdTime:Float = 0;

	public function new(name:String, row:Int)
	{
		super(name, null, row);

		Cool_Name = name;
		value = HapticsUtil.intensity;
		refresh();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Std.int(Alphabet_Text.targetY) != 0 || states.OptionsMenu.inMenu)
		{
			holdTime = 0;
			return;
		}

		var change:Float = 0;

		if (FlxG.keys.justPressed.LEFT)
			change = -HapticsUtil.STEP;
		else if (FlxG.keys.justPressed.RIGHT)
			change = HapticsUtil.STEP;
		else if (FlxG.keys.justPressed.ENTER)
			change = value >= HapticsUtil.MAX_INTENSITY ? -value : 0.5;

		if (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.RIGHT)
		{
			holdTime += elapsed;
			if (holdTime > 0.4)
			{
				holdTime -= 0.05;
				change = FlxG.keys.pressed.LEFT ? -HapticsUtil.STEP : HapticsUtil.STEP;
			}
		}
		else
			holdTime = 0;

		if (change == 0)
			return;

		var next:Float = Math.round((value + change) * 10) / 10;
		next = Math.max(HapticsUtil.MIN_INTENSITY, Math.min(HapticsUtil.MAX_INTENSITY, next));
		if (next == value)
			return;

		value = next;
		Options.setData(value, "hapticsIntensity");
		refresh();
		HapticsUtil.play(value);
	}

	function refresh():Void
	{
		var text:String = Std.string(value);
		if (text.indexOf(".") == -1)
			text += ".0";

		Option_Name = Cool_Name + " " + text;

		var old:ui.Alphabet = Alphabet_Text;
		var x:Float = old != null ? old.x : 20;
		var y:Float = old != null ? old.y : 20 + (Option_Row * 100);
		var target:Float = old != null ? old.targetY : Option_Row;

		if (old != null)
		{
			remove(old);
			old.kill();
			old.destroy();
		}

		Alphabet_Text = new ui.Alphabet(x, y, Option_Name, true);
		Alphabet_Text.isMenuItem = true;
		Alphabet_Text.targetY = target;
		add(Alphabet_Text);
	}
}
