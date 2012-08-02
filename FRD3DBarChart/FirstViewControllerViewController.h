//
//  FirstViewControllerViewController.h
//  removeme
//
//  Created by Sebastien Windal on 7/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstViewControllerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *contentView;

- (IBAction)twitterAction:(id)sender;
- (IBAction)facebookAction:(id)sender;

- (IBAction)pyramidAction:(id)sender;
- (IBAction)domeAction:(id)sender;
- (IBAction)mexHatAction:(id)sender;
- (IBAction)sinAction:(id)sender;
- (IBAction)simpleAction:(id)sender;


@end
