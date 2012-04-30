//
//  v002FilmLightLeak.h
//  v002FilmEffects
//
//  Created by vade on 12/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "v002MasterPluginInterface.h"

@interface v002FilmLightLeakPlugIn : v002MasterPluginInterface
{
}

@property (assign) id<QCPlugInInputImageSource> inputImage;
@property (assign) id<QCPlugInInputImageSource> inputLeak;
@property (assign) double inputAmount;
@property (assign) double inputLength;
@property (assign) double inputAngle;
@property (assign) id<QCPlugInOutputImageProvider> outputImage;

@end

@interface v002FilmLightLeakPlugIn (Execution)
- (GLuint) renderToFBO:(CGLContextObj)cgl_ctx image:(id<QCPlugInInputImageSource>)image lut:(id<QCPlugInInputImageSource>)lutImage amount:(GLfloat)amount angle:(GLfloat)angle length:(GLfloat)length;
@end
