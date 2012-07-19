//
//  v002LUTPlugIn.m
//  v002LUT
//
//  Created by vade on 9/2/08.
//  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "v002FilmLUTPlugIn.h"

#define	kQCPlugIn_Name				@"v002 LUT"
#define	kQCPlugIn_Description		@"Generate 32 bit float lookup tables"

static void _TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* info)
{
	glDeleteTextures(1, &name);
}

@implementation v002FilmLUTPlugIn


@dynamic inputKnee;
@dynamic inputColor;
@dynamic outputImage;

+ (NSDictionary*) attributes
{	
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey,
            [kQCPlugIn_Description stringByAppendingString:kv002DescriptionAddOnText], QCPlugInAttributeDescriptionKey,
            kQCPlugIn_Category, @"categories", nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{	
	if([key isEqualToString:@"inputKnee"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Knee", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.5], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithFloat:1.0], QCPortAttributeMaximumValueKey,
				nil];
	}
	
	if([key isEqualToString:@"inputColor"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Knee Color", QCPortAttributeNameKey, QCPortTypeColor, QCPortAttributeTypeKey, nil];
	}
	
	if([key isEqualToString:@"outputImage"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"LUT Image", QCPortAttributeNameKey, nil];
	}

	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{	
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{	
	return kQCPlugInTimeModeNone;
}

@end

@implementation v002FilmLUTPlugIn (Execution)

// override supers startExecution to provide 32 bit per channel FBO 
- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	// work around lack of GLMacro.h for now
	CGLContextObj cgl_ctx = [context CGLContextObj];
//	CGLSetCurrentContext(cgl_ctx);
	
	// we can remove shader loading... 
	
	// here is our over-ride. yay.
	pluginFBO = [[v002FBO alloc] initWithContext:cgl_ctx];
	if(pluginFBO == nil)
	{
		[context logMessage:@"Cannot create FBO"];
		return NO;
	}
	
	return YES;
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	CGLContextObj cgl_ctx = [context CGLContextObj];
		
	GLint finalOutput = [self renderToFBO:cgl_ctx bounds:NSMakeRect(0.0, 0.0, 1024.0, 1.0) knee:(GLfloat)self.inputKnee color:self.inputColor];
	if(finalOutput == 0)
		return NO;

	// cache our FBO output. No need to re-create more than once.... 
/*	if( (!outputImageProvider && outputImageProvider == nil) || ([self didValueForInputKeyChange:@"inputKnee"] || [self didValueForInputKeyChange:@"inputColor"]))
	{
		// cleanup... (can send message to nil)
		[outputImageProvider release];
		outputImageProvider = [context outputImageProviderFromTextureWithPixelFormat:QCPlugInPixelFormatRGBAf pixelsWide:1024 pixelsHigh:1 name:finalOutput flipped:NO releaseCallback:_TextureReleaseCallback releaseContext:NULL colorSpace:[context colorSpace] shouldColorMatch:YES];
		[outputImageProvider retain];
	}
*/	
	// we do not want color to match, this is a LUT providing numerical data, not a color to look nice.
	id provider = [context outputImageProviderFromTextureWithPixelFormat:QCPlugInPixelFormatRGBAf pixelsWide:1024 pixelsHigh:1 name:finalOutput flipped:NO releaseCallback:_TextureReleaseCallback releaseContext:NULL colorSpace:[context colorSpace] shouldColorMatch:NO];

	self.outputImage = provider;
	
	return YES;
}

- (GLuint) renderToFBO:(CGLContextObj)cgl_ctx bounds:(NSRect)bounds knee:(GLfloat)knee color:(CGColorRef)color
{
	GLsizei width = bounds.size.width,	height = bounds.size.height;
	
	GLfloat kneePosition = knee * width;
	
	// this must be called before any other FBO stuff can happen for 10.6
	[pluginFBO pushAttributes:cgl_ctx];
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	GLuint tex;
	
	glGenTextures(1, &tex);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, tex);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, bounds.size.width, bounds.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	[pluginFBO pushFBO:cgl_ctx];
	[pluginFBO attachFBO:cgl_ctx withTexture:tex width:bounds.size.width height:bounds.size.height];
	
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);			
	
	glBegin(GL_QUADS);
	glColor4f(0.0, 0.0, 0.0, 1.0);
	glVertex2f(0, 0);
	glVertex2f(0, height);

	const CGFloat* refColor;
	refColor = CGColorGetComponents(color);
	
	glColor4f(refColor[0], refColor[1], refColor[2], 1.0);
	glVertex2f(kneePosition, 0);
	glVertex2f(kneePosition, height);
	
	glVertex2f(kneePosition, 0);
	glVertex2f(kneePosition, height);
	
	glColor4f(1.0, 1.0, 1.0, 1.0);
	glVertex2f(width, height);
	glVertex2f(width, 0);
	glEnd();		
	
	[pluginFBO detachFBO:cgl_ctx];
	[pluginFBO popFBO:cgl_ctx];
	[pluginFBO popAttributes:cgl_ctx];
	return tex;
}


@end
