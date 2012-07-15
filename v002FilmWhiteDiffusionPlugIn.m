//
//  v002FBOGLSLTemplatePlugIn.m
//  v002FBOGLSLTemplate
//
//  Created by vade on 6/30/08.
//  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "v002FilmWhiteDiffusionPlugIn.h"

#define	kQCPlugIn_Name				@"v002 White Diffusion"
#define	kQCPlugIn_Description		@"Emulate classic clack and white film look with diffused and blown out whites."


#pragma mark -
#pragma mark Static Functions

static void _TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* info)
{
	glDeleteTextures(1, &name);
}

@implementation v002FilmWhiteDiffusionPlugIn

@dynamic inputImage;
@dynamic inputAmount;
@dynamic inputDiffusion;
@dynamic inputExposure;
@dynamic outputImage;

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
	
	if([key isEqualToString:@"inputAmount"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Amount", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithFloat:1.0], QCPortAttributeMaximumValueKey,
				nil];
	}
	
	if([key isEqualToString:@"inputExposure"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Exposure", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithFloat:1.0], QCPortAttributeMaximumValueKey,
				nil];
	}

	if([key isEqualToString:@"inputDiffusion"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Diffusion", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithFloat:1.0], QCPortAttributeMaximumValueKey,
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
	return [NSArray arrayWithObjects:@"inputImage", @"inputAmount", nil];
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
		self.pluginShaderName = @"v002.film-whitediffusion";
	}
	
	return self;
}

@end

@implementation v002FilmWhiteDiffusionPlugIn (Execution)

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{	
	CGLContextObj cgl_ctx = [context CGLContextObj];
	CGLLockContext(cgl_ctx);
		
	id<QCPlugInInputImageSource>   image = self.inputImage;

	CGColorSpaceRef cspace = ([image shouldColorMatch]) ? [context colorSpace] : [image imageColorSpace];
	
	if(image && [image lockTextureRepresentationWithColorSpace:cspace forBounds:[image imageBounds]])
	{	
		[image bindTextureRepresentationToCGLContext:[context CGLContextObj] textureUnit:GL_TEXTURE0 normalizeCoordinates:YES];
		
		GLuint finalOutput = [self renderToFBO:cgl_ctx width:[image imageBounds].size.width height:[image imageBounds].size.height bounds:[image imageBounds] texture:[image textureName] amount:self.inputAmount diffusion:self.inputDiffusion exposure:self.inputExposure];
		
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

		self.outputImage = provider;
		
		}	
	else
		self.outputImage = nil;

	CGLUnlockContext(cgl_ctx);
	return YES;
}

- (GLuint) renderToFBO:(CGLContextObj)context width:(NSUInteger)pixelsWide height:(NSUInteger)pixelsHigh bounds:(NSRect)bounds texture:(GLuint)texture amount:(double)amount diffusion:(double)diffusion exposure:(double)exposure
{
	GLsizei width = bounds.size.width,	height = bounds.size.height;
		
	CGLContextObj cgl_ctx = context;
	
	[pluginFBO pushAttributes:cgl_ctx];
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	GLuint tex;
	
	glGenTextures(1, &tex);
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, tex);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	[pluginFBO pushFBO:cgl_ctx];
	[pluginFBO attachFBO:cgl_ctx withTexture:tex width:width height:height];
	
	glColor4f(1.0, 1.0, 1.0, 1.0);
	
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture);
	
	// do not need blending if we use black border for alpha and replace env mode, saves a buffer wipe
	// we can do this since our image draws over the complete surface of the FBO, no pixel goes untouched.
	glDisable(GL_BLEND);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);	
	
	// bind our shader program
	glUseProgramObjectARB([pluginShader programObject]);
	
	// set program vars
	glUniform1iARB([pluginShader getUniformLocation:"tex0"], 0); 
	glUniform1fARB([pluginShader getUniformLocation:"amount"], amount); 
	glUniform1fARB([pluginShader getUniformLocation:"blur"], 0.5); 
	glUniform1fARB([pluginShader getUniformLocation:"exposure"], exposure); 
	glUniform1fARB([pluginShader getUniformLocation:"diffusion"], diffusion * 1000.0); 
	
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
		width,height,
		0.0,height,
		0.0,0.0,
		width,0.0
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