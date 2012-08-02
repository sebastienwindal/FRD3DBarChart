//
//  ViewController.h
//  removeme
//
//  Created by Sebastien Windal on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


@class FRD3DBarChartViewController;

@protocol FRD3DBarChartViewControllerDelegate <NSObject>

@required

// number of rows to display in the chart.
-(int) frd3DBarChartViewControllerNumberRows:(FRD3DBarChartViewController *) frd3DBarChardViewController;
// number of columns to display in the chart
-(int) frd3DBarChartViewControllerNumberColumns:(FRD3DBarChartViewController *) frd3DBarChardViewController;
// maximum value (height of the bar). Heights are normalized using this value.
-(float) frd3DBarChartViewControllerMaxValue:(FRD3DBarChartViewController *) frd3DBarChardViewController;
// value (height) of a bar in the chart
-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController valueForBarAtRow:(int)row column:(int)column;


@optional

// indicates if there is a bar on a row/column. Return false here is different that returning false on
// frd3DBarChartViewController:valueForBarAtRow:column, the latter will render acolored square
// with no height, the former will result in an empty cell on the grid.
-(bool) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController hasBarForRow:(int)row column:(int) column;
// strings to be displayed on the left side of the grid. Return nil to skip the legend for a row.
-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForRow:(int) row;
// strings to be displayed on the front side of the grid. Return nil to skip the legend for a column.
-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForColumn:(int) column;
// strings to be displayed on the frobackground side of the chart, next to the heighe lines.
-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForValueLine:(int) line;

// color of the bars.
-(UIColor *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController colorForBarAtRow:(int)row column:(int) column ;
// the size of the bar as a percentage of the square in the grid. Return 1.0 to make the bar occupy the whole square.
// best-looking results will be obtained by returning values between 0.8 and 1.0.
-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *) frd3DBarChardViewController percentSizeForBarAtRow:(int) row column:(int) column;
// the font name to use in the row chart legend. 
-(NSString *) frd3DBarChartViewControllerRowLegendFontName:(FRD3DBarChartViewController *)frd3DBarChardViewController;
// the font name to use in the column chart legend. 
-(NSString *) frd3DBarChartViewControllerColumnLegendFontName:(FRD3DBarChartViewController *)frd3DBarChardViewController;
// font name to be used in the height values in background pane
-(NSString *) frd3DBarChartViewControllerValueLegendFontName:(FRD3DBarChartViewController *)frd3DBarChardViewController;
// the color to use in the row chart legend (default white)
-(UIColor *) frd3DBarChartViewControllerRowLegendColor:(FRD3DBarChartViewController *)frd3DBarChardViewController;
// the color to use in the column chart legend. (default is white)
-(UIColor *) frd3DBarChartViewControllerColumnLegendColor:(FRD3DBarChartViewController *)frd3DBarChardViewController;
// the color to use for the height value lables in the background pane.
-(UIColor *) frd3DBarChartViewControllerValueLegendColor:(FRD3DBarChartViewController *)frd3DBarChardViewController;
// the number of lines to dsplay in the background grid plane.
-(int) frd3DBarChartViewControllerNumberHeightLines:(FRD3DBarChartViewController *)frd3DBarChardViewController;

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

-(void) updateChartAnimated:(BOOL) animated animationDuration:(NSTimeInterval)duration options:(kUpdateChartOptions)options;

@end
