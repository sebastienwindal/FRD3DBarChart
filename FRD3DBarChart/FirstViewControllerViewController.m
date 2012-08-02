//
//  FirstViewControllerViewController.m
//  removeme
//
//  Created by Sebastien Windal on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FirstViewControllerViewController.h"
#import "FRD3DBarChartViewController.h"
#import "Example1.h"
#import "Example2.h"
#import "Example3.h"

@interface FirstViewControllerViewController ()


@property (nonatomic, strong) Example1 *example1;
@property (nonatomic, strong) Example2 *example2;
@property (nonatomic, strong) Example3 *example3;
@property (nonatomic, strong) FRD3DBarChartViewController *frd3DBarCharVC;
@end

@implementation FirstViewControllerViewController
@synthesize contentView = _contentView;

@synthesize example1 = _example1;
@synthesize example2 = _example2;
@synthesize example3 = _example3;

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
    self.example1 = [[Example1 alloc] init];
    self.example2 = [[Example2 alloc] init];
    self.example3 = [[Example3 alloc] init];
    
    UIStoryboard *storyboard = self.storyboard;
    self.frd3DBarCharVC = [storyboard instantiateViewControllerWithIdentifier:@"FRD3DBarChart"];
    
    
    [self addChildViewController:self.frd3DBarCharVC];
    self.frd3DBarCharVC.frd3dBarChartDelegate = self.example1;
    
    [self.contentView addSubview:self.frd3DBarCharVC.view];
    
    [self.frd3DBarCharVC updateChartAnimated:NO animationDuration:0.0 options:0];
}

- (void)viewDidUnload
{
    [self setContentView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:0];
}
- (IBAction)twitterAction:(id)sender 
{
    [self.example2 setDataSet:kExample2DataSetTwitter];
    kUpdateChartOptions options = (self.frd3DBarCharVC.frd3dBarChartDelegate == self.example2) ? kUpdateChartOptionsDoNotUpdateLegends : 0;
    self.frd3DBarCharVC.frd3dBarChartDelegate = self.example2;
    
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:0.7 options:options];
}

- (IBAction)facebookAction:(id)sender 
{
    [self.example2 setDataSet:kExample2DataSetFacebook];
    kUpdateChartOptions options = (self.frd3DBarCharVC.frd3dBarChartDelegate == self.example2) ? kUpdateChartOptionsDoNotUpdateLegends : 0;
    self.frd3DBarCharVC.frd3dBarChartDelegate = self.example2;
    
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:0.7 options:options];
}

- (IBAction)pyramidAction:(id)sender {
    self.example1.equationType = EquationTypePyramid;
    kUpdateChartOptions options = (self.frd3DBarCharVC.frd3dBarChartDelegate == self.example1) ? kUpdateChartOptionsDoNotUpdateLegends : 0;
    self.frd3DBarCharVC.frd3dBarChartDelegate = self.example1;
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:options];
}

- (IBAction)domeAction:(id)sender {
    self.example1.equationType = EquationTypeDome;
    kUpdateChartOptions options = (self.frd3DBarCharVC.frd3dBarChartDelegate == self.example1) ? kUpdateChartOptionsDoNotUpdateLegends : 0;
    self.frd3DBarCharVC.frd3dBarChartDelegate = self.example1;
    
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:options];
}

- (IBAction)mexHatAction:(id)sender {
    self.example1.equationType = EquationTypeMexicanHatWavelet;
    kUpdateChartOptions options = (self.frd3DBarCharVC.frd3dBarChartDelegate == self.example1) ? kUpdateChartOptionsDoNotUpdateLegends : 0;
    self.frd3DBarCharVC.frd3dBarChartDelegate = self.example1;
    
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:options];
}

- (IBAction)sinAction:(id)sender {
    self.example1.equationType = EquationTypeSin;
    kUpdateChartOptions options = (self.frd3DBarCharVC.frd3dBarChartDelegate == self.example1) ? kUpdateChartOptionsDoNotUpdateLegends : 0;
    self.frd3DBarCharVC.frd3dBarChartDelegate = self.example1;
    
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:options];
}

- (IBAction)simpleAction:(id)sender {
    
    kUpdateChartOptions options = (self.frd3DBarCharVC.frd3dBarChartDelegate == self.example3) ? kUpdateChartOptionsDoNotUpdateLegends : 0;
    [self.example3 regenerateValues];
    self.frd3DBarCharVC.frd3dBarChartDelegate = self.example3;
    
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:options];
}


@end
