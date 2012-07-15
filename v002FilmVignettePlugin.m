//
//  v002FilmVignettePlugin.m
//  v002FilmEffects
//
//  Created by vade on 12/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "v002FilmVignettePlugin.h"

#define	kQCPlugIn_Name				@"v002 Vignette"
#define	kQCPlugIn_Description		@"Configurable classic film vignetting."


#pragma mark -
#pragma mark Static Functions

static void _TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* info)
{
	glDeleteTextures(1, &name);
}

@implementation v002FilmVignettePlugin

@dynamic inputImage;
@dynamic inputVignetteAmount;
@dynamic inputVignetteEdge;
@dynamic inputVignetteMix;
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
	
	
	if([key isEqualToString:@"inputVignetteAmount"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Vignette Amount", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithFloat:1.0], QCPortAttributeMaximumValueKey,
				nil];
	}
	
	if([key isEqualToString:@"inputVignetteEdge"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Vignette Edge", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.5], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithFloat:1.0], QCPortAttributeMaximumValueKey,
				nil];
	}
	
	if([key isEqualToString:@"inputVignetteMix"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Vignette Size", QCPortAttributeNameKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:0.5], QCPortAttributeDefaultValueKey,
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
	return [NSArray arrayWithObjects:@"inputImage", @"inputVignetteAmount", @"inputVignetteMix", @"inputVignetteEdge", nil];
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
		self.pluginShaderName = @"v002.film-vignette";
	}
	
	return self;
}

@end

@implementation v002FilmVignettePlugin (Execution)

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{	
	CGLContextObj cgl_ctx = [context CGLContextObj];
	CGLLockContext(cgl_ctx);
	
	id<QCPlugInInputImageSource>   image = self.inputImage;
	
	CGColorSpaceRef cspace = ([image shouldColorMatch]) ? [context colorSpace] : [image imageColorSpace];

	if(image && [image lockTextureRepresentationWithColorSpace:cspace forBounds:[image imageBounds]])
	{	
		[image bindTextureRepresentationToCGLContext:[context CGLContextObj] textureUnit:GL_TEXTURE0 normalizeCoordinates:YES];
		
		GLuint finalOutput = [self renderToFBO:cgl_ctx image:image vignette:self.inputVignetteAmount edge:self.inputVignetteEdge mix:self.inputVignetteMix];
		
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

- (GLuint) renderToFBO:(CGLContextObj)cgl_ctx image:(id<QCPlugInInputImageSource>)image vignette:(GLfloat)vignette edge:(GLfloat)edge mix:(GLfloat)mix
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
	
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, [image textureName]);
	
	// do not need blending if we use black border for alpha and replace env mode, saves a buffer wipe
	// we can do this since our image draws over the complete surface of the FBO, no pixel goes untouched.
	glDisable(GL_BLEND);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);	
	
	// bind our shader program
	glUseProgramObjectARB([pluginShader programObject]);
	
	// set program vars
	glUniform1iARB([pluginShader getUniformLocation:"tex0"], 0); // load tex0 sampler to texture unit 0 
	glUniform2fARB([pluginShader getUniformLocation:"dim"], [image imageBounds].size.width, [image imageBounds].size.height); // glsl uniform vars
	glUniform1fARB([pluginShader getUniformLocation:"vignette"], vignette); 
	glUniform1fARB([pluginShader getUniformLocation:"vignetteEdge"], edge); 
	glUniform1fARB([pluginShader getUniformLocation:"vignetteMix"], mix); 
	
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