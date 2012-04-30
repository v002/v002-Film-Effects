//
//  v002FilmLomoPlugIn.h
//  v002FilmLomo
//
//  Created by vade on 8/6/08.
//  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "v002MasterPluginInterface.h"

@interface v002FilmLomoPlugIn : v002MasterPluginInterface
{
}

@property (assign) id<QCPlugInInputImageSource> inputImage;
@property (assign) id<QCPlugInInputImageSource> inputLUT;
@property (assign) double inputAmount;
@property (assign) double inputSaturation;
@property (assign) double inputSharpness;
@property (assign) id<QCPlugInOutputImageProvider> outputImage;

@end

@interface v002FilmLomoPlugIn (Execution)
- (GLuint) renderToFBO:(CGLContextObj)cgl_ctx image:(id<QCPlugInInputImageSource>)image lut:(id<QCPlugInInputImageSource>)lutImage amount:(GLfloat)amount sharpness:(GLfloat)sharpness saturation:(GLfloat)saturation;
@end
