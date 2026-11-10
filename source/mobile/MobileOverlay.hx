package mobile;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup;

class MobileOverlay extends FlxGroup
{
	public var overlayCamera(default, null):FlxCamera;
	public var gestures(default, null):TouchGestures;
	public var backButton(default, null):TouchGroup;

	var layoutWidth:Int = 0;
	var layoutHeight:Int = 0;

	public function new(withGestures:Bool = true, withBack:Bool = true)
	{
		super();

		overlayCamera = new FlxCamera();
		overlayCamera.bgColor.alpha = 0;
		FlxG.cameras.add(overlayCamera, false);

		if (withBack)
		{
			backButton = MobileControls.createBackButton();
			backButton.cameras = [overlayCamera];
			add(backButton);
		}

		if (withGestures)
		{
			gestures = new TouchGestures();
			if (backButton != null)
				for (button in backButton.buttons)
					gestures.ignored.push(button);
			add(gestures);
		}

		layoutWidth = FlxG.width;
		layoutHeight = FlxG.height;
	}

	public function layout():Void
	{
		layoutWidth = FlxG.width;
		layoutHeight = FlxG.height;

		if (overlayCamera != null && (overlayCamera.width != FlxG.width || overlayCamera.height != FlxG.height))
			overlayCamera.setSize(FlxG.width, FlxG.height);

		if (backButton != null)
			for (button in backButton.buttons)
				MobileControls.placeBackButton(button);
	}

	override function update(elapsed:Float)
	{
		if (layoutWidth != FlxG.width || layoutHeight != FlxG.height)
			layout();

		super.update(elapsed);
	}

	public function keepOnTop():Void
	{
		if (overlayCamera == null)
			return;

		var list:Array<FlxCamera> = FlxG.cameras.list;
		if (list.length == 0 || list[list.length - 1] == overlayCamera)
			return;

		if (list.contains(overlayCamera))
			FlxG.cameras.remove(overlayCamera, false);
		FlxG.cameras.add(overlayCamera, false);
	}

	override function draw()
	{
		if (layoutWidth != FlxG.width || layoutHeight != FlxG.height)
			layout();

		keepOnTop();
		super.draw();
	}

	override function destroy()
	{
		if (overlayCamera != null && FlxG.cameras.list.contains(overlayCamera))
			FlxG.cameras.remove(overlayCamera, true);

		overlayCamera = null;
		gestures = null;
		backButton = null;
		super.destroy();
	}
}
