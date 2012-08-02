//
//  Example3.m
//  removeme
//
//  Created by Sebastien Windal on 8/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Example3.h"


float gVals[] = { 1,2,2.1,4.5,4.3,4.2,6,8,9,10, 13, 5.5 };

@implementation Example3
{
    float _max;
}

-(int) frd3DBarChartViewControllerNumberRows:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 1;
}

-(int) frd3DBarChartViewControllerNumberColumns:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 12;
}

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController valueForBarAtRow:(int)row column:(int)column
{
    return gVals[column%12];
}

-(float) frd3DBarChartViewControllerMaxValue:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return _max;
}

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController percentSizeForBarAtRow:(int)row column:(int)column
{
    return 0.7;
}

-(NSString *)frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForColumn:(int)column
{
    NSArray *array = [NSArray arrayWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dev", nil];
    
    return [array objectAtIndex:column%12];
}

-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForRow:(int)row
{
    return @"Sales";
}

-(UIColor *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController colorForBarAtRow:(int)row column:(int)column
{
    int quarter = (int)((column % 12 )/ 3.0);
    
    UIColor *color = [UIColor colorWithHue:0.2 + quarter / 8.0 saturation:1.0 brightness:1.0 alpha:1.0];
    return color;
    
}

-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForValueLine:(int)line
{
    return [NSString stringWithFormat:@"$%d.0B", line + 1];
}

-(int) frd3DBarChartViewControllerNumberHeightLines:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 5;
}

-(void) regenerateValues
{
    _max = 0.0;
    gVals[0] = 0.0;
    for (int i=1; i<12; i++)
    {
        gVals[i] = 0.5 + (arc4random() % 100000) / 10000;
        _max = MAX(_max, gVals[i]);
    }
}

@end
