package;

import utilities.CoolUtil;
import openfl.text.TextFormat;
import ui.SimpleInfoDisplay;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {
	public function new() {
		super();

		CoolUtil.haxe_trace = haxe.Log.trace;
		haxe.Log.trace = CoolUtil.haxe_print;

		#if mobile
		mobile.StorageUtil.init();
		mobile.CrashHandler.init();
		#end

		addChild(new FlxGame(1280, 720, #if mobile mobile.CopyState #else states.TitleState #end, 60, 60, true));

		display = new SimpleInfoDisplay(8, 3, 0xFFFFFF, "_sans");
		addChild(display);

		#if mobile
		flixel.FlxG.signals.gameResized.add(onResize);
		onResize(openfl.Lib.current.stage.stageWidth, openfl.Lib.current.stage.stageHeight);
		#end
	}

	public static var display:SimpleInfoDisplay;

	#if mobile
	function onResize(width:Int, height:Int):Void {
		if (display != null)
			display.scaleX = display.scaleY = Math.max(1, Math.min(width / 1280, height / 720));
	}
	#end

	public static function toggleFPS(fpsEnabled:Bool):Void
		display.infoDisplayed[0] = fpsEnabled;

	public static function toggleMem(memEnabled:Bool):Void
		display.infoDisplayed[1] = memEnabled;

	public static function toggleVers(versEnabled:Bool):Void
		display.infoDisplayed[2] = versEnabled;

	public static function changeFont(font:String):Void
		display.defaultTextFormat = new TextFormat(font, (font == "_sans" ? 12 : 14), display.textColor);
}
