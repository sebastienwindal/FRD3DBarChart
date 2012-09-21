//
//  Example1.m
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


#import "Example1.h"

@implementation Example1
{
    int runCount; 
}

@synthesize equationType = _equationType;


#pragma mark FRD3DBarChartViewControllerDelegate implementation

#define SIZE 26
#define HALF_SIZE (SIZE / 2)

-(int) frd3DBarChartViewControllerNumberRows:(FRD3DBarChartViewController *)frd3DBarChartViewController
{
    return SIZE;
}

-(int) frd3DBarChartViewControllerNumberColumns:(FRD3DBarChartViewController *)frd3DBarChartViewController
{
    return SIZE;  
}
-(float) frd3DBarChartViewControllerMaxValue:(FRD3DBarChartViewController *)frd3DBarChartViewController
{
    return 1.0f;
}

-(void) setEquationType:(Example1EquationTypes)equationType
{
    runCount ++;
    _equationType = equationType;
    
}

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController valueForBarAtRow:(int)row column:(int)column
{
    // "centered" coordinatess
    float x = row - [self frd3DBarChartViewControllerNumberRows:frd3DBarChartViewController]/2.0;
    float y = column - [self frd3DBarChartViewControllerNumberColumns:frd3DBarChartViewController]/2.0;
    
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


/* uncomment to add text to bars:

-(BOOL) frd3DBarChartViewControllerHasTopText:(FRD3DBarChartViewController *)frd3DBarChartViewController {
    return YES;
}

-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController topTextForBarAtRow:(int)row column:(int)column
{
    int ascii = 65 + (row * SIZE + column) % 26;
    return [NSString stringWithFormat:@"%c", ascii];
}

-(NSString *) frd3DBarChartViewControllerTopTextFontName:frd3DBarChartViewController
{
    //return @"Zapfino";
    return @"AmericanTypewriter-Bold";
}

*/


-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController legendForRow:(int)row
{
    if ((row-HALF_SIZE) % 5 != 0) return nil;
    
    return [NSString stringWithFormat:@"%d", row - HALF_SIZE];
}


-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController legendForColumn:(int)column
{
    if ((column-HALF_SIZE) % 5 != 0) return nil;
    
    return [NSString stringWithFormat:@"%d", column - HALF_SIZE];
}

-(UIColor *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController colorForBarAtRow:(int)row column:(int)column
{
    float v = [self frd3DBarChartViewController:frd3DBarChartViewController valueForBarAtRow:row column:column];
    
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

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController percentSizeForBarAtRow:(int)row column:(int)column
{
    return 0.9;
}



@end
