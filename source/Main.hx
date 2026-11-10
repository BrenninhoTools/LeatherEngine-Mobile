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

		#if mobile
		displayBackground = new openfl.display.Shape();
		addChild(displayBackground);
		#end

		display = new SimpleInfoDisplay(8, 3, 0xFFFFFF, "_sans");
		addChild(display);

		#if mobile
		display.autoSize = openfl.text.TextFieldAutoSize.LEFT;
		display.wordWrap = false;
		display.multiline = true;

		mobile.ScreenUtil.apply();
		flixel.FlxG.signals.gameResized.add((_, _) -> updateDisplayLayout());
		flixel.FlxG.signals.postDraw.add(drawDisplayBackground);
		updateDisplayLayout();
		#end
	}

	public static var display:SimpleInfoDisplay;

	#if mobile
	public static var displayBackground:openfl.display.Shape;

	static inline var DISPLAY_MARGIN:Float = 10;
	static inline var DISPLAY_PADDING:Float = 6;

	static var displayScale:Float = 1;
	#end

	public static function updateDisplayLayout():Void {
		#if mobile
		if (display == null || flixel.FlxG.game == null || flixel.FlxG.scaleMode == null)
			return;

		var scale:flixel.math.FlxPoint = flixel.FlxG.scaleMode.scale;
		displayScale = Math.max(1, Math.min(scale.x, scale.y) * 1.25);

		var insets:Array<Float> = mobile.ScreenUtil.safeInsets();
		var left:Float = flixel.FlxG.game.x + DISPLAY_MARGIN * scale.x;
		var top:Float = flixel.FlxG.game.y + DISPLAY_MARGIN * scale.y;

		display.scaleX = display.scaleY = displayScale;
		display.x = Math.max(left, insets[0] + DISPLAY_MARGIN * scale.x) + DISPLAY_PADDING * displayScale;
		display.y = Math.max(top, insets[1] + DISPLAY_MARGIN * scale.y) + DISPLAY_PADDING * displayScale;
		#end
	}

	#if mobile
	static function drawDisplayBackground():Void {
		if (display == null || displayBackground == null)
			return;

		displayBackground.graphics.clear();

		if (!display.visible || display.text == null || StringTools.trim(display.text).length == 0)
			return;

		var padding:Float = DISPLAY_PADDING * displayScale;
		var width:Float = display.textWidth * displayScale + padding * 2 + 4 * displayScale;
		var height:Float = display.textHeight * displayScale + padding * 2;

		var maxWidth:Float = openfl.Lib.current.stage.stageWidth - (display.x - padding) - padding;
		if (width > maxWidth)
			width = maxWidth;

		displayBackground.graphics.beginFill(0x000000, 0.55);
		displayBackground.graphics.drawRoundRect(display.x - padding, display.y - padding, width, height, 10 * displayScale, 10 * displayScale);
		displayBackground.graphics.endFill();
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
