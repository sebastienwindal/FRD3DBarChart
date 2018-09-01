//
//  ClickThroughRatesViewController.m
//  FRD3DBarChart
//
//  Created by Sebastien Windal on 8/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ClickThroughRatesViewController.h"
#import "FRD3DBarChartViewController.h"
#import "Example2.h"

@interface ClickThroughRatesViewController ()

@property (nonatomic,strong) Example2 *example;
@property (nonatomic, strong) FRD3DBarChartViewController *frd3DBarCharVC;
@end

@implementation ClickThroughRatesViewController
@synthesize contentView;
@synthesize chartView;
@synthesize example = _example;
@synthesize frd3DBarCharVC = _frd3DBarCharVC;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIStoryboard *storyboard = self.storyboard;
    self.frd3DBarCharVC = [storyboard instantiateViewControllerWithIdentifier:@"FRD3DBarChart"];
    
    self.example = [[Example2 alloc] init];
    self.example.dataSet = kExample2DataSetFacebook;
    
    [self addChildViewController:self.frd3DBarCharVC];
    self.frd3DBarCharVC.frd3dBarChartDelegate = self.example;
    
    [self.contentView addSubview:self.frd3DBarCharVC.view];
    
    [self.frd3DBarCharVC updateChartAnimated:NO animationDuration:0.0 options:0];
    
    [self addChildViewController:self.frd3DBarCharVC];
}

- (IBAction)facebookAction:(id)sender {
    [self.example setDataSet:kExample2DataSetFacebook];
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:kUpdateChartOptionsDoNotUpdateLegends];
}

- (IBAction)twitterAction:(id)sender {
    [self.example setDataSet:kExample2DataSetTwitter];
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:kUpdateChartOptionsDoNotUpdateLegends];
}

@end
