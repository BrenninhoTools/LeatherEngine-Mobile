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
	static inline var ARROW_SIZE:Float = 150;
	static inline var ARROW_SPACING:Float = 250;
	static inline var ARROW_MARGIN:Float = 14;
	static inline var ARROW_OUTER:Float = 0.15;
	static inline var ARROW_INNER:Float = 0.45;

	public var lanes(default, null):Array<FlxSprite> = [];
	public var blockers:Array<FlxSprite> = [];
	public var keys(default, null):Array<Int>;
	public var arrowMode(default, null):Bool;
	public var showLanes:Bool;
	public var arrows(default, null):Array<FlxSprite> = [];

	var down:Array<Bool> = [];
	var justDown:Array<Bool> = [];
	var excluded:Array<Int> = [];
	var pointLanes:Map<Int, Int> = new Map();
	var laneWidth:Float;
	var arrowCenters:Array<Float> = [];
	var arrowSpacing:Float = ARROW_SPACING;
	var arrowSize:Float = ARROW_SIZE;
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

		if (arrowMode)
			createArrows(directions);
		else
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

	function createArrows(directions:Array<String>):Void
	{
		var count:Int = keys.length;
		var leftCount:Int = Math.ceil(count / 2);
		var rightCount:Int = count - leftCount;
		var span:Float = FlxG.width * (ARROW_INNER - ARROW_OUTER);
		var most:Int = leftCount > rightCount ? leftCount : rightCount;

		arrowSpacing = most > 1 ? Math.min(ARROW_SPACING, span / (most - 1)) : ARROW_SPACING;
		arrowSize = Math.min(ARROW_SIZE, arrowSpacing * 0.9);

		var insetLeft:Float = ScreenUtil.gameInset(0);
		var insetRight:Float = ScreenUtil.gameInset(2);
		var outerLeft:Float = Math.max(FlxG.width * ARROW_OUTER, insetLeft + arrowSize / 2 + 8);
		var outerRight:Float = Math.min(FlxG.width * (1 - ARROW_OUTER), FlxG.width - insetRight - arrowSize / 2 - 8);

		if (count == 1)
			arrowCenters.push(FlxG.width / 2);
		else
		{
			for (i in 0...leftCount)
				arrowCenters.push(outerLeft + arrowSpacing * i);
			for (i in 0...rightCount)
				arrowCenters.push(outerRight - arrowSpacing * (rightCount - 1 - i));
		}

		var bases:Array<String> = null;
		if (utilities.NoteVariables.Note_Count_Directions != null && count - 1 < utilities.NoteVariables.Note_Count_Directions.length)
			bases = utilities.NoteVariables.Note_Count_Directions[count - 1];

		var atlas = Paths.getSparrowAtlas('ui skins/default/arrows/default', 'shared');
		var bottom:Float = FlxG.height - ARROW_MARGIN - ScreenUtil.gameInset(3);

		for (i in 0...count)
		{
			var base:String = bases != null && i < bases.length ? bases[i].toLowerCase() : "left";
			var press:String = directions != null && i < directions.length ? directions[i] : base;

			var arrow:FlxSprite = new FlxSprite();
			arrow.frames = atlas;
			arrow.animation.addByPrefix('static', base + ' static', 24, false);
			arrow.animation.addByPrefix('pressed', press + ' press', 24, false);
			arrow.antialiasing = true;
			arrow.animation.play('static');
			arrow.setGraphicSize(Std.int(arrowSize));
			arrow.updateHitbox();
			arrow.setPosition(arrowCenters[i] - arrow.width / 2, bottom - arrow.height);
			arrow.visible = showLanes;
			arrows.push(arrow);
			add(arrow);
		}
	}

	function playArrow(index:Int, pressed:Bool):Void
	{
		var arrow:FlxSprite = arrows[index];
		var name:String = pressed ? 'pressed' : 'static';
		if (arrow.animation.curAnim != null && arrow.animation.curAnim.name == name)
			return;
		if (arrow.animation.getByName(name) == null)
			return;

		arrow.animation.play(name, true);
		arrow.centerOffsets();
		arrow.centerOrigin();
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
		var bestDistance:Float = Math.max(arrowSpacing / 2, arrowSize / 2 + 12);
		var top:Float = FlxG.height - ARROW_MARGIN - ScreenUtil.gameInset(3) - arrowSize * 1.8;

		if (y < top)
			return best;

		for (i in 0...arrowCenters.length)
		{
			var distance:Float = Math.abs(x - arrowCenters[i]);
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
			pointLanes.clear();
			return;
		}

		var present:Array<Int> = [];
		var entered:Array<Bool> = [for (i in 0...keys.length) false];
		var currentLanes:Map<Int, Int> = new Map();

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
			if (lane == -1)
				continue;

			down[lane] = true;
			currentLanes.set(point.id, lane);

			var last:Null<Int> = pointLanes.get(point.id);
			if (!point.seen || last == null || last != lane)
				entered[lane] = true;
		}

		pointLanes = currentLanes;

		var i:Int = excluded.length;
		while (i-- > 0)
			if (!present.contains(excluded[i]))
				excluded.splice(i, 1);

		for (lane in 0...keys.length)
		{
			justDown[lane] = down[lane] && (!previous[lane] || entered[lane]);

			if (!down[lane] || keys[lane] < 0)
				continue;

			if (!into.contains(keys[lane]))
				into.push(keys[lane]);

			if (previous[lane] && entered[lane])
				TouchKeyBridge.retrigger(keys[lane]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		lastFrame = TouchKeyBridge.frame;

		for (i in 0...arrows.length)
			playArrow(i, down[i]);

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
		pointLanes.clear();
		arrows = [];
		super.destroy();
	}
}
