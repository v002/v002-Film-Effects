//
//  v002FilmVignettePlugin.h
//  v002FilmEffects
//
//  Created by vade on 12/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "v002MasterPluginInterface.h"

@interface v002FilmVignettePlugin : v002MasterPluginInterface
{
}

@property (assign) id<QCPlugInInputImageSource> inputImage;
@property (assign) double inputVignetteAmount;
@property (assign) double inputVignetteEdge;
@property (assign) double inputVignetteMix;
@property (assign) id<QCPlugInOutputImageProvider> outputImage;

@end

@interface v002FilmVignettePlugin (Execution)
- (GLuint) renderToFBO:(CGLContextObj)cgl_ctx image:(id<QCPlugInInputImageSource>)image vignette:(GLfloat)vignette edge:(GLfloat)edge mix:(GLfloat)mix;
@end;

