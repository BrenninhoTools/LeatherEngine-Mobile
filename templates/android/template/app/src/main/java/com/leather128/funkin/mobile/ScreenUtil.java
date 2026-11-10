package com.leather128.funkin.mobile;

import android.app.Activity;
import android.os.Build;
import android.view.DisplayCutout;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;

import org.haxe.extension.Extension;

public class ScreenUtil {

	private static volatile boolean fullScreen = false;

	public static void setFullScreen(final boolean full) {
		fullScreen = full;

		final Activity activity = Extension.mainActivity;
		if (activity == null) {
			return;
		}

		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				apply(activity);
			}
		});
	}

	public static boolean isFullScreen() {
		return fullScreen;
	}

	public static String getSafeInsets() {
		final Activity activity = Extension.mainActivity;
		if (activity == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
			return "0,0,0,0";
		}

		Window window = activity.getWindow();
		if (window == null) {
			return "0,0,0,0";
		}

		WindowInsets insets = window.getDecorView().getRootWindowInsets();
		if (insets == null) {
			return "0,0,0,0";
		}

		DisplayCutout cutout = insets.getDisplayCutout();
		if (cutout == null) {
			return "0,0,0,0";
		}

		return cutout.getSafeInsetLeft() + "," + cutout.getSafeInsetTop() + "," + cutout.getSafeInsetRight() + "," + cutout.getSafeInsetBottom();
	}

	private static void apply(Activity activity) {
		Window window = activity.getWindow();
		if (window == null) {
			return;
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
			int mode;
			if (fullScreen) {
				mode = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
					? WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
					: WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
			} else {
				mode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER;
			}

			WindowManager.LayoutParams params = window.getAttributes();
			if (params.layoutInDisplayCutoutMode != mode) {
				params.layoutInDisplayCutoutMode = mode;
				window.setAttributes(params);
			}
		}

		hideSystemBars(window);
	}

	@SuppressWarnings("deprecation")
	private static void hideSystemBars(Window window) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
			WindowInsetsController controller = window.getInsetsController();
			if (controller != null) {
				controller.hide(WindowInsets.Type.systemBars());
				controller.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
			}
			return;
		}

		window.getDecorView().setSystemUiVisibility(
			View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
			| View.SYSTEM_UI_FLAG_FULLSCREEN
			| View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
			| View.SYSTEM_UI_FLAG_LAYOUT_STABLE
			| View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
			| View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
	}
}
