#import "EJBindingCanvas.h"

#import "EJCanvasContext2DScreen.h"
#import "EJCanvasContext2DTexture.h"
#import "EJBindingCanvasContext2D.h"


@implementation EJBindingCanvas

static int firstCanvasInstance = YES;

- (id)initWithContext:(JSContextRef)ctx object:(JSObjectRef)obj argc:(size_t)argc argv:(const JSValueRef [])argv {
	if( self = [super initWithContext:ctx object:obj argc:argc argv:argv] ) {
		scalingMode = kEJScalingModeFitWidth;
		useRetinaResolution = true;
		msaaEnabled = false;
		msaaSamples = 2;
		
		// If this is the first canvas instance we created, make it the screen canvas
		if( firstCanvasInstance ) {
			isScreenCanvas = YES;
			firstCanvasInstance = NO;
		}
		
		if( argc == 2 ) {
			width = JSValueToNumberFast(ctx, argv[0]);
			height = JSValueToNumberFast(ctx, argv[1]);
		}
		else {
			CGSize screen = [EJApp instance].view.bounds.size;
			width = screen.width;
			height = screen.height;
		}
	}
	return self;
}

- (void)dealloc {
	[renderingContext release];
	if( jsCanvasContext ) {
		JSValueUnprotect([EJApp instance].jsGlobalContext, jsCanvasContext);
	}
	[super dealloc];
}

- (EJTexture *)texture {
	if( [renderingContext isKindOfClass:[EJCanvasContext2DTexture class]] ) {
		return ((EJCanvasContext2DTexture *)renderingContext).texture;
	}
	else {
		return nil;
	}
}

EJ_BIND_ENUM(scalingMode, scalingMode, EJ_ENUM_NAMES(
	[kEJScalingModeNone] = "none",
	[kEJScalingModeFitWidth] = "fit-width",
	[kEJScalingModeFitHeight] = "fit-height"
));

EJ_BIND_GET(width, ctx) {
	return JSValueMakeNumber(ctx, width);
}

EJ_BIND_SET(width, ctx, value) {
	short newWidth = JSValueToNumberFast(ctx, value);
	if( renderingContext && newWidth != width ) {
		NSLog(@"Warning: rendering context already created; can't change width");
		return;
	}
	width = newWidth;
}

EJ_BIND_GET(height, ctx) {
	return JSValueMakeNumber(ctx, height);
}

EJ_BIND_SET(height, ctx, value) {
	short newHeight = JSValueToNumberFast(ctx, value);
	if( renderingContext && newHeight != height ) {
		NSLog(@"Warning: rendering context already created; can't change height");
		return;
	}
	height = newHeight;
}

EJ_BIND_GET(offsetLeft, ctx) {
	return JSValueMakeNumber(ctx, 0);
}

EJ_BIND_GET(offsetTop, ctx) {
	return JSValueMakeNumber(ctx, 0);
}

EJ_BIND_SET(retinaResolutionEnabled, ctx, value) {
	useRetinaResolution = JSValueToBoolean(ctx, value);
}

EJ_BIND_GET(retinaResolutionEnabled, ctx) {
	return JSValueMakeBoolean(ctx, useRetinaResolution);
}

EJ_BIND_SET(MSAAEnabled, ctx, value) {
	msaaEnabled = JSValueToBoolean(ctx, value);
}

EJ_BIND_GET(MSAAEnabled, ctx) {
	return JSValueMakeBoolean(ctx, msaaEnabled);
}

EJ_BIND_SET(MSAASamples, ctx, value) {
	int samples = JSValueToNumberFast(ctx, value);
	if( samples == 2 || samples == 4 ) {
		msaaSamples	= samples;
	}
}

EJ_BIND_GET(MSAASamples, ctx) {
	return JSValueMakeNumber(ctx, msaaSamples);
}

EJ_BIND_FUNCTION(getContext, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; };
	
	NSString * type = JSValueToNSString(ctx, argv[0]);
	EJCanvasContextMode newContextMode = kEJCanvasContextModeInvalid;
	
	if( [type isEqualToString:@"2d"] ) {
		newContextMode = kEJCanvasContextMode2D;
	}
	else if( [type rangeOfString:@"webgl"].location != NSNotFound ) {
		newContextMode = kEJCanvasContextModeWebGL;
	}
	
	if( contextMode != kEJCanvasContextModeInvalid && contextMode == kEJCanvasContextModeWebGL ) {
		// Nothing changed - just return the already created context
		return jsCanvasContext;
	}
	else if( contextMode != kEJCanvasContextModeInvalid && contextMode != kEJCanvasContextModeWebGL) {
		// New mode is different from current - we can't do that
		NSLog(@"Warning: CanvasContext already created. Can't change 2d/webgl mode.");
		return NULL;
	}
	
	
	
	// Create the requested CanvasContext
	
	[EJApp instance].currentRenderingContext = nil;
	
	if( newContextMode == kEJCanvasContextMode2D ) {
		if( isScreenCanvas ) {
			EJCanvasContext2DScreen * sc = [[EJCanvasContext2DScreen alloc] initWithWidth:width height:height];
			sc.useRetinaResolution = useRetinaResolution;
			sc.scalingMode = scalingMode;
			
			[EJApp instance].screenRenderingContext = sc;		
			renderingContext = sc;
		}
		else {
			renderingContext = [[EJCanvasContext2DTexture alloc] initWithWidth:width height:height];
		}
		
		// Create the JS object
		JSClassRef canvasContextClass = [[EJApp instance] getJSClassForClass:[EJBindingCanvasContext2D class]];
		jsCanvasContext = JSObjectMake( ctx, canvasContextClass, NULL );
		JSValueProtect(ctx, jsCanvasContext);
		
		// Create the native instance
		EJBindingCanvasContext2D * canvasContextBinding = [[EJBindingCanvasContext2D alloc] initWithContext:ctx object:jsCanvasContext renderingContext:(EJCanvasContext2D *)renderingContext];
		
		// Attach the native instance to the js object
		JSObjectSetPrivate( jsCanvasContext, (void *)canvasContextBinding );
	}
	
	else if( newContextMode == kEJCanvasContextModeWebGL ) {
		NSLog(@"Warning: webgl context not yet implemented.");
		return NULL;
	}
	
	
	contextMode = newContextMode;
	
	renderingContext.msaaEnabled = msaaEnabled;
	renderingContext.msaaSamples = msaaSamples;
	
	[renderingContext create];
	[EJApp instance].currentRenderingContext = renderingContext;
	
	
	return jsCanvasContext;
}

@end
