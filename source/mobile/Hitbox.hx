package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import mobile.TouchInput.TouchPoint;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class Hitbox extends FlxSpriteGroup implements TouchKeySource
{
	static inline var BORDER:Int = 4;
	static inline var FADE_TIME:Float = 0.12;
	static inline var ARROW_REACH:Float = 140;

	public var lanes(default, null):Array<FlxSprite> = [];
	public var blockers:Array<FlxSprite> = [];
	public var keys(default, null):Array<Int>;
	public var arrowMode(default, null):Bool;
	public var showLanes:Bool;
	public var targets:Array<FlxSprite>;

	var down:Array<Bool> = [];
	var justDown:Array<Bool> = [];
	var excluded:Array<Int> = [];
	var laneWidth:Float;
	var createdFrame:Int;
	var lastFrame:Int = -1;

	public function new(keys:Array<Int>, ?directions:Array<String>)
	{
		super();
		scrollFactor.set();

		this.keys = keys;
		arrowMode = MobileControls.hitboxMode == MobileControls.ARROWS;
		showLanes = MobileControls.hitboxVisible;
		laneWidth = FlxG.width / Math.max(1, keys.length);

		for (i in 0...keys.length)
		{
			down.push(false);
			justDown.push(false);
		}

		if (!arrowMode)
			createLanes(directions);

		createdFrame = TouchKeyBridge.frame;
		TouchKeyBridge.register(this);
	}

	function createLanes(directions:Array<String>):Void
	{
		var width:Int = Math.ceil(laneWidth);
		for (i in 0...keys.length)
		{
			var color:FlxColor = MobileControls.laneColor(directions != null ? directions[i] : null, i, keys.length);
			var lane:FlxSprite = new FlxSprite(Math.round(laneWidth * i), 0);
			lane.loadGraphic(createLane(width, FlxG.height, color), false, 0, 0, true, 'leather-hitbox-$width-${color.toHexString()}');
			lane.antialiasing = true;
			lane.alpha = 0;
			lanes.push(lane);
			add(lane);
		}
	}

	static function createLane(width:Int, height:Int, color:FlxColor):BitmapData
	{
		var top:FlxColor = color;
		top.alphaFloat = 0;
		var middle:FlxColor = color;
		middle.alphaFloat = 0.12;
		var bottom:FlxColor = color;
		bottom.alphaFloat = 0.5;

		var bitmap:BitmapData = FlxGradient.createGradientBitmapData(width, height, [top, middle, bottom], 1, 90);

		var edge:FlxColor = color;
		edge.alphaFloat = 0.9;
		bitmap.fillRect(new Rectangle(0, 0, BORDER, height), edge);
		bitmap.fillRect(new Rectangle(width - BORDER, 0, BORDER, height), edge);
		bitmap.fillRect(new Rectangle(0, height - BORDER * 2, width, BORDER * 2), edge);
		return bitmap;
	}

	public function isDown(lane:Int):Bool
	{
		return lane >= 0 && lane < down.length && down[lane];
	}

	public function justPressed(lane:Int):Bool
	{
		return lane >= 0 && lane < justDown.length && justDown[lane];
	}

	function laneAt(x:Float, y:Float):Int
	{
		if (arrowMode)
			return arrowAt(x, y);

		var lane:Int = Math.floor(x / laneWidth);
		return lane < 0 ? 0 : (lane >= keys.length ? keys.length - 1 : lane);
	}

	function arrowAt(x:Float, y:Float):Int
	{
		var best:Int = -1;
		var bestDistance:Float = ARROW_REACH;
		if (targets == null)
			return best;

		for (i in 0...targets.length)
		{
			var arrow:FlxSprite = targets[i];
			if (arrow == null || !arrow.exists || i >= keys.length)
				continue;

			var dx:Float = x - (arrow.x + arrow.width / 2);
			var dy:Float = y - (arrow.y + arrow.height / 2);
			var distance:Float = Math.sqrt(dx * dx + dy * dy);
			if (distance <= bestDistance)
			{
				bestDistance = distance;
				best = i;
			}
		}
		return best;
	}

	function startsOnBlocker(point:TouchPoint):Bool
	{
		for (blocker in blockers)
			if (blocker != null && blocker.visible && TouchInput.overlaps(blocker, point.startX, point.startY, 20))
				return true;
		return false;
	}

	public function collectKeys(into:Array<Int>):Void
	{
		var previous:Array<Bool> = down.copy();
		for (i in 0...down.length)
		{
			down[i] = false;
			justDown[i] = false;
		}

		if (!exists || !alive || !active || !TouchKeyBridge.isActive(lastFrame))
		{
			excluded = [];
			return;
		}

		var present:Array<Int> = [];
		for (point in TouchInput.points)
		{
			if (point.startFrame < createdFrame)
				continue;

			present.push(point.id);

			if (!point.seen && startsOnBlocker(point) && !excluded.contains(point.id))
				excluded.push(point.id);

			if (excluded.contains(point.id) || !point.down)
				continue;

			var lane:Int = laneAt(point.x, point.y);
			if (lane != -1)
				down[lane] = true;
		}

		var i:Int = excluded.length;
		while (i-- > 0)
			if (!present.contains(excluded[i]))
				excluded.splice(i, 1);

		for (lane in 0...keys.length)
		{
			justDown[lane] = down[lane] && !previous[lane];
			if (down[lane] && keys[lane] >= 0 && !into.contains(keys[lane]))
				into.push(keys[lane]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		lastFrame = TouchKeyBridge.frame;

		for (i in 0...lanes.length)
		{
			if (down[i] && showLanes)
				lanes[i].alpha = 1;
			else if (lanes[i].alpha > 0)
				lanes[i].alpha = Math.max(0, lanes[i].alpha - elapsed / FADE_TIME);
		}
	}

	override function destroy()
	{
		TouchKeyBridge.unregister(this);
		lanes = [];
		blockers = [];
		targets = null;
		super.destroy();
	}
}
