package mobile;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import haxe.Timer;
import openfl.Lib;
import openfl.events.TouchEvent;
import openfl.geom.Point;

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

	static var ready:Bool = false;
	static var stagePoint:Point = new Point();
	static var bounds:FlxRect = FlxRect.get();

	public static function init():Void
	{
		if (ready)
			return;

		ready = true;
		Lib.current.stage.addEventListener(TouchEvent.TOUCH_BEGIN, onBegin);
		Lib.current.stage.addEventListener(TouchEvent.TOUCH_MOVE, onMove);
		Lib.current.stage.addEventListener(TouchEvent.TOUCH_END, onEnd);
		FlxG.signals.focusLost.add(clear);
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

	static function toGame(event:TouchEvent):Point
	{
		stagePoint.setTo(event.stageX, event.stageY);
		var local:Point = FlxG.game.globalToLocal(stagePoint);
		local.x /= FlxG.scaleMode.scale.x;
		local.y /= FlxG.scaleMode.scale.y;
		return local;
	}

	static function onBegin(event:TouchEvent):Void
	{
		var position:Point = toGame(event);
		var point:TouchPoint = find(event.touchPointID);
		if (point != null)
			point.ended = true;
		points.push(new TouchPoint(event.touchPointID, position.x, position.y, TouchKeyBridge.frame));
	}

	static function onMove(event:TouchEvent):Void
	{
		var point:TouchPoint = find(event.touchPointID);
		if (point == null)
			return;

		var position:Point = toGame(event);
		point.x = position.x;
		point.y = position.y;
	}

	static function onEnd(event:TouchEvent):Void
	{
		var point:TouchPoint = find(event.touchPointID);
		if (point == null)
			return;

		var position:Point = toGame(event);
		point.x = position.x;
		point.y = position.y;
		point.ended = true;
	}
}
