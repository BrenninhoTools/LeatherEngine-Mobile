package mobile;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import mobile.TouchInput.TouchPoint;

class TouchGestures extends FlxBasic implements TouchKeySource
{
	public var stepX:Float = 110;
	public var stepY:Float = 80;
	public var lockDistance:Float = 24;
	public var tapSlop:Float = 32;
	public var tapTime:Float = 0.45;
	public var maxQueue:Int = 3;
	public var tapKeys:Array<Int> = [FlxKey.ENTER];
	public var horizontal:Bool = true;
	public var vertical:Bool = true;
	public var ignored:Array<FlxSprite> = [];
	public var onTap:Float->Float->Bool;

	var createdFrame:Int;
	var lastFrame:Int = -1;
	var tracked:TouchPoint;
	var anchorX:Float = 0;
	var anchorY:Float = 0;
	var axis:Int = 0;
	var moved:Bool = false;
	var queue:Array<Int> = [];
	var pulse:Int = -1;

	public function new()
	{
		super();
		createdFrame = TouchKeyBridge.frame;
		TouchKeyBridge.register(this);
	}

	public function collectKeys(into:Array<Int>):Void
	{
		if (!exists || !alive || !active || !TouchKeyBridge.isActive(lastFrame))
		{
			reset();
			return;
		}

		track();

		if (pulse != -1)
			pulse = -1;
		else if (queue.length > 0)
			pulse = queue.shift();

		if (pulse != -1 && !into.contains(pulse))
			into.push(pulse);
	}

	function track():Void
	{
		if (tracked != null && !TouchInput.points.contains(tracked))
			tracked = null;

		if (tracked == null)
		{
			for (point in TouchInput.points)
			{
				if (point.seen || point.startFrame < createdFrame || isIgnored(point))
					continue;

				tracked = point;
				anchorX = point.startX;
				anchorY = point.startY;
				axis = 0;
				moved = false;
				break;
			}
		}

		if (tracked == null)
			return;

		if (!moved && (Math.abs(tracked.x - tracked.startX) > tapSlop || Math.abs(tracked.y - tracked.startY) > tapSlop))
			moved = true;

		if (axis == 0)
		{
			var dx:Float = Math.abs(tracked.x - anchorX);
			var dy:Float = Math.abs(tracked.y - anchorY);
			if (dx >= lockDistance || dy >= lockDistance)
				axis = dx >= dy ? 1 : 2;
		}

		if (axis == 1 && horizontal)
		{
			while (Math.abs(tracked.x - anchorX) >= stepX)
			{
				var direction:Float = tracked.x > anchorX ? 1 : -1;
				enqueue(direction > 0 ? FlxKey.RIGHT : FlxKey.LEFT);
				anchorX += stepX * direction;
			}
		}
		else if (axis == 2 && vertical)
		{
			while (Math.abs(tracked.y - anchorY) >= stepY)
			{
				var direction:Float = tracked.y > anchorY ? 1 : -1;
				enqueue(direction > 0 ? FlxKey.DOWN : FlxKey.UP);
				anchorY += stepY * direction;
			}
		}

		if (tracked.ended)
		{
			if (!moved && tracked.duration <= tapTime)
				tap(tracked.x, tracked.y);
			tracked = null;
		}
	}

	function tap(x:Float, y:Float):Void
	{
		if (onTap != null && onTap(x, y))
			return;

		for (key in tapKeys)
			enqueue(key);
	}

	function enqueue(key:Int):Void
	{
		if (queue.length < maxQueue)
			queue.push(key);
	}

	function isIgnored(point:TouchPoint):Bool
	{
		for (sprite in ignored)
			if (sprite != null && sprite.visible && TouchInput.overlaps(sprite, point.startX, point.startY, 18))
				return true;
		return false;
	}

	function reset():Void
	{
		tracked = null;
		queue = [];
		pulse = -1;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		lastFrame = TouchKeyBridge.frame;
	}

	override function destroy()
	{
		TouchKeyBridge.unregister(this);
		ignored = [];
		onTap = null;
		reset();
		super.destroy();
	}
}
