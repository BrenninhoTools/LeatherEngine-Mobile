package mobile;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import haxe.Timer;
import haxe.io.Path;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class CopyState extends FlxState
{
	static final PREFIXES:Array<String> = ["mods/", "assets/replays/"];
	static inline var FRAME_BUDGET:Float = 0.012;

	var queue:Array<String> = [];
	var total:Int = 0;
	var copied:Int = 0;
	var failed:Array<String> = [];
	var progress:Float = 0;
	var label:FlxText;
	var bar:FlxBar;
	var finished:Bool = false;

	override function create()
	{
		super.create();

		queue = findMissing();
		total = queue.length;

		if (total == 0)
		{
			leave();
			return;
		}

		label = new FlxText(0, FlxG.height / 2 - 60, FlxG.width, "", 28);
		label.setFormat(null, 28, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(label);

		bar = new FlxBar(FlxG.width * 0.15, FlxG.height / 2, LEFT_TO_RIGHT, Std.int(FlxG.width * 0.7), 18, this, "progress", 0, 1);
		bar.createFilledBar(0xFF333333, 0xFFFFFFFF, true, FlxColor.BLACK);
		add(bar);

		updateLabel();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (finished || total == 0)
			return;

		var start:Float = Timer.stamp();
		while (queue.length > 0 && Timer.stamp() - start < FRAME_BUDGET)
			copy(queue.shift());

		progress = copied / total;
		updateLabel();

		if (queue.length == 0)
			leave();
	}

	function updateLabel():Void
	{
		if (label != null)
			label.text = 'Preparing files... $copied/$total';
	}

	function leave():Void
	{
		if (finished)
			return;

		finished = true;

		if (failed.length > 0)
			CrashHandler.writeLog("copy", "Failed to copy:\n" + failed.join("\n"));

		FlxG.switchState(new states.TitleState());
	}

	static function findMissing():Array<String>
	{
		var missing:Array<String> = [];

		#if sys
		for (id in Assets.list())
		{
			if (!shouldCopy(id))
				continue;

			if (!FileSystem.exists(StorageUtil.directory + id))
				missing.push(id);
		}
		#end

		return missing;
	}

	static function shouldCopy(id:String):Bool
	{
		for (prefix in PREFIXES)
			if (StringTools.startsWith(id, prefix))
				return true;
		return false;
	}

	static function readBytes(id:String):haxe.io.Bytes
	{
		try
		{
			return Assets.getBytes(id);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	static function readText(id:String):String
	{
		try
		{
			var text:String = Assets.getText(id);
			if (text != null)
				return text;
		}
		catch (e:Dynamic) {}

		try
		{
			return lime.utils.Assets.getText(id);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	function copy(id:String):Void
	{
		#if sys
		try
		{
			var target:String = StorageUtil.directory + id;
			StorageUtil.createDirectory(Path.directory(target));

			var bytes = readBytes(id);
			if (bytes != null)
				File.saveBytes(target, bytes);
			else
			{
				var text:String = readText(id);
				if (text == null && !Assets.exists(id))
					throw "missing";

				File.saveContent(target, text != null ? text : "");
			}
		}
		catch (e:Dynamic)
		{
			failed.push(id);
		}
		#end

		copied++;
	}
}
