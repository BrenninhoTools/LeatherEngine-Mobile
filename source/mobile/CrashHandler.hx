package mobile;

import haxe.CallStack;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
#if sys
import sys.io.File;
#end

class CrashHandler
{
	static var ready:Bool = false;

	public static function init():Void
	{
		if (ready)
			return;

		ready = true;
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
		#end
	}

	static function onUncaughtError(event:UncaughtErrorEvent):Void
	{
		event.preventDefault();
		event.stopImmediatePropagation();
		report(Std.string(event.error), CallStack.exceptionStack(true));
	}

	static function onCriticalError(message:Dynamic):Void
	{
		report(Std.string(message), CallStack.exceptionStack(true));
	}

	static function report(message:String, stack:Array<StackItem>):Void
	{
		var text:String = message + "\n\n" + CallStack.toString(stack);
		var path:String = writeLog("crash", text);

		try
		{
			lime.app.Application.current.window.alert(text + (path != null ? "\n\nSaved to " + path : ""), "Leather Engine crashed");
		}
		catch (e:Dynamic) {}

		lime.system.System.exit(1);
	}

	public static function writeLog(name:String, text:String):String
	{
		#if sys
		try
		{
			var folder:String = StorageUtil.directory + "crash/";
			StorageUtil.createDirectory(folder);
			var stamp:String = DateTools.format(Date.now(), "%Y-%m-%d_%H-%M-%S");
			var path:String = folder + name + "_" + stamp + ".txt";
			File.saveContent(path, text);
			return path;
		}
		catch (e:Dynamic) {}
		#end
		return null;
	}
}
