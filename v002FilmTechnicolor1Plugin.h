
//
//  Created by vade on 7/10/08.
//  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "v002MasterPluginInterface.h"

@interface v002FilmTechnicolor1Plugin : v002MasterPluginInterface
{
}

@property (assign) id<QCPlugInInputImageSource> inputImage;
@property (assign) double inputAmount;
@property (assign) id<QCPlugInOutputImageProvider> outputImage;

@end

@interface v002FilmTechnicolor1Plugin (Execution)
- (GLuint) renderToFBO:(CGLContextObj)context width:(NSUInteger)pixelsWide height:(NSUInteger)pixelsHigh bounds:(NSRect)bounds texture:(GLuint)texture amount:(double)amount;
@end;

