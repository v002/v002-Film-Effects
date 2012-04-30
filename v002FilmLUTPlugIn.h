//
//  v002LUTPlugIn.h
//  v002LUT
//
//  Created by vade on 9/2/08.
//  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>

#import "v002MasterPluginInterface.h"

@interface v002FilmLUTPlugIn : v002MasterPluginInterface
{
	id outputImageProvider;
}

@property (assign) double inputKnee;
//@property double inputKneeLuma;
@property (assign) CGColorRef inputColor;
@property (assign) id<QCPlugInOutputImageProvider> outputImage;

/*
Declare here the Obj-C 2.0 properties to be used as input and output ports for the plug-in e.g.
@property double inputFoo;
@property(assign) NSString* outputBar;
You can access their values in the appropriate plug-in methods using self.inputFoo or self.inputBar
*/

@end

@interface v002FilmLUTPlugIn (Execution)
- (GLuint) renderToFBO:(CGLContextObj)cgl_ctx bounds:(NSRect)bounds knee:(GLfloat)knee color:(CGColorRef)color;
@end


