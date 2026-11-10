package mobile;

import flixel.FlxG;
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
