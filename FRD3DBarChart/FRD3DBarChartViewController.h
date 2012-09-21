//
//  FRD3DBarChartViewController.h
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

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


@class FRD3DBarChartViewController;

@protocol FRD3DBarChartViewControllerDelegate <NSObject>

@required

// number of rows to display in the chart.
-(int) frd3DBarChartViewControllerNumberRows:(FRD3DBarChartViewController *) frd3DBarChartViewController;
// number of columns to display in the chart
-(int) frd3DBarChartViewControllerNumberColumns:(FRD3DBarChartViewController *) frd3DBarChartViewController;
// maximum value (height of the bar). Heights are normalized using this value.
-(float) frd3DBarChartViewControllerMaxValue:(FRD3DBarChartViewController *) frd3DBarChartViewController;
// value (height) of a bar in the chart
-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController valueForBarAtRow:(int)row column:(int)column;


@optional

// indicates if there is a bar on a row/column. Return false here is different that returning false on
// frd3DBarChartViewController:valueForBarAtRow:column, the latter will render acolored square
// with no height, the former will result in an empty cell on the grid.
-(bool) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController hasBarForRow:(int)row column:(int) column;
// strings to be displayed on the left side of the grid. Return nil to skip the legend for a row.
-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController legendForRow:(int) row;
// strings to be displayed on the front side of the grid. Return nil to skip the legend for a column.
-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController legendForColumn:(int) column;
// strings to be displayed on the frobackground side of the chart, next to the height lines.
-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController legendForValueLine:(int) line;

// color of the bars.
-(UIColor *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController colorForBarAtRow:(int)row column:(int) column ;
// the size of the bar as a percentage of the square in the grid. Return 1.0 to make the bar occupy the whole square.
// best-looking results will be obtained by returning values between 0.8 and 1.0.
-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *) frd3DBarChartViewController percentSizeForBarAtRow:(int) row column:(int) column;

// enabled text label on top of the bars.
-(BOOL) frd3DBarChartViewControllerHasTopText:(FRD3DBarChartViewController *)frd3DBarChartViewController;
// optional text to put on top of the bar
-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController topTextForBarAtRow:(int)row column:(int) column;
// optional font for the  text on top of the bar (default is Helvetica)
-(NSString *) frd3DBarChartViewControllerTopTextFontName:(FRD3DBarChartViewController *)frd3DBarChartViewController;
// optional text color for the top bar text (default is white)
-(UIColor *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChartViewController colorForTopTextBarAtRow:(int)row column:(int) column;


// the font name to use in the row chart legend. 
-(NSString *) frd3DBarChartViewControllerRowLegendFontName:(FRD3DBarChartViewController *)frd3DBarChartViewController;
// the font name to use in the column chart legend. 
-(NSString *) frd3DBarChartViewControllerColumnLegendFontName:(FRD3DBarChartViewController *)frd3DBarChartViewController;
// font name to be used in the height values in background pane
-(NSString *) frd3DBarChartViewControllerValueLegendFontName:(FRD3DBarChartViewController *)frd3DBarChartViewController;
// the color to use in the row chart legend (default white)
-(UIColor *) frd3DBarChartViewControllerRowLegendColor:(FRD3DBarChartViewController *)frd3DBarChartViewController;
// the color to use in the column chart legend. (default is white)
-(UIColor *) frd3DBarChartViewControllerColumnLegendColor:(FRD3DBarChartViewController *)frd3DBarChartViewController;
// the color to use for the height value labels in the background pane.
-(UIColor *) frd3DBarChartViewControllerValueLegendColor:(FRD3DBarChartViewController *)frd3DBarChartViewController;
// the number of lines to dsplay in the background grid plane.
-(int) frd3DBarChartViewControllerNumberHeightLines:(FRD3DBarChartViewController *)frd3DBarChartViewController;

@end

enum
{
    kUpdateChartOptionsDoNotUpdateRowLegend         = 1 <<  0,
    kUpdateChartOptionsDoNotUpdateColumnLegend      = 1 <<  1,
    kUpdateChartOptionsDoNotUpdateValueLegend       = 1 <<  2,
    kUpdateChartOptionsDoNotUpdateLegends           = 7,
} ;
typedef NSUInteger kUpdateChartOptions;

@interface FRD3DBarChartViewController : GLKViewController

@property (nonatomic, strong) id<FRD3DBarChartViewControllerDelegate> frd3dBarChartDelegate;
@property (nonatomic) BOOL useCylinders;

-(void) updateChartAnimated:(BOOL) animated animationDuration:(NSTimeInterval)duration options:(kUpdateChartOptions)options;

@end
