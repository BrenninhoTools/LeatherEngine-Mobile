package mobile;

import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if android
import extension.androidtools.Permissions;
import extension.androidtools.Settings;
import extension.androidtools.content.Context;
import extension.androidtools.os.Build.VERSION as AndroidVersion;
import extension.androidtools.os.Environment;
import extension.androidtools.widget.Toast;
#end

class StorageUtil
{
	public static inline var DATA:String = "data";
	public static inline var OBB:String = "obb";
	public static inline var MEDIA:String = "media";
	public static inline var EXTERNAL:String = "external";

	public static final TYPES:Array<String> = #if android [DATA, OBB, MEDIA, EXTERNAL] #else [DATA] #end;
	public static final FOLDERS:Array<String> = ["mods", "assets/replays", "crash"];

	public static var type(default, null):String = DATA;
	public static var directory(default, null):String = "";
	public static var usingFallback(default, null):Bool = false;

	static inline var CONFIG_FILE:String = "storage.txt";
	static inline var EXTERNAL_FOLDER:String = "LeatherEngine";

	public static function init():Void
	{
		var wanted:String = readType();
		var candidates:Array<String> = [wanted];
		if (wanted != DATA)
			candidates.push(DATA);

		type = DATA;
		directory = null;
		usingFallback = false;

		for (candidate in candidates)
		{
			var path:String = resolve(candidate);
			if (path != null && prepare(candidate, path))
			{
				type = candidate;
				directory = path;
				break;
			}
		}

		if (directory == null)
		{
			directory = internalDirectory();
			createDirectory(directory);
		}

		usingFallback = type != wanted;

		#if sys
		Sys.setCwd(directory);
		#end

		ensureFolders();

		if (usingFallback)
			notify('Could not use "$wanted" storage, using "$type" instead');
	}

	public static function getPath(file:String = ""):String
	{
		return directory + file;
	}

	public static function setType(value:String):Void
	{
		if (!TYPES.contains(value))
			value = DATA;

		#if sys
		try
		{
			File.saveContent(configPath(), value);
		}
		catch (e:Dynamic) {}
		#end

		if (value == EXTERNAL && !hasExternalAccess())
			requestExternalAccess();

		if (value != type)
			notify("Restart the game to use the new storage");
	}

	public static function getSavedType():String
	{
		return readType();
	}

	public static function resolve(value:String):String
	{
		var path:String = null;

		#if android
		try
		{
			switch (value)
			{
				case OBB:
					path = Context.getObbDir();
				case MEDIA:
					path = Environment.getExternalStorageDirectory() + "/Android/media/" + packageName();
				case EXTERNAL:
					path = Environment.getExternalStorageDirectory() + "/" + EXTERNAL_FOLDER;
				default:
					path = Context.getExternalFilesDir();
			}
		}
		catch (e:Dynamic)
		{
			path = null;
		}

		if ((path == null || path.length == 0) && value == DATA)
			path = internalDirectory();
		#elseif ios
		path = lime.system.System.documentsDirectory;
		#elseif sys
		path = Sys.getCwd();
		#end

		return path == null || path.length == 0 ? null : Path.addTrailingSlash(path);
	}

	public static function hasExternalAccess():Bool
	{
		#if android
		try
		{
			if (AndroidVersion.SDK_INT >= 30)
				return Environment.isExternalStorageManager();

			return Permissions.getGrantedPermissions().contains("android.permission.WRITE_EXTERNAL_STORAGE");
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		return true;
		#end
	}

	public static function requestExternalAccess():Void
	{
		#if android
		try
		{
			if (AndroidVersion.SDK_INT >= 30)
				Settings.requestSetting("MANAGE_APP_ALL_FILES_ACCESS_PERMISSION");
			else
				Permissions.requestPermissions(["READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE"]);
		}
		catch (e:Dynamic) {}
		#end
	}

	public static function createDirectory(path:String):Bool
	{
		#if sys
		try
		{
			if (!FileSystem.exists(path))
				FileSystem.createDirectory(path);
			return FileSystem.isDirectory(path);
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		return false;
		#end
	}

	public static function ensureFolders():Void
	{
		for (folder in FOLDERS)
			createDirectory(directory + folder);

		#if sys
		if (type == MEDIA || type == EXTERNAL)
		{
			try
			{
				var noMedia:String = directory + ".nomedia";
				if (!FileSystem.exists(noMedia))
					File.saveContent(noMedia, "");
			}
			catch (e:Dynamic) {}
		}
		#end
	}

	public static function notify(message:String):Void
	{
		#if android
		try
		{
			Toast.makeText(message, Toast.LENGTH_LONG);
		}
		catch (e:Dynamic) {}
		#end
	}

	static function prepare(kind:String, path:String):Bool
	{
		if (kind == EXTERNAL && !hasExternalAccess())
		{
			requestExternalAccess();
			return false;
		}

		if (!createDirectory(path))
			return false;

		return isWritable(path);
	}

	static function isWritable(path:String):Bool
	{
		#if sys
		var probe:String = path + ".write_test_" + Std.int(haxe.Timer.stamp() * 1000);
		try
		{
			File.saveContent(probe, "ok");
			var ok:Bool = FileSystem.exists(probe);
			FileSystem.deleteFile(probe);
			return ok;
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		return true;
		#end
	}

	static function readType():String
	{
		#if sys
		try
		{
			var path:String = configPath();
			if (FileSystem.exists(path))
			{
				var value:String = StringTools.trim(File.getContent(path));
				if (TYPES.contains(value))
					return value;
			}
		}
		catch (e:Dynamic) {}
		#end
		return DATA;
	}

	static function internalDirectory():String
	{
		return Path.addTrailingSlash(lime.system.System.applicationStorageDirectory);
	}

	static function configPath():String
	{
		return internalDirectory() + CONFIG_FILE;
	}

	static function packageName():String
	{
		var app = lime.app.Application.current;
		var name:String = app != null && app.meta != null ? app.meta.get("packageName") : null;
		return name != null ? name : "com.leather128.funkin";
	}
}

class StorageOption extends ui.Option.StringSaveOption
{
	public function new(name:String, row:Int)
	{
		super(name, StorageUtil.TYPES, row, "hitboxMode");

		Save_Data_Name = null;
		Current_Mode = StorageUtil.getSavedType();
		Option_Name = Cool_Name + " " + Current_Mode;

		remove(Alphabet_Text);
		Alphabet_Text.kill();
		Alphabet_Text.destroy();

		Alphabet_Text = new ui.Alphabet(20, 20 + (Option_Row * 100), Option_Name, true);
		Alphabet_Text.isMenuItem = true;
		Alphabet_Text.targetY = Option_Row;
		add(Alphabet_Text);
	}

	override function SetDataIGuess()
	{
		StorageUtil.setType(Current_Mode);
	}
}
