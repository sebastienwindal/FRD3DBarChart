//
//  Example3.m
//  FRD3DBarChart
//
//  Created by Sebastien Windal on 7/23/12.
//  Copyright (c) 2012 Free Range Developers. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the project's author nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
// TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#import "Example3.h"


float gVals[] = { 1,2,2.1,4.5,4.3,4.2,6,8,9,10, 13, 5.5 };

@implementation Example3
{
    float _max;
}

-(int) frd3DBarChartViewControllerNumberRows:(FRD3DBarChartViewController *)frd3DBarChartViewController
{
    return 1;
}

-(int) frd3DBarChartViewControllerNumberColumns:(FRD3DBarChartViewController *)frd3DBarChartViewController
{
    return 12;
}


-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController valueForBarAtRow:(int)row column:(int)column
{
    return gVals[column%12];
}

-(float) frd3DBarChartViewControllerMaxValue:(FRD3DBarChartViewController *)frd3DBarChartViewController
{
    return _max;
}

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController percentSizeForBarAtRow:(int)row column:(int)column
{
    return 0.7;
}


-(NSString *)frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController legendForColumn:(int)column
{
    NSArray *array = [NSArray arrayWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dev", nil];
    
    return [array objectAtIndex:column%12];
}

-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController legendForRow:(int)row
{
    return @"Sales";
}

-(UIColor *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController colorForBarAtRow:(int)row column:(int)column
{
    int quarter = (int)((column % 12 )/ 3.0);
    
    UIColor *color = [UIColor colorWithHue:0.2 + quarter / 8.0 saturation:1.0 brightness:1.0 alpha:1.0];
    return color;
    
}

-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController legendForValueLine:(int)line
{
    return [NSString stringWithFormat:@"$%d.0B", line + 1];
}

-(int) frd3DBarChartViewControllerNumberHeightLines:(FRD3DBarChartViewController *)frd3DBarChartViewController
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
