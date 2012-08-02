//
//  Example1.m
//  removeme
//
//  Created by Sebastien Windal on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Example1.h"

@implementation Example1
{
    int runCount; 
}

@synthesize equationType = _equationType;


#pragma mark FRD3DBarChartViewControllerDelegate implementation

#define SIZE 40
#define HALF_SIZE (SIZE / 2)

-(int) frd3DBarChartViewControllerNumberRows:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return SIZE;
}

-(int) frd3DBarChartViewControllerNumberColumns:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return SIZE;  
}
-(float) frd3DBarChartViewControllerMaxValue:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 1.0f;
}

-(void) setEquationType:(Example1EquationTypes)equationType
{
    runCount ++;
    _equationType = equationType;
    
}

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController valueForBarAtRow:(int)row column:(int)column
{
    // "centered" coordinatess
    float x = row - [self frd3DBarChartViewControllerNumberRows:frd3DBarChardViewController]/2.0;
    float y = column - [self frd3DBarChartViewControllerNumberColumns:frd3DBarChardViewController]/2.0;
    
    // distance from center:
    float d = sqrtf(x*x + y*y);
    float maxDistance = sqrt(HALF_SIZE*HALF_SIZE+HALF_SIZE*HALF_SIZE);
    
    double v;
    if (self.equationType == EquationTypeMexicanHatWavelet)
        v = 0.75 * (1.0 + cosf(d*0.7) / 2.0) / exp((d-2)/20.0);
    else if (self.equationType == EquationTypePyramid)
    {
        float xx = x > 0 ? x : -x;
        float yy = y > 0 ? y : -y;
        
        float mm = MAX(xx,yy);
        
        v = 1.01 - mm/HALF_SIZE;
    }
    else if (self.equationType == EquationTypeDome)
        v = 0.01 + cosf(0.5 * M_PI * d/maxDistance);
    else if (self.equationType == EquationTypeSin)
        v = 0.29 + sinf(x/1.0 - runCount * M_PI/2.0) / 11;
    
    return v * (0.8 + cos(runCount)/5.0);
}

-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForRow:(int)row
{
    if ((row-HALF_SIZE) % 5 != 0) return nil;
    
    return [NSString stringWithFormat:@"%d", row - HALF_SIZE];
}


-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForColumn:(int)column
{
    if ((column-HALF_SIZE) % 5 != 0) return nil;
    
    return [NSString stringWithFormat:@"%d", column - HALF_SIZE];
}

-(UIColor *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController colorForBarAtRow:(int)row column:(int)column
{
    float v = [self frd3DBarChartViewController:frd3DBarChardViewController valueForBarAtRow:row column:column];
    
    // "centered" coordinatess
    float x = row - HALF_SIZE;
    float y = column - HALF_SIZE;

    // distance from center:
    float d = sqrtf(x*x + y*y);
    
    // angle...
    float angle = 0.0;
    if (d != 0)
    {
        angle = acosf(x/d); // between -PI and PI...
        angle = 0.25 * angle / M_PI;
    }
    float maxDistance = sqrt(HALF_SIZE*HALF_SIZE + HALF_SIZE*HALF_SIZE);
    UIColor *color = [UIColor colorWithHue:angle saturation:1-0.5 * d/maxDistance brightness:0.75 + cos(v)/4.0 alpha:1.0];
    return color;
}

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController percentSizeForBarAtRow:(int)row column:(int)column
{
    return 0.9;
}



@end
