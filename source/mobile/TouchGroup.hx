package mobile;

import flixel.group.FlxSpriteGroup;

class TouchGroup extends FlxSpriteGroup implements TouchKeySource
{
	public var buttons(default, null):Array<TouchButton> = [];

	var createdFrame:Int;
	var lastFrame:Int = -1;

	public function new()
	{
		super();
		scrollFactor.set();
		createdFrame = TouchKeyBridge.frame;
		TouchKeyBridge.register(this);
	}

	public function addButton(button:TouchButton):TouchButton
	{
		buttons.push(button);
		add(button);
		return button;
	}

	public function collectKeys(into:Array<Int>):Void
	{
		var usable:Bool = exists && alive && visible && active && TouchKeyBridge.isActive(lastFrame);

		for (button in buttons)
		{
			button.poll(createdFrame, usable);
			button.collectKeys(into);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		lastFrame = TouchKeyBridge.frame;
	}

	override function destroy()
	{
		TouchKeyBridge.unregister(this);
		buttons = [];
		super.destroy();
	}
}
