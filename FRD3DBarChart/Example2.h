//
//  Example2.h
//  removeme
//
//  Created by Sebastien Windal on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRD3DBarChartViewController.h"

typedef enum {
    kExample2DataSetTwitter,
    kExample2DataSetFacebook,
} kExample2DataSets;

@interface Example2 : NSObject<FRD3DBarChartViewControllerDelegate>

-(void) setDataSet:(kExample2DataSets) dataSet;

@end
