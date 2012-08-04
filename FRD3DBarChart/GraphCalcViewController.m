//
//  FirstViewControllerViewController.m
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


#import "GraphCalcViewController.h"
#import "FRD3DBarChartViewController.h"
#import "Example1.h"


@interface GraphCalcViewController ()


@property (nonatomic, strong) Example1 *example1;

@property (nonatomic, strong) FRD3DBarChartViewController *frd3DBarCharVC;
@end

@implementation GraphCalcViewController
@synthesize contentView = _contentView;

@synthesize example1 = _example1;

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

- (IBAction)pyramidAction:(id)sender {
    self.example1.equationType = EquationTypePyramid;
   [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:kUpdateChartOptionsDoNotUpdateLegends];
}

- (IBAction)domeAction:(id)sender {
    self.example1.equationType = EquationTypeDome;
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:kUpdateChartOptionsDoNotUpdateLegends];
}

- (IBAction)mexHatAction:(id)sender {
    self.example1.equationType = EquationTypeMexicanHatWavelet;
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:kUpdateChartOptionsDoNotUpdateLegends];
}

- (IBAction)sinAction:(id)sender {
    self.example1.equationType = EquationTypeSin;
    [self.frd3DBarCharVC updateChartAnimated:YES animationDuration:1.0 options:kUpdateChartOptionsDoNotUpdateLegends];
}


@end
