package mobile;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Timer;
import mobile.TouchInput.TouchPoint;

class TouchButton extends FlxSprite
{
	public var keys:Array<Int>;
	public var idleAlpha:Float = 0.65;
	public var pressedAlpha:Float = 1;
	public var padding:Float = 18;
	public var cooldown:Float = 0.3;
	public var pressed(default, null):Bool = false;

	var handled:Array<Int> = [];
	var readyTime:Float = 0;
	var flashTime:Float = 0;

	public function new(x:Float, y:Float, keys:Array<Int>)
	{
		super(x, y);
		this.keys = keys;
		solid = false;
		immovable = true;
		moves = false;
		antialiasing = true;
		scrollFactor.set();
	}

	public function loadAnimated(atlas:FlxAtlasFrames, prefix:String, targetHeight:Int):TouchButton
	{
		frames = atlas;
		animation.addByIndices("normal", prefix, [0], "", 24, false);
		animation.addByPrefix("pressed", prefix, 24, false);
		animation.play("normal");
		setGraphicSize(0, targetHeight);
		updateHitbox();
		alpha = idleAlpha;
		return this;
	}

	public function startsInside(point:TouchPoint):Bool
	{
		return TouchInput.overlaps(this, point.startX, point.startY, padding);
	}

	public function poll(createdFrame:Int, usable:Bool):Void
	{
		var trigger:Bool = false;
		var present:Array<Int> = [];

		for (point in TouchInput.points)
		{
			present.push(point.id);

			if (!usable || point.startFrame < createdFrame || handled.contains(point.id) || !startsInside(point))
				continue;

			handled.push(point.id);
			if (Timer.stamp() >= readyTime)
				trigger = true;
		}

		var i:Int = handled.length;
		while (i-- > 0)
			if (!present.contains(handled[i]))
				handled.splice(i, 1);

		if (trigger)
		{
			readyTime = Timer.stamp() + cooldown;
			flashTime = 0.18;
			if (animation.getByName("pressed") != null)
				animation.play("pressed", true);
		}

		pressed = trigger;
	}

	public function collectKeys(into:Array<Int>):Void
	{
		if (!exists || !alive || !visible || !pressed)
			return;

		for (key in keys)
			if (key >= 0 && !into.contains(key))
				into.push(key);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (flashTime > 0)
			flashTime -= elapsed;

		alpha = flashTime > 0 ? pressedAlpha : idleAlpha;
		if (flashTime <= 0 && animation.curAnim != null && animation.curAnim.name == "pressed" && animation.curAnim.finished)
			animation.play("normal");
	}
}
