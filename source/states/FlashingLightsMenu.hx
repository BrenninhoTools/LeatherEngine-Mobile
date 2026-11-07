package states;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import utilities.Options;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class FlashingLightsMenu extends MusicBeatState {
	var text:FlxText;

	override public function create() {
		super.create();

		#if mobile
		text = new FlxText(0, 0, 0, "Hey! Leather Engine has flashing lights\nTap the screen to enable them, or press Back to not.", 32);
		#else
		text = new FlxText(0, 0, 0, "Hey! Leather Engine has flashing lights\nPress Y to enable them, or anything else to not.\n(Any key closes this menu)",
			32);
		#end
		text.font = Paths.font("vcr.ttf");
		text.screenCenter();
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5, 1);
		add(text);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		#if mobile
		var enable:Bool = FlxG.keys.justPressed.ENTER;
		var disable:Bool = FlxG.keys.justPressed.ESCAPE;
		#else
		var enable:Bool = FlxG.keys.justPressed.Y;
		var disable:Bool = !enable && FlxG.keys.justPressed.ANY;
		#end

		if (enable)
			Options.setData(true, "flashingLights");
		else if (disable)
			Options.setData(false, "flashingLights");

		if (enable || disable) {
			FlxG.sound.play(Paths.sound("confirmMenu"));

			FlxTween.tween(text, {alpha: 0}, 2.5, {
				ease: FlxEase.cubeInOut,
				onComplete: (_) -> FlxG.switchState(new TitleState())
			});
		}
	}
}
