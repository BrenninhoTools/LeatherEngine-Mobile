package com.leather128.funkin.mobile;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.os.VibratorManager;

import org.haxe.extension.Extension;

public class HapticsUtil {

	private static Vibrator vibrator;

	@SuppressWarnings("deprecation")
	private static Vibrator getVibrator() {
		if (vibrator != null) {
			return vibrator;
		}

		Activity activity = Extension.mainActivity;
		if (activity == null) {
			return null;
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			VibratorManager manager = (VibratorManager) activity.getSystemService(Context.VIBRATOR_MANAGER_SERVICE);
			if (manager != null) {
				vibrator = manager.getDefaultVibrator();
			}
		} else {
			vibrator = (Vibrator) activity.getSystemService(Context.VIBRATOR_SERVICE);
		}

		return vibrator;
	}

	public static boolean isSupported() {
		Vibrator device = getVibrator();
		return device != null && device.hasVibrator();
	}

	@SuppressWarnings("deprecation")
	public static void vibrate(int duration, int amplitude) {
		Vibrator device = getVibrator();
		if (device == null || !device.hasVibrator() || duration <= 0) {
			return;
		}

		if (amplitude < 1) {
			amplitude = 1;
		} else if (amplitude > 255) {
			amplitude = 255;
		}

		try {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
				int strength = device.hasAmplitudeControl() ? amplitude : VibrationEffect.DEFAULT_AMPLITUDE;
				device.vibrate(VibrationEffect.createOneShot(duration, strength));
			} else {
				device.vibrate(duration);
			}
		} catch (Exception e) {
		}
	}

	public static void cancel() {
		Vibrator device = getVibrator();
		if (device != null) {
			device.cancel();
		}
	}
}
