//
//  Example1.h
//  removeme
//
//  Created by Sebastien Windal on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRD3DBarChartViewController.h"


typedef enum 
{
    EquationTypeMexicanHatWavelet = 0, // kind of...
    EquationTypePyramid,
    EquationTypeDome,
    EquationTypeSin,
} Example1EquationTypes;

@interface Example1 : NSObject<FRD3DBarChartViewControllerDelegate>

@property (nonatomic) Example1EquationTypes equationType;


@end
