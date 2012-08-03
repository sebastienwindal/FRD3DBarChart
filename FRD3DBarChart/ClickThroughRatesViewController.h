//
//  ClickThroughRatesViewController.h
//  FRD3DBarChart
//
//  Created by Sebastien Windal on 8/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


@interface ClickThroughRatesViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet GLKView *chartView;

- (IBAction)facebookAction:(id)sender;
- (IBAction)twitterAction:(id)sender;
@end
