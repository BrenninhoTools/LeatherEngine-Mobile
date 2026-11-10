#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static bool leatherFullScreen = false;

static BOOL leatherPrefersHomeIndicatorAutoHidden(id self, SEL _cmd)
{
	return leatherFullScreen ? YES : NO;
}

static UIRectEdge leatherPreferredScreenEdges(id self, SEL _cmd)
{
	return leatherFullScreen ? UIRectEdgeAll : UIRectEdgeNone;
}

static BOOL leatherPrefersStatusBarHidden(id self, SEL _cmd)
{
	return YES;
}

static UIWindow *leatherKeyWindow(void)
{
	UIApplication *application = [UIApplication sharedApplication];

	if (@available(iOS 13.0, *))
	{
		for (UIScene *scene in application.connectedScenes)
		{
			if (![scene isKindOfClass:[UIWindowScene class]])
				continue;

			for (UIWindow *window in ((UIWindowScene *)scene).windows)
			{
				if (window.isKeyWindow)
					return window;
			}
		}
	}

	for (UIWindow *window in application.windows)
	{
		if (window.isKeyWindow)
			return window;
	}

	return application.windows.firstObject;
}

static UIViewController *leatherRootController(void)
{
	UIWindow *window = leatherKeyWindow();
	return window != nil ? window.rootViewController : nil;
}

static void leatherPatchController(UIViewController *controller)
{
	if (controller == nil)
		return;

	Class cls = [controller class];
	if (objc_getAssociatedObject(cls, (const void *)&leatherFullScreen) != nil)
		return;

	class_replaceMethod(cls, @selector(prefersHomeIndicatorAutoHidden), (IMP)leatherPrefersHomeIndicatorAutoHidden, "B@:");
	class_replaceMethod(cls, @selector(preferredScreenEdgesDeferringSystemGestures), (IMP)leatherPreferredScreenEdges, "Q@:");
	class_replaceMethod(cls, @selector(prefersStatusBarHidden), (IMP)leatherPrefersStatusBarHidden, "B@:");

	objc_setAssociatedObject(cls, (const void *)&leatherFullScreen, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void leatherApply(void)
{
	UIViewController *controller = leatherRootController();
	if (controller == nil)
		return;

	leatherPatchController(controller);

	[controller setNeedsStatusBarAppearanceUpdate];
	[controller setNeedsUpdateOfHomeIndicatorAutoHidden];
	[controller setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
}

static void leatherRunOnMain(void (^block)(void))
{
	if ([NSThread isMainThread])
		block();
	else
		dispatch_sync(dispatch_get_main_queue(), block);
}

extern "C" void leather_ios_set_full_screen(bool full)
{
	leatherFullScreen = full;
	leatherRunOnMain(^{
		leatherApply();
	});
}

extern "C" double leather_ios_safe_inset(int side)
{
	__block double value = 0;

	leatherRunOnMain(^{
		UIViewController *controller = leatherRootController();
		UIView *view = controller != nil ? controller.view : nil;
		if (view == nil)
			return;

		UIEdgeInsets insets = view.safeAreaInsets;
		CGFloat scale = view.contentScaleFactor > 0 ? view.contentScaleFactor : [UIScreen mainScreen].scale;

		switch (side)
		{
			case 0:
				value = insets.left * scale;
				break;
			case 1:
				value = insets.top * scale;
				break;
			case 2:
				value = insets.right * scale;
				break;
			default:
				value = insets.bottom * scale;
				break;
		}
	});

	return value;
}
