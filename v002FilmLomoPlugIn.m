//
//  v002FilmLomoPlugIn.m
//  v002FilmLomo
//
//  Created by vade on 8/6/08.
//  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "v002FilmLomoPlugIn.h"

#define	kQCPlugIn_Name				@"v002 Lomo"
#define	kQCPlugIn_Description		@"Recreates elements of the classic lomography look via configurable RGB lookup table"


#pragma mark -
#pragma mark Static Functions

static void _TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* info)
{
	glDeleteTextures(1, &name);
}

@implementation v002FilmLomoPlugIn

@dynamic inputImage, inputLUT, inputSharpness, inputSaturation, inputAmount, outputImage;

+ (NSDictionary*) attributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey,
            [kQCPlugIn_Description stringByAppendingString:kv002DescriptionAddOnText], QCPlugInAttributeDescriptionKey,
            kQCPlugIn_Category, QCPlugInAttributeCategoriesKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	if([key isEqualToString:@"inputImage"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];
	}

	if([key isEqualToString:@"inputLUT"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"LUT", QCPortAttributeNameKey, nil];
	}
		
	if([key isEqualToString:@"inputAmount"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Amount", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithFloat:1.5], QCPortAttributeMaximumValueKey,
				nil];
	}
	
	if([key isEqualToString:@"inputSharpness"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Sharpness", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithFloat:1.0], QCPortAttributeMaximumValueKey,
				nil];
	}
	
	if([key isEqualToString:@"inputSaturation"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Saturation", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithFloat:2.0], QCPortAttributeMaximumValueKey,
				nil];
	}
	
	
	if([key isEqualToString:@"outputImage"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];
	}
	
	return nil;
}

+ (NSArray*) sortedPropertyPortKeys
{
	return [NSArray arrayWithObjects:@"inputImage", @"inputLUT", @"inputAmount", @"inputSharpness", nil];
}

+ (QCPlugInExecutionMode) executionMode
{
	return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode) timeMode
{
	return kQCPlugInTimeModeNone;
}

- (id) init
{
	if(self = [super init])
	{
		self.pluginShaderName = @"v002.film-lomo";
	}
	
	return self;
}

@end

@implementation v002FilmLomoPlugIn (Execution)

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	CGLContextObj cgl_ctx = [context CGLContextObj];
	CGLLockContext(cgl_ctx);
	
	id<QCPlugInInputImageSource>   image = self.inputImage;
	id<QCPlugInInputImageSource>   lut = self.inputLUT;

	// LUT should not be color corrected, thus we use imageColorSpace on it for a basic NOP color correct
	CGColorSpaceRef cspace = ([image shouldColorMatch]) ? [context colorSpace] : [image imageColorSpace];
	
	if(image &&  [image lockTextureRepresentationWithColorSpace:cspace forBounds:[image imageBounds]] &&
	   lut && [lut lockTextureRepresentationWithColorSpace:[lut imageColorSpace] forBounds:[lut imageBounds]])
	{	
		
		[image bindTextureRepresentationToCGLContext:[context CGLContextObj] textureUnit:GL_TEXTURE0 normalizeCoordinates:YES];
		[lut bindTextureRepresentationToCGLContext:[context CGLContextObj] textureUnit:GL_TEXTURE1 normalizeCoordinates:YES];

		GLuint finalOutput;
		
		finalOutput = [self renderToFBO:cgl_ctx image:image lut:lut amount:self.inputAmount sharpness:self.inputSharpness saturation:self.inputSaturation];
			
		id provider = nil;	
		
		if(finalOutput != 0)
		{
			
#if __BIG_ENDIAN__
#define v002QCPluginPixelFormat QCPlugInPixelFormatARGB8
#else
#define v002QCPluginPixelFormat QCPlugInPixelFormatBGRA8			
#endif
			// we have to use a 4 channel output format, I8 does not support alpha at fucking all, so if we want text with alpha, we need to use this and waste space. Ugh.
			provider = [context outputImageProviderFromTextureWithPixelFormat:v002QCPluginPixelFormat pixelsWide:[image imageBounds].size.width pixelsHigh:[image imageBounds].size.height name:finalOutput flipped:NO releaseCallback:_TextureReleaseCallback releaseContext:NULL colorSpace:[context colorSpace] shouldColorMatch:[image shouldColorMatch]];
			
			self.outputImage = provider;
			
		}
				
		[image unbindTextureRepresentationFromCGLContext:[context CGLContextObj] textureUnit:GL_TEXTURE0];
		[image unlockTextureRepresentation];

		[lut unbindTextureRepresentationFromCGLContext:[context CGLContextObj] textureUnit:GL_TEXTURE1];
		[lut unlockTextureRepresentation];

	}	
	else
		self.outputImage = nil;
	
	CGLUnlockContext(cgl_ctx);
	return YES;
}

- (GLuint) renderToFBO:(CGLContextObj)cgl_ctx image:(id<QCPlugInInputImageSource>)image lut:(id<QCPlugInInputImageSource>)lutImage amount:(GLfloat)amount sharpness:(GLfloat)sharpness saturation:(GLfloat)saturation
{	
	[pluginFBO pushAttributes:cgl_ctx];
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	NSSize size = [image imageBounds].size;
	GLuint tex;
	
	glGenTextures(1, &tex);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, tex);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, size.width, size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	[pluginFBO pushFBO:cgl_ctx];
	[pluginFBO attachFBO:cgl_ctx withTexture:tex width:size.width height:size.height];

	glColor4f(1.0, 1.0, 1.0, 1.0);
	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, [image textureName]);
	
	// do not need blending if we use black border for alpha and replace env mode, saves a buffer wipe
	// we can do this since our image draws over the complete surface of the FBO, no pixel goes untouched.
	glDisable(GL_BLEND);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);	

	// bind our shader program
	glUseProgramObjectARB([pluginShader programObject]);
	
	// set program vars
	glUniform1iARB([pluginShader getUniformLocation:"tex0"], 0); // load tex0 sampler to texture unit 0 
	glUniform1iARB([pluginShader getUniformLocation:"tex1"], 1); // load tex1 sampler to texture unit 1
	glUniform2fARB([pluginShader getUniformLocation:"dim"], [image imageBounds].size.width, [image imageBounds].size.height); // glsl uniform vars
	glUniform2fARB([pluginShader getUniformLocation:"dim2"], [lutImage imageBounds].size.width, [lutImage imageBounds].size.height); 
	glUniform1fARB([pluginShader getUniformLocation:"amount"], amount); 
	glUniform1fARB([pluginShader getUniformLocation:"sharpness"], sharpness); 
	glUniform1fARB([pluginShader getUniformLocation:"saturation"], saturation);
	
	// move to VA for rendering
	GLfloat tex_coords[] = 
	{
		1.0,1.0,
		0.0,1.0,
		0.0,0.0,
		1.0,0.0
	};
	
	GLfloat verts[] = 
	{
		[image imageBounds].size.width,[image imageBounds].size.height,
		0.0,[image imageBounds].size.height,
		0.0,0.0,
		[image imageBounds].size.width,0.0
	};
	
	glEnableClientState( GL_TEXTURE_COORD_ARRAY );
	glTexCoordPointer(2, GL_FLOAT, 0, tex_coords );
	glEnableClientState(GL_VERTEX_ARRAY);		
	glVertexPointer(2, GL_FLOAT, 0, verts );
	glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );	// TODO: GL_QUADS or GL_TRIANGLE_FAN?
	glDisableClientState( GL_TEXTURE_COORD_ARRAY );
	glDisableClientState(GL_VERTEX_ARRAY);			
	
	// disable shader program
	glUseProgramObjectARB(NULL);
	[pluginFBO detachFBO:cgl_ctx];
	[pluginFBO popFBO:cgl_ctx];
	[pluginFBO popAttributes:cgl_ctx];
	return tex;
}
@end
