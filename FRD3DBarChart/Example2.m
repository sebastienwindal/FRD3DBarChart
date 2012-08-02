//
//  Example2.m
//  removeme
//
//  Created by Sebastien Windal on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


float gValsTwitter[7*24] = {
    216, 232, 225, 223, 230, 228, 202, 193, 142, 124, 112, 74, 57, 69, 40, 62, 45, 75, 68, 71, 84, 91, 113, 170,
    206, 224, 218, 228, 229, 222, 217, 202, 153, 127, 103, 69, 69, 77, 62, 45, 49, 68, 71, 79, 84, 85, 114, 176,
    184, 219, 223, 227, 227, 218, 218, 206, 159, 141, 119, 84, 74, 55, 56, 55, 59, 59, 51, 56, 79, 89, 106, 147,
    203, 232, 224, 224, 224, 224, 217, 202, 158, 134, 105, 89, 71, 64, 70, 74, 67, 67, 117, 83, 86, 129, 122, 153,
    210, 230, 226, 231, 234, 221, 221, 212, 173, 145, 145, 103, 98, 71, 72, 77, 104, 104, 98, 108, 125, 152, 188, 184,
    225, 237, 240, 247, 250, 244, 242, 230, 229, 216, 216, 194, 202, 181, 191, 181, 190, 190, 164, 67, 196, 201, 199, 212,
    227, 242, 239, 240, 239, 241, 241, 229, 222, 206, 206, 190, 170, 180, 180, 173, 149, 148, 131, 84, 139, 139, 159, 164 };

float gValsFacebook[7*24] = {
    237, 244, 228, 217, 191, 206, 211, 208, 191, 201, 183, 104, 113,  84, 117, 127,  66, 134, 149, 187, 220, 236, 230, 241,
    226, 221, 241, 194, 167, 203, 204, 213, 203, 188, 180, 147, 112, 116,  73, 150,  78, 140, 164,  84, 217, 226, 217, 236,
    226, 230, 224, 206, 191, 203, 210, 205, 183, 191, 186, 145, 161,  71, 104, 111, 105, 115, 124, 173, 215, 216, 231, 213,
    235, 236, 233, 195, 186, 205, 229, 203, 205, 175, 181, 154, 139,  77, 104,  41,  97, 160, 177, 142, 216, 218, 191, 221,
    250, 239, 236, 206, 160, 191, 219, 206, 210, 173, 156, 113, 152,  76,  70,  87, 111,  86, 159, 210, 221, 228, 225, 236,
    238, 246, 234, 201, 210, 199, 217, 221, 216, 214, 210, 178, 204, 135, 143, 186, 145, 175, 186, 188, 236, 224, 237, 250,
    233, 248, 223, 193, 170, 214, 199, 214, 222, 196, 193, 199, 188, 164, 185, 181, 175, 217, 213, 214, 221, 218, 207, 230,
};



#import "Example2.h"

@implementation Example2
{
    float *gvals;
}

-(void) setDataSet:(kExample2DataSets) dataSet
{
    if (dataSet == kExample2DataSetTwitter)
    {
        gvals = gValsTwitter;
    }
    else 
    {
        gvals = gValsFacebook;
    }
}

-(id) init
{
    self = [super init];
    if (self)
    {
        gvals = gValsTwitter;
    }
    return self;
}


#pragma mark FRD3DBarChartViewControllerDelegate implementation

-(int) frd3DBarChartViewControllerNumberRows:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 7;
}

-(int) frd3DBarChartViewControllerNumberColumns:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 24;  
}

-(float) frd3DBarChartViewControllerMaxValue:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return 256.0f;
}

-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController valueForBarAtRow:(int)row column:(int)column
{
    return 256.0f - gvals[row * 24 + column];
}

-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForRow:(int)row
{
    switch (row) {
        case 0:
            return @"Mon";
            break;
        case 1:
            return @"Tue";
            break;
        case 2:
            return @"Wed";
            break;
        case 3:
            return @"Thu";
            break;
        case 4:
            return @"Fri";
            break;
        case 5:
            return @"Sat";
            break;
        case 6:
            return @"Sun";
            break;
        default:
            return @"";
            break;
    }
}


-(float) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController percentSizeForBarAtRow:(int)row column:(int)column
{
    return 1.0;
}


-(NSString *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController legendForColumn:(int)column
{
    if (column % 2) return nil;
    
    int hour = column % 12;
    if (hour == 0) hour = 12;
    return [NSString stringWithFormat:@"%d %@", hour, (column <12) ? @"am" : @"pm"];
    
}

-(UIColor *) frd3DBarChartViewController:(FRD3DBarChartViewController *)frd3DBarChardViewController colorForBarAtRow:(int)row column:(int)column
{
    
    float val = gvals[row * 24 + column];
    //float b = 0.5 + (1-(val * val)/256.0/256) / 2.0;
    float b2 = 1.1 * (1-(val * val)/256.0/256) ;
    //return [UIColor colorWithHue:1.0 saturation:1.0 brightness:b alpha:1.0];
    float darkb2 = 10*b2;
    if (darkb2 < 0.8) darkb2 = 0.8;
    return [UIColor colorWithRed:darkb2 green:b2 blue:b2 alpha:1.0];
    
}

-(NSString *) frd3DBarChartViewControllerColumnLegendFontName:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return @"Verdana-Italic";
}

-(NSString *) frd3DBarChartViewControllerRowLegendFontName:(FRD3DBarChartViewController *)frd3DBarChardViewController
{
    return @"Verdana-Bold";
}



@end
