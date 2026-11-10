package mobile;

class AssetUtil
{
	public static function readText(path:String):Null<String>
	{
		if (path == null)
			return null;

		try
		{
			if (openfl.utils.Assets.exists(path))
			{
				var text:String = openfl.utils.Assets.getText(path);
				if (text != null)
					return text;

				var bytes = openfl.utils.Assets.getBytes(path);
				if (bytes != null)
					return bytes.toString();
			}
		}
		catch (e:Dynamic) {}

		try
		{
			if (lime.utils.Assets.exists(path))
				return lime.utils.Assets.getText(path);
		}
		catch (e:Dynamic) {}

		return null;
	}
}
