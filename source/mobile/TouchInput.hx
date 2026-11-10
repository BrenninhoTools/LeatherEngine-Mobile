package mobile;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import haxe.Timer;
import lime.ui.Touch;
import openfl.Lib;

class TouchPoint
{
	public var id(default, null):Int;
	public var startX(default, null):Float;
	public var startY(default, null):Float;
	public var startTime(default, null):Float;
	public var startFrame(default, null):Int;
	public var x:Float;
	public var y:Float;
	public var ended:Bool = false;
	public var seen:Bool = false;
	public var finished:Bool = false;

	public var down(get, never):Bool;
	public var duration(get, never):Float;

	public function new(id:Int, x:Float, y:Float, frame:Int)
	{
		this.id = id;
		this.x = startX = x;
		this.y = startY = y;
		startTime = Timer.stamp();
		startFrame = frame;
	}

	inline function get_down():Bool
	{
		return !ended || !seen;
	}

	inline function get_duration():Float
	{
		return Timer.stamp() - startTime;
	}
}

class TouchInput
{
	public static var points(default, null):Array<TouchPoint> = [];

	static inline var MAX_POINTS:Int = 20;

	static var ready:Bool = false;
	static var bounds:FlxRect = FlxRect.get();
	static var gameX:Float = 0;
	static var gameY:Float = 0;

	public static function init():Void
	{
		if (ready)
			return;

		ready = true;
		openfl.ui.Multitouch.inputMode = openfl.ui.MultitouchInputMode.TOUCH_POINT;
		Touch.onStart.add(onBegin);
		Touch.onMove.add(onMove);
		Touch.onEnd.add(onEnd);
		Touch.onCancel.add(onEnd);
		FlxG.signals.focusLost.add(clear);
		FlxG.signals.focusGained.add(clear);
	}

	public static function beginFrame():Void
	{
		var i:Int = points.length;
		while (i-- > 0)
			if (points[i].finished)
				points.splice(i, 1);
	}

	public static function endFrame():Void
	{
		for (point in points)
		{
			if (point.ended)
				point.finished = true;
			point.seen = true;
		}
	}

	public static function clear():Void
	{
		points = [];
	}

	public static function overlaps(sprite:FlxSprite, x:Float, y:Float, padding:Float = 0):Bool
	{
		if (sprite == null || !sprite.exists)
			return false;

		var camera:FlxCamera = sprite.camera;
		if (camera == null)
			camera = FlxG.camera;

		if (Std.isOfType(sprite, FlxSpriteGroup) || sprite.frame == null)
			bounds.set(sprite.x - camera.scroll.x * sprite.scrollFactor.x, sprite.y - camera.scroll.y * sprite.scrollFactor.y, sprite.width, sprite.height);
		else
			sprite.getScreenBounds(bounds, camera);

		return x >= bounds.x - padding && x <= bounds.right + padding && y >= bounds.y - padding && y <= bounds.bottom + padding;
	}

	static function find(id:Int):TouchPoint
	{
		for (point in points)
			if (point.id == id && !point.ended)
				return point;
		return null;
	}

	static function convert(touch:Touch):Bool
	{
		var window = Lib.application != null ? Lib.application.window : null;
		if (window == null || FlxG.game == null || FlxG.scaleMode == null)
			return false;

		var stageX:Float = touch.x * window.width * window.scale;
		var stageY:Float = touch.y * window.height * window.scale;
		var scaleX:Float = FlxG.scaleMode.scale.x;
		var scaleY:Float = FlxG.scaleMode.scale.y;

		if (scaleX <= 0 || scaleY <= 0)
			return false;

		gameX = (stageX - FlxG.game.x) / scaleX;
		gameY = (stageY - FlxG.game.y) / scaleY;
		return true;
	}

	static function onBegin(touch:Touch):Void
	{
		if (!convert(touch))
			return;

		var point:TouchPoint = find(touch.id);
		if (point != null)
			point.ended = true;

		if (points.length >= MAX_POINTS)
			points.shift();

		points.push(new TouchPoint(touch.id, gameX, gameY, TouchKeyBridge.frame));
	}

	static function onMove(touch:Touch):Void
	{
		var point:TouchPoint = find(touch.id);
		if (point == null || !convert(touch))
			return;

		point.x = gameX;
		point.y = gameY;
	}

	static function onEnd(touch:Touch):Void
	{
		var point:TouchPoint = find(touch.id);
		if (point == null)
			return;

		if (convert(touch))
		{
			point.x = gameX;
			point.y = gameY;
		}

		point.ended = true;
	}
}
