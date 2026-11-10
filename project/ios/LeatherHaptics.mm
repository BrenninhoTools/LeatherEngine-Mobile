#import <UIKit/UIKit.h>

static UIImpactFeedbackGenerator *leatherImpact = nil;

static void leatherHapticsRun(void (^block)(void))
{
	if ([NSThread isMainThread])
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
}

extern "C" void leather_ios_vibrate(double intensity)
{
	if (intensity <= 0)
		return;

	if (intensity > 1)
		intensity = 1;

	leatherHapticsRun(^{
		if (leatherImpact == nil)
		{
			leatherImpact = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
			[leatherImpact prepare];
		}

		if (@available(iOS 13.0, *))
			[leatherImpact impactOccurredWithIntensity:intensity];
		else
			[leatherImpact impactOccurred];

		[leatherImpact prepare];
	});
}
