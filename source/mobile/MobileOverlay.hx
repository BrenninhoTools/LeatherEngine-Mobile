package mobile;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup;

class MobileOverlay extends FlxGroup
{
	public var overlayCamera(default, null):FlxCamera;
	public var gestures(default, null):TouchGestures;
	public var backButton(default, null):TouchGroup;

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
