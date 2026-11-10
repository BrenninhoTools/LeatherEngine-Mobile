package mobile;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.scaleModes.RatioScaleMode;
import utilities.Options;
#if android
import lime.system.JNI;
#end

#if ios
@:build(mobile.NativeBuild.addFiles('project/ios', 'mm', 'leather_ios'))
@:cppFileCode('extern "C" void leather_ios_set_full_screen(bool full);\nextern "C" double leather_ios_safe_inset(int side);')
#end
class ScreenUtil
{
	public static inline var ORIGINAL:String = "Original";
	public static inline var FULL:String = "Full";

	public static final STYLES:Array<String> = [ORIGINAL, FULL];

	public static var style(get, never):String;
	public static var isFull(get, never):Bool;

	static var listening:Bool = false;
	static var lastWidth:Int = 0;
	static var covered:Array<FlxSprite> = [];

	public static var contentOffset(get, never):Float;

	static function get_contentOffset():Float
	{
		return Math.max(0, (FlxG.width - FlxG.initialWidth) / 2);
	}

	#if android
	static var jniSetFullScreen:Dynamic;
	static var jniGetSafeInsets:Dynamic;
	#end

	static function get_style():String
	{
		return Options.getData("screenStyle") == FULL ? FULL : ORIGINAL;
	}

	static function get_isFull():Bool
	{
		return style == FULL;
	}

	public static function apply():Void
	{
		if (FlxG.game == null)
			return;

		if (!listening)
		{
			listening = true;
			FlxG.signals.gameResized.add((_, _) -> resizeCameras());
			FlxG.signals.postStateSwitch.add(onStateSwitch);
			FlxG.signals.preStateSwitch.add(() -> covered = []);
			FlxG.signals.postUpdate.add(keepCovered);
		}

		var full:Bool = isFull;
		setNativeFullScreen(full);

		if (full && Std.isOfType(FlxG.scaleMode, WideScaleMode))
			return;
		if (!full && !Std.isOfType(FlxG.scaleMode, WideScaleMode) && Std.isOfType(FlxG.scaleMode, RatioScaleMode))
			return;

		lastWidth = FlxG.width;
		FlxG.scaleMode = full ? new WideScaleMode() : new RatioScaleMode();

		if (!full)
		{
			@:privateAccess
			{
				FlxG.width = FlxG.initialWidth;
				FlxG.height = FlxG.initialHeight;
			}
			FlxG.scaleMode.onMeasure(FlxG.stage.stageWidth, FlxG.stage.stageHeight);
		}

		resizeCameras();
		onStateSwitch();
	}

	static function onStateSwitch():Void
	{
		if (FlxG.state == null || Std.isOfType(FlxG.state, states.PlayState))
			return;

		fitBackgrounds(cast FlxG.state);
	}

	public static function fitBackgrounds(group:FlxTypedGroup<FlxBasic>):Void
	{
		if (!isFull || FlxG.width <= FlxG.initialWidth || group == null)
			return;

		for (member in group.members)
		{
			if (member == null || !Std.isOfType(member, FlxSprite))
				continue;

			var sprite:FlxSprite = cast member;
			if (!isBackground(sprite))
				continue;

			cover(sprite);
			if (!covered.contains(sprite))
				covered.push(sprite);
		}
	}

	public static function cover(sprite:FlxSprite):Void
	{
		if (sprite == null || sprite.width <= 0 || sprite.height <= 0)
			return;

		var factor:Float = Math.max(FlxG.width / sprite.width, FlxG.height / sprite.height);
		if (factor > 1)
		{
			sprite.scale.set(sprite.scale.x * factor, sprite.scale.y * factor);
			sprite.updateHitbox();
			sprite.screenCenter();
			return;
		}

		if (sprite.x > 0 || sprite.x + sprite.width < FlxG.width)
			sprite.screenCenter(X);
	}

	static function keepCovered():Void
	{
		if (covered.length == 0)
			return;

		if (!isFull || FlxG.width <= FlxG.initialWidth)
		{
			covered = [];
			return;
		}

		var index:Int = covered.length;
		while (index-- > 0)
		{
			var sprite:FlxSprite = covered[index];
			if (sprite == null || !sprite.exists || sprite.graphic == null)
			{
				covered.splice(index, 1);
				continue;
			}

			if (sprite.width < FlxG.width - 1 || sprite.x > 0.5 || sprite.x + sprite.width < FlxG.width - 0.5)
				cover(sprite);
		}
	}

	static function isBackground(sprite:FlxSprite):Bool
	{
		if (sprite.graphic == null)
			return false;

		var initialWidth:Int = FlxG.initialWidth;
		var initialHeight:Int = FlxG.initialHeight;

		if (sprite.width < initialWidth * 0.95 || sprite.width >= FlxG.width)
			return false;
		if (sprite.height < initialHeight * 0.9)
			return false;

		var tolerance:Float = initialWidth * 0.05;
		var leftAligned:Bool = sprite.x <= tolerance && sprite.x + sprite.width >= initialWidth - tolerance;
		var centered:Bool = Math.abs(sprite.x + sprite.width / 2 - FlxG.width / 2) <= tolerance;

		return leftAligned || centered;
	}

	static function resizeCameras():Void
	{
		if (lastWidth == 0)
			lastWidth = FlxG.initialWidth;

		if (lastWidth != FlxG.width)
		{
			for (camera in FlxG.cameras.list)
				if (camera != null && camera.width == lastWidth)
					camera.setSize(FlxG.width, FlxG.height);
		}

		lastWidth = FlxG.width;
	}

	public static function safeInsets():Array<Float>
	{
		var result:Array<Float> = [0, 0, 0, 0];
		if (!isFull)
			return result;

		#if android
		try
		{
			if (jniGetSafeInsets == null)
				jniGetSafeInsets = JNI.createStaticMethod("com/leather128/funkin/mobile/ScreenUtil", "getSafeInsets", "()Ljava/lang/String;");

			var raw:String = jniGetSafeInsets();
			if (raw != null)
			{
				var parts:Array<String> = raw.split(",");
				for (i in 0...Std.int(Math.min(4, parts.length)))
				{
					var value:Float = Std.parseFloat(parts[i]);
					result[i] = Math.isNaN(value) ? 0 : value;
				}
			}
		}
		catch (e:Dynamic) {}
		#elseif ios
		for (i in 0...4)
		{
			var value:Float = untyped __cpp__('leather_ios_safe_inset({0})', i);
			result[i] = value;
		}
		#end

		return result;
	}

	public static function gameInset(side:Int):Float
	{
		var pixels:Float = safeInsets()[side];
		if (pixels <= 0 || FlxG.scaleMode == null)
			return 0;

		var scale:Float = side == 0 || side == 2 ? FlxG.scaleMode.scale.x : FlxG.scaleMode.scale.y;
		return scale > 0 ? pixels / scale : 0;
	}

	static function setNativeFullScreen(full:Bool):Void
	{
		#if android
		try
		{
			if (jniSetFullScreen == null)
				jniSetFullScreen = JNI.createStaticMethod("com/leather128/funkin/mobile/ScreenUtil", "setFullScreen", "(Z)V");

			jniSetFullScreen(full);
		}
		catch (e:Dynamic) {}
		#elseif ios
		untyped __cpp__('leather_ios_set_full_screen({0})', full);
		#end
	}
}

class ScreenStyleOption extends ui.Option.StringSaveOption
{
	public function new(name:String, row:Int)
	{
		super(name, ScreenUtil.STYLES, row, "screenStyle");
	}

	override function SetDataIGuess()
	{
		super.SetDataIGuess();
		ScreenUtil.apply();
		Main.updateDisplayLayout();
	}
}
