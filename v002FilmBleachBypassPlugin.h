
//
//  Created by vade on 7/10/08.
//  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "v002MasterPluginInterface.h"

@interface v002FilmBleachBypassPlugin : v002MasterPluginInterface
{
//	GLuint quadDisplayList;
//	BOOL madeDisplayList;
}


@property (assign) id<QCPlugInInputImageSource> inputImage;
@property (assign) double inputAmount;
@property (assign) id<QCPlugInOutputImageProvider> outputImage;


@end

@interface v002FilmBleachBypassPlugin (Execution)
- (GLuint) renderToFBO:(CGLContextObj)context width:(NSUInteger)pixelsWide height:(NSUInteger)pixelsHigh bounds:(NSRect)bounds texture:(GLuint)texture amount:(double)amount;
@end;

