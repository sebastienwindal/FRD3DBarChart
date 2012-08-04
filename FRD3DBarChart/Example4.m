//
//  Example4.m
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


#import "Example4.h"

float gValsRevenue[] = { 
    25.3, 28.37, 32.19, 36.84, 39.79, 44.28, 51.12, 60.42, 58.44, 62.48, 69.94, 73.72, // MSFT
    5.36, 4.74, 6.21, 8.28, 13.93, 19.32, 24.01, 32.48, 36.54, 65.22, 108.25, 148.81, // AAPL
    0.0, 0.43951, 1.47, 3.19, 6.14, 10.6, 16.59, 21.8, 23.65, 29.32, 37.91, 43.16, // GOOG
};


@implementation Example4


-(int) frd3DBarChartViewControllerNumberRows:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 3;
}

-(int) frd3DBarChartViewControllerNumberColumns:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 12;
}

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController valueForBarAtRow:(int)row column:(int)column
{
    return gValsRevenue[row * 12 + column];
}

-(float) frd3DBarChartViewControllerMaxValue:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 150;
}

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController percentSizeForBarAtRow:(int)row column:(int)column
{
    return 0.7;
}

-(NSString *)frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForColumn:(int)column
{
    return [NSString stringWithFormat:@"%d", 2001 + column];
}

-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForRow:(int)row
{
    if (row == 0) return @"Microsoft";
    else if (row == 1) return @"Apple";
    else return @"Google";
}

-(UIColor *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController colorForBarAtRow:(int)row column:(int)column
{
    
    float val = [self frd3DBarChartViewController:frd3DBarChardViewController valueForBarAtRow:row column:column];
    float max = [self frd3DBarChartViewControllerMaxValue:frd3DBarChardViewController];
    
    
    UIColor *color = [UIColor colorWithHue:0.3 + row/6.0 saturation:0.2 + val/max/1.25 brightness:1.0 alpha:1.0];
    return color;
    
}

-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForValueLine:(int)line
{
    float max = [self frd3DBarChartViewControllerMaxValue:frd3DBarChardViewController];
    float delta = max / 5.0;
    
    return [NSString stringWithFormat:@"$%0.1fB", (line + 1) * delta];
}

-(int) frd3DBarChartViewControllerNumberHeightLines:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 5;
}

-(bool) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController hasBarForRow:(int)row column:(int)column
{
    if (row == 2 && column == 0) return false; // no revenue data for Google in 2001 from the financial web site I was using.
    return true;
}
@end
