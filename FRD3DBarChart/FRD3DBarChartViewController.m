//
//  ViewController.m
//  removeme
//
//  Created by Sebastien Windal on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FRD3DBarChartViewController.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/CoreAnimation.h>
#import <QuartzCore/QuartzCore.h>
#import "FRD3DBarChartViewController+Easing.h"
#import "Shapes.h"


@interface FRD3DBarChartViewController () {

    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    // bunch of variable openGL needs.
    GLuint _vertexArray;
    GLuint _vertexArrayHLine;
    GLuint _vertexArrayVLine;
    GLuint _vertexArrayBasePlane;
    GLuint _vertexLeftLegendPlane;
    GLuint _vertexBuffer;
    GLuint _vertexBuffer2;
    GLuint _vertexBuffer3;
    GLuint _vertexBuffer4;
    GLuint _vertexBuffer5;
    
    // current x and y offset (modified by panning) and radius scale (modified by pinching). 
    float _offsetX;
    float _offsetY;
    float _radiusScale;
    // variables to support animation of position and zoom
    float _targetOffsetY;
    float _offsetYAnimationDelta;
    float _targetOffsetX;
    float _offsetXAnimationDelta;
    float _targetRadiusScale;
    float _radiusScaleAnimationDelta;
    
    // array of target value for bar heights
    float *_targetBarHeights;
    // array of bar heights values. When height animation is over, values in 
    // _currentBarHeights and _targetBarHeights are identical.
    float *_currentBarHeights;
    // array of deltas between values in _currentBarHeights and _targetBarHeights, saved right at the beginning
    // of the animation. Used by easing function to compute intermediary values between _currentBarHeights[x] and _targetBarHeights[x]
    float *_barHeightAnimationDeltas;
    
    // array to support bar color animation
    float *_targetColors;
    float *_currentColors;
    float *_colorDeltas;
    
    // when animating bar heights (or color) the date at which the animation should complete.
    // Used with _barHeightsAnimationStartDate by the easing function to compute intermediary
    // values between start and target values for bar heights and color.
    NSDate *_barHeightAnimationCompletionDate;
    NSDate *_barHeightsAnimationStartDate; // bar animation start date.
    
    // same as above to compute intermediary values when animating position (offsetX, offsetY and radiusScale).
    NSDate *_positionAnimationCompletionDate;
    NSDate *_positionAnimationStartDate;
    
    // flags to indicate if we are animating bar heights or position/zoom.
    BOOL _isAnimatingBarHeights;
    BOOL _isAnimatingPosition;
    
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (nonatomic, strong) GLKTextureInfo *texture;
@property (nonatomic, strong) NSMutableDictionary *rowLegendTextures;
@property (nonatomic, strong) NSMutableDictionary *columnLegendTextures;
@property (nonatomic, strong) NSMutableDictionary *valueLegendTextures;

@property (nonatomic) float radiusScale;
@property (nonatomic) float offsetX;
@property (nonatomic) float offsetY;

- (void)setupGL;
- (void)tearDownGL;


@end

@implementation FRD3DBarChartViewController

@synthesize context = _context;
@synthesize effect = _effect;
@synthesize texture = _texture;
@synthesize rowLegendTextures = _rowLegendTextures;
@synthesize columnLegendTextures = _columnLegendTextures;
@synthesize valueLegendTextures = _valueLegendTextures;
@synthesize radiusScale = _radiusScale;
@synthesize offsetX = _offsetX;
@synthesize offsetY = _offsetY;

@synthesize frd3dBarChartDelegate = _frd3dBarChartDelegate;


//
// to be called to trigger the chart height and color to change.
//
-(void) updateChartAnimated:(BOOL)animated animationDuration:(NSTimeInterval)duration options:(kUpdateChartOptions)options
{
    // make legend images regenerate themselved in the next drawing cycle
    if ((options & kUpdateChartOptionsDoNotUpdateRowLegend) == 0)
    {
        self.rowLegendTextures = nil;
    }
    if ((options & kUpdateChartOptionsDoNotUpdateColumnLegend) == 0)
    {
        self.columnLegendTextures = nil;
    }
    if ((options & kUpdateChartOptionsDoNotUpdateValueLegend) == 0)
    {
        self.valueLegendTextures = nil;
    }
    
    float max = [self.frd3dBarChartDelegate frd3DBarChartViewControllerMaxValue:self];
    
    // copy the values over our target heights array...
    int k=0;
    for (int i=0; i<[self numberRows]; i++)
    {
        for (int j=0; j<[self numberColumns]; j++)
        {
            float value = [self.frd3dBarChartDelegate frd3DBarChartViewController:self valueForBarAtRow:i column:j];
            
            _targetBarHeights[k] = value / max;
            _barHeightAnimationDeltas[k] = _targetBarHeights[k] - _currentBarHeights[k];
            
            
            UIColor *color = [self colorForRow:i column:j];
            float r,g,b,a;
            [color getRed:&r green:&g blue:&b alpha:&a];
            _targetColors[4*k+0] = r;
            _targetColors[4*k+1] = g;
            _targetColors[4*k+2] = b;
            _targetColors[4*k+3] = a;
            _colorDeltas[4*k+0] = _targetColors[4*k+0] - _currentColors[4*k+0];
            _colorDeltas[4*k+1] = _targetColors[4*k+1] - _currentColors[4*k+1];
            _colorDeltas[4*k+2] = _targetColors[4*k+2] - _currentColors[4*k+2];
            _colorDeltas[4*k+3] = _targetColors[4*k+3] - _currentColors[4*k+3];
            k++;
        }
    }
    
    if (!animated)
    {
        for (k=0; k<[self numberRows]*[self numberColumns]; k++)
        {
            _currentBarHeights[k] = _targetBarHeights[k];
            _barHeightAnimationDeltas[k] = 0.0f;
        }
        _barHeightAnimationCompletionDate = [NSDate date];
    }
    else
    {
        _barHeightsAnimationStartDate = [NSDate date];
        _barHeightAnimationCompletionDate = [NSDate dateWithTimeIntervalSinceNow:duration];
        _isAnimatingBarHeights = YES;
    }
}

#pragma mark - legend (chart labels) texture routines

-(void) setValueLegendTextures:(NSMutableDictionary *)valueLegendTextures
{
    if (valueLegendTextures != _valueLegendTextures)
    {
        // problem with texture is they are not freed on their own since they are retained by GL.
        for (NSNumber *number in [_valueLegendTextures keyEnumerator])
        {
            GLKTextureInfo *text = [_valueLegendTextures objectForKey:number];
            GLuint name = text.name;
            glDeleteTextures(1, &name);
        }
        // now we have cleaned up everything we can override the dictionary.
        _valueLegendTextures = valueLegendTextures;
    }
}


-(void) setColumnLegendTextures:(NSMutableDictionary *)columnLegendTextures
{
    if (columnLegendTextures != _columnLegendTextures)
    {
        // problem with texture is they are not freed on their own since they are retained by GL.
        for (NSNumber *number in [_columnLegendTextures keyEnumerator])
        {
            GLKTextureInfo *text = [_columnLegendTextures objectForKey:number];
            GLuint name = text.name;
            glDeleteTextures(1, &name);
        }
        // now we have cleaned up everything we can override the dictionary.
        _columnLegendTextures = columnLegendTextures;
    }
}

-(void) setRowLegendTextures:(NSMutableDictionary *)rowLegendTextures
{
    if (rowLegendTextures != _rowLegendTextures)
    {
        // problem with texture is they are not freed on their own since they are retained by GL.
        for (NSNumber *number in [_rowLegendTextures keyEnumerator])
        {
            GLKTextureInfo *text = [_rowLegendTextures objectForKey:number];
            GLuint name = text.name;
            glDeleteTextures(1, &name);
        }
        // now we have cleaned up everything we can override the dictionary.
        _rowLegendTextures = rowLegendTextures;
    }
}


// lazy loading of value label textures
-(NSMutableDictionary *) valueLegendTextures
{
    if (_valueLegendTextures == nil)
    {
        _valueLegendTextures = [[NSMutableDictionary alloc] init];
        for (int i=0; i<[self numberValueLines]; i++)
        {
            if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewController:legendForValueLine:)])
            {
                NSString *legendText = [self.frd3dBarChartDelegate frd3DBarChartViewController:self legendForValueLine:i];
                if ([legendText length] > 0)
                {
                    UIImage *image = [self imageWithText:legendText
                                                fontName:[self valueLegendFont] 
                                                   color:[self colorForValueLabels]
                                                   width:300.0 
                                                  height:100.0
                                              rightAlign:YES];
                    NSError *error = nil;
                    GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:nil error:&error];
                    if (error == nil)
                    {
                        [_valueLegendTextures setObject:texture forKey:[NSNumber numberWithInt:i]];
                    }
                }
            }         
        }
    }
    return _valueLegendTextures;
}


// lazy loading of row label textures
-(NSMutableDictionary *) rowLegendTextures
{
    if (_rowLegendTextures == nil)
    {
        _rowLegendTextures = [[NSMutableDictionary alloc] init];
        int start = 1;
        int end = [self numberRows];
        for (int i=0; i<[self numberRows];i++)
        {
            if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewController:legendForRow:)])
            {
                NSString *legendText = [self.frd3dBarChartDelegate frd3DBarChartViewController:self legendForRow:i];
                if ([legendText length] > 0)
                {
                    UIImage *image = [self imageWithText:legendText
                                                fontName:[self rowLegendFont] 
                                                   color:[self colorForRowLabels]
                                                   width:300.0 
                                                  height:100.0
                                              rightAlign:YES];
                    NSError *error = nil;
                    GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:nil error:&error];
                    if (error == nil)
                    {
                        [_rowLegendTextures setObject:texture forKey:[NSNumber numberWithInt:i]];
                    }
                }
            }
            start += [self numberRows];
            end += [self numberRows];            
        }
    }
    return _rowLegendTextures;
}




// lazy loading of column label textures
-(NSMutableDictionary *) columnLegendTextures
{
    if (_columnLegendTextures == nil)
    {
        _columnLegendTextures = [[NSMutableDictionary alloc] init];
        int start = 1;
        int end = [self numberColumns];
        for (int i=0; i<[self numberColumns];i++)
        {
            if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewController:legendForColumn:)])
            {
                NSString *legendText = [self.frd3dBarChartDelegate frd3DBarChartViewController:self legendForColumn:i];
                if ([legendText length] > 0)
                {
                    UIImage *image = [self imageWithText:legendText 
                                                fontName:[self columnLegendFont] 
                                                   color:[self colorForColumnLabels] 
                                                   width:300.0 
                                                  height:100.0 
                                              rightAlign:NO];
                    NSError *error = nil;
                    GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:nil error:&error];
                    if (error == nil)
                    {
                        [_columnLegendTextures setObject:texture forKey:[NSNumber numberWithInt:i]];
                    }
                }
            }
            start += [self numberColumns];
            end += [self numberColumns];            
        }
    }
    return _columnLegendTextures;
}


-(UIImage *) imageWithText:(NSString *)text fontName:(NSString *)fontName color:(UIColor *)color width:(float)width height:(float)height rightAlign:(BOOL) rightAlign
{
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();

    
    CGContextRef _composedImageContext = CGBitmapContextCreate(NULL, 
                                                               width, 
                                                               height, 
                                                               8, 
                                                               width*4, 
                                                               rgbColorSpace, 
                                                               kCGImageAlphaPremultipliedFirst);
    
    // draw your things into _composedImageContext
    char* txt	= (char *)[text cStringUsingEncoding:NSASCIIStringEncoding];

    CGContextSelectFont(_composedImageContext, [fontName cStringUsingEncoding:NSASCIIStringEncoding], 60.0, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode(_composedImageContext, kCGTextFill);
    CGContextSetFillColorWithColor(_composedImageContext, color.CGColor);
    
    //rotate text
    //CGContextSetTextMatrix(_composedImageContext, CGAffineTransformMakeRotation(0.0));
	
        
    CGSize expectedLabelSize = [text sizeWithFont:[UIFont fontWithName:fontName size:60.0] constrainedToSize:CGSizeMake(width, height)];
    
    if (rightAlign)
    {       
        float offsetX = width - expectedLabelSize.width;
        if (offsetX < 0 || offsetX >= width) offsetX = 0.0; // string is bigger than our allocated space.
        CGContextShowTextAtPoint(_composedImageContext, offsetX , expectedLabelSize.height / 2.0 , txt, strlen(txt));
    }
    else 
    {
        CGContextShowTextAtPoint(_composedImageContext, 0, expectedLabelSize.height / 2.0, txt, strlen(txt));
    }
    
    //finally turn the context into a CGImage
    CGImageRef cgImage = CGBitmapContextCreateImage(_composedImageContext);
    
    CGContextRelease(_composedImageContext);
    CGColorSpaceRelease(rgbColorSpace);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
     
}


#pragma mark - position animation routines

-(void) setRadiusScale:(float)radiusScale
{
    if (radiusScale > 2.0) radiusScale = 2.0;
    else if (radiusScale < 0.5) radiusScale = 0.5;
    
    _radiusScale = radiusScale;
}

-(void) setOffsetX:(float)offsetX
{
    while (offsetX >= 2 * M_PI) offsetX -= 2 * M_PI;
    while (offsetX <= -2 * M_PI) offsetX += 2 * M_PI;
    
    if (offsetX > M_PI) offsetX = offsetX - 2 * M_PI;
    if (offsetX < -M_PI) offsetX = offsetX + 2 * M_PI;
    
    _offsetX = offsetX;
}

-(void) setOffsetY:(float)offsetY
{
    if (offsetY > 2.0) offsetY = 2.0;
    if (offsetY < -2.0) offsetY = -2.0;
    
    _offsetY = offsetY;
}


-(void) animateOffsetX:(float)toOffsetX offsetY:(float)toOffsetY radiusScale:(float) toRadiusScale inDuration:(NSTimeInterval) timeInterval
{
    _targetOffsetY = toOffsetY;
    _offsetYAnimationDelta = toOffsetY - _offsetY;
    _targetOffsetX = toOffsetX;
    _offsetXAnimationDelta = toOffsetX - _offsetX;
    _targetRadiusScale = toRadiusScale;
    _radiusScaleAnimationDelta = toRadiusScale - _radiusScale;
    _positionAnimationStartDate = [NSDate date];
    _positionAnimationCompletionDate = [_positionAnimationStartDate dateByAddingTimeInterval:timeInterval];
    
    _isAnimatingPosition = YES;
}


#pragma mark - actions

-(void) viewDoubleTapped:(UITapGestureRecognizer *) sender
{
    [self animateOffsetX:0.0 offsetY:0.0 radiusScale:1.0 inDuration:0.7];
}



-(void) viewPinched:(UIPinchGestureRecognizer *)sender
{
    self.radiusScale = 1/sender.scale;
}


-(void) viewPanned:(UIPanGestureRecognizer *) sender
{    
    CGPoint diff = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    
    float deltaX = 0.0;
    float deltaY = 0.0;
    
    if (abs(diff.y) > abs(diff.x))
    {
        deltaY = [sender velocityInView:self.view].y / 10000.0;
    }
    else 
    {
        deltaX = [sender velocityInView:self.view].x / 10000.0;
    }
    
    self.offsetY += deltaY;
    self.offsetX += deltaX;
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        // keep moving for a little while
        [self animateOffsetX:_offsetX + 1.5 * deltaX 
                     offsetY:_offsetY + 1.5 * deltaY
                 radiusScale:_radiusScale inDuration:0.7];
    }
}


#pragma mark - delegate wrappers

-(int) numberValueLines
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerNumberHeightLines:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewControllerNumberHeightLines:self];
    }
    return 0;
}

-(NSString *) valueLegendFont
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerValueLegendFontName:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewControllerValueLegendFontName:self];
    }
    return @"Helvetica";
}

-(NSString *) rowLegendFont
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerRowLegendFontName:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewControllerRowLegendFontName:self];
    }
    return @"Helvetica";
}

-(NSString *) columnLegendFont
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerColumnLegendFontName:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewControllerColumnLegendFontName:self];
    }
    return @"Helvetica";
}

-(UIColor *) colorForRowLabels
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerRowLegendColor:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewControllerRowLegendColor:self];
    }
    return [UIColor whiteColor];
}

-(UIColor *) colorForColumnLabels
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerColumnLegendColor:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewControllerColumnLegendColor:self];
    }
    return [UIColor whiteColor];
}

-(UIColor *) colorForValueLabels
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerValueLegendColor:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewControllerValueLegendColor:self];
    }
    return [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0];
}

-(int) numberColumns
{
    return [self.frd3dBarChartDelegate frd3DBarChartViewControllerNumberColumns:self];
}

-(int) numberRows
{
    return [self.frd3dBarChartDelegate frd3DBarChartViewControllerNumberRows:self];    
}

-(float) cubeWidth
{
    return 2.0 / MAX([self numberColumns], [self numberRows]);
}
                      
-(UIColor *) colorForRow:(int)row column:(int)column
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewController:colorForBarAtRow:column:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewController:self colorForBarAtRow:row column:column];
    }
    else 
    {
        return [UIColor greenColor];
    }
}

-(float) cubePercentSizeForBarAtRow:(int)row column:(int) column
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewController:percentSizeForBarAtRow:column:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewController:self percentSizeForBarAtRow:row column:column];
    }
    return 0.97;
}

-(bool) hasBarForRow:(int)row column:(int)column
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewController:hasBarForRow:column:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewController:self hasBarForRow:row column:column];
    }
    return YES;
}


#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    _isAnimatingBarHeights = YES;
    _radiusScale = 1.0;
    _targetRadiusScale = _radiusScale;
    {
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(viewPinched:)];
        [self.view addGestureRecognizer:pinchGestureRecognizer];
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewPanned:)];
        [self.view addGestureRecognizer:panGestureRecognizer];
        
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDoubleTapped:)];
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        [self.view addGestureRecognizer:doubleTapGestureRecognizer];
    }
    
  
    _targetBarHeights = malloc([self numberRows] * [self numberColumns] * sizeof(float));
    _currentBarHeights = malloc([self numberRows] * [self numberColumns] * sizeof(float));
    _barHeightAnimationDeltas = malloc([self numberRows] * [self numberColumns] * sizeof(float));
    _targetColors = malloc([self numberRows] * [self numberColumns] * sizeof(float) * 4); // r g b a
    _currentColors = malloc([self numberRows] * [self numberColumns] * sizeof(float) * 4); // r g b a
    _colorDeltas = malloc([self numberRows] * [self numberColumns] * sizeof(float) * 4);  // r g b a
    
    
    bzero(_targetBarHeights, [self numberRows] * [self numberColumns] * sizeof(float));
    bzero(_currentBarHeights, [self numberRows] * [self numberColumns] * sizeof(float));
    bzero(_barHeightAnimationDeltas, [self numberRows] * [self numberColumns] * sizeof(float));
    bzero(_targetColors, [self numberRows] * [self numberColumns] * sizeof(float));
    bzero(_currentColors, [self numberRows] * [self numberColumns] * sizeof(float));
    bzero(_colorDeltas, [self numberRows] * [self numberColumns] * sizeof(float));
    
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
    
    free(_targetBarHeights);
    free(_currentBarHeights);
    free(_barHeightAnimationDeltas);
    free(_targetColors);
    free(_currentColors);
    free(_colorDeltas);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - openGL setup routines

- (void)setupVBOs 
{   
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindVertexArrayOES(0);
    {
        glGenVertexArraysOES(1, &_vertexArray);
        glBindVertexArrayOES(_vertexArray);
        
        //    GLuint texCoordBuffer;
        glGenBuffers(1, &_vertexBuffer);   
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
        
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
        glEnableVertexAttribArray(GLKVertexAttribNormal);
        
    }
    {
        glGenVertexArraysOES(1, &_vertexArrayHLine);
        glBindVertexArrayOES(_vertexArrayHLine);
        
        glGenBuffers(1, &_vertexBuffer2);   
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer2);
        glBufferData(GL_ARRAY_BUFFER, sizeof(gHLineVertexData), gHLineVertexData, GL_STATIC_DRAW);
        
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
        glEnableVertexAttribArray(GLKVertexAttribNormal);  
        
    }
    {
        glGenVertexArraysOES(1, &_vertexArrayVLine);
        glBindVertexArrayOES(_vertexArrayVLine);
        
        glGenBuffers(1, &_vertexBuffer3);   
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer3);
        glBufferData(GL_ARRAY_BUFFER, sizeof(gVLineVertexData), gVLineVertexData, GL_STATIC_DRAW);
        
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
        glEnableVertexAttribArray(GLKVertexAttribNormal);      
    }
    
    {
        glGenVertexArraysOES(1, &_vertexArrayBasePlane);
        glBindVertexArrayOES(_vertexArrayBasePlane);
        
        glGenBuffers(1, &_vertexBuffer4);   
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer4);
        glBufferData(GL_ARRAY_BUFFER, sizeof(gBasePlaneData), gBasePlaneData, GL_STATIC_DRAW);
        
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
        glEnableVertexAttribArray(GLKVertexAttribNormal);    
    }    
    
    {
        glGenVertexArraysOES(1, &_vertexLeftLegendPlane);
        glBindVertexArrayOES(_vertexLeftLegendPlane);
        
        glGenBuffers(1, &_vertexBuffer5);   
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer5);
        glBufferData(GL_ARRAY_BUFFER, sizeof(gLeftLegendPlaneData), gLeftLegendPlaneData, GL_STATIC_DRAW);
        
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
        glEnableVertexAttribArray(GLKVertexAttribNormal);      
        
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(24));
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);    
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    //glBindVertexArrayOES(0);
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
        
    [self setupVBOs];
    
    glEnable(GL_DEPTH_TEST);
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    self.effect.light0.position = GLKVector4Make(+2.0, 2.0, +2.0, 0.0);
    
    self.effect.material.shininess = 100.0;
    self.effect.material.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
}

#pragma mark - update stuff

- (void)update
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    
    self.effect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), aspect, 1.0f, 10.0f);
    
    GLKVector3 rotation = GLKVector3Make(0.0,0.0,0.0);
    GLKVector3 position = GLKVector3Make(0.0, 0.0, -0.0);
    GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
    GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
    GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);

    GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale(1.0, 1.0, 1.0);
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
    
    GLKMatrix4 modelMatrix = 
    GLKMatrix4Multiply(translateMatrix,
                       GLKMatrix4Multiply(scaleMatrix,
                                          GLKMatrix4Multiply(zRotationMatrix, 
                                                             GLKMatrix4Multiply(yRotationMatrix, 
                                                                                xRotationMatrix))));
    
    self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(self.viewMatrix, modelMatrix);

    NSTimeInterval timeRemainingToPositionAnimationCompletion = [_positionAnimationCompletionDate timeIntervalSinceNow];
    
    
    // the repositioning animation (double tap)
    if (_isAnimatingPosition)
    {
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSinceDate:_positionAnimationStartDate];
        NSTimeInterval animationDuration = [_positionAnimationCompletionDate timeIntervalSinceDate:_positionAnimationStartDate];
        
        BOOL animationCompleted = YES;
        if (timeRemainingToPositionAnimationCompletion <= 0)
        {
            _radiusScale = _targetRadiusScale;
            self.offsetX = _targetOffsetX;
            self.offsetY = _targetOffsetY;
        }
        else
        {
            kEasingMethods method = kEasingMethodCubicOut;
            _radiusScale = [self easingWithMethod:method currentTime:currentTime startValue:_targetRadiusScale - _radiusScaleAnimationDelta changeInValue:_radiusScaleAnimationDelta duration:animationDuration];
            _offsetX = [self easingWithMethod:method currentTime:currentTime startValue:_targetOffsetX - _offsetXAnimationDelta changeInValue:_offsetXAnimationDelta duration:animationDuration];
            _offsetY = [self easingWithMethod:method currentTime:currentTime startValue:_targetOffsetY - _offsetYAnimationDelta changeInValue:_offsetYAnimationDelta duration:animationDuration];
            
            animationCompleted = NO;
        }
        _isAnimatingPosition = !animationCompleted;
    }

    NSTimeInterval timeRemainingToHeightAnimationCompletion = [_barHeightAnimationCompletionDate timeIntervalSinceNow];
    
    if (_isAnimatingBarHeights)
    {
        BOOL animationCompleted = YES;

        NSTimeInterval currentTime = [[NSDate date] timeIntervalSinceDate:_barHeightsAnimationStartDate];
        NSTimeInterval animationDuration = [_barHeightAnimationCompletionDate timeIntervalSinceDate:_barHeightsAnimationStartDate];

                
        // the bar height animation and color
        for (int i=0; i<[self numberRows] * [self numberColumns]; i++)
        {
            // how close are we?            
            if (timeRemainingToHeightAnimationCompletion <= 0)
            {
                _currentBarHeights[i] = _targetBarHeights[i];
                _currentColors[4*i] = _targetColors[4*i];
                _currentColors[4*i+1] = _targetColors[4*i+1];
                _currentColors[4*i+2] = _targetColors[4*i+2];
                _currentColors[4*i+3] = _targetColors[4*i+3];
            }
            else
            {
                // we still have some ways to go.
                _currentBarHeights[i] = [self easingWithMethod:kEasingMethodQuinticOut 
                                                   currentTime:currentTime 
                                                    startValue:_targetBarHeights[i]-_barHeightAnimationDeltas[i] 
                                                 changeInValue:_barHeightAnimationDeltas[i] 
                                                      duration:animationDuration];
                _currentColors[4 * i] = [self easingWithMethod:kEasingMethodQuinticOut 
                                                   currentTime:currentTime 
                                                    startValue:_targetColors[4*i]-_colorDeltas[4*i] 
                                                 changeInValue:_colorDeltas[4*i] 
                                                      duration:animationDuration];
                _currentColors[4 * i + 1] = [self easingWithMethod:kEasingMethodQuinticOut 
                                                   currentTime:currentTime 
                                                    startValue:_targetColors[4*i + 1]-_colorDeltas[4*i + 1] 
                                                 changeInValue:_colorDeltas[4*i + 1] 
                                                      duration:animationDuration];
                _currentColors[4 * i + 2] = [self easingWithMethod:kEasingMethodQuinticOut 
                                                   currentTime:currentTime 
                                                    startValue:_targetColors[4*i + 2]-_colorDeltas[4*i + 2] 
                                                 changeInValue:_colorDeltas[4*i + 2] 
                                                      duration:animationDuration];
                _currentColors[4 * i + 3] = [self easingWithMethod:kEasingMethodQuinticOut 
                                                   currentTime:currentTime 
                                                    startValue:_targetColors[4*i + 3]-_colorDeltas[4*i + 3] 
                                                 changeInValue:_colorDeltas[4*i + 3] 
                                                      duration:animationDuration];
                
                animationCompleted = NO;
            }
        }
        _isAnimatingBarHeights = !animationCompleted;
    }
    
}

-(GLKMatrix4) viewMatrix
{
    
    float radius = 4.5 * _radiusScale;
    float startAngle = -3 * M_PI/4.0;
    
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(radius * cos(_offsetX - startAngle) , 2.75 * (1.0 + _offsetY), radius * sinf(_offsetX - startAngle) , 0, 0, 0, +0.0, 1, -0.0);
    
    return viewMatrix;
}


#pragma mark - drawing routines

-(float) startX
{
    if ([self numberColumns] > [self numberRows])
    {
        return -1.0;
    }
    return -1 + [self cubeWidth] * ( [self numberRows] - [self numberColumns]) / 2.0;;
}

-(float) startY
{
    if ([self numberRows] > [self numberColumns])
    {
        return -1.0;
    }
    return -1 + [self cubeWidth] * ( [self numberColumns] - [self numberRows]) / 2.0;
}


-(void) drawLegend
{
    // draw the legend.
    glEnable(GL_BLEND);
    glBlendFunc( GL_ONE, GL_ONE_MINUS_SRC_ALPHA );
 
    // our image is 300x100 so its lenght is 3 * cubewidth
    float x = [self startX] - (300.0/100.0) * [self cubeWidth] - [self cubeWidth]/2.0;
    float y = [self startY] ;
    
    for (int i=0; i<([self numberRows]); i++)
    {
        GLKTextureInfo *texture = [self.rowLegendTextures objectForKey:[NSNumber numberWithInt:i]];
        
        if (texture != nil)
        {
            glBindVertexArrayOES(_vertexLeftLegendPlane);
            GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
            GLKVector3 position = GLKVector3Make(x, 0.0, y);
            GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
            GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
            GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
            
            GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale([self cubeWidth],1.0,[self cubeWidth]);
            GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
            
            
            GLKMatrix4 modelMatrix = 
            GLKMatrix4Multiply(translateMatrix,
                               GLKMatrix4Multiply(scaleMatrix,
                                                  GLKMatrix4Multiply(zRotationMatrix, 
                                                                     GLKMatrix4Multiply(yRotationMatrix, 
                                                                                        xRotationMatrix))));
            
            self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(self.viewMatrix, modelMatrix);
            
            self.effect.texture2d0.enabled = GL_TRUE;
            self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;
            self.effect.texture2d0.target = GLKTextureTarget2D;
            self.effect.texture2d0.name = texture.name;
            
            [self.effect prepareToDraw];
            
            glDrawArrays(GL_TRIANGLES, 0, 6);
        }
        y += [self cubeWidth];
    }
    
    if ([self numberValueLines] > 0)
    {
#define HEIGHT_LABEL_SIZE 0.1
        // our image is 300x100 so its lenght is 3 * cubewidth
        float x = [self startX] - (300.0/100.0) * HEIGHT_LABEL_SIZE - HEIGHT_LABEL_SIZE/2.0;
        float y = 1.0 / [self numberValueLines] + HEIGHT_LABEL_SIZE/2.0;
        float z = [self startY];
        
        for (int i=0; i<([self numberValueLines]); i++)
        {
            GLKTextureInfo *texture = [self.valueLegendTextures objectForKey:[NSNumber numberWithInt:i]];
            
            if (texture != nil)
            {
                glBindVertexArrayOES(_vertexLeftLegendPlane);
                GLKVector3 rotation = GLKVector3Make(+M_PI_2, 0.0, 0.0);
                GLKVector3 position = GLKVector3Make(x, y, z);
                GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
                GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
                GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
                
                GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale(HEIGHT_LABEL_SIZE, HEIGHT_LABEL_SIZE, [self cubeWidth]);
                GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
                
                
                GLKMatrix4 modelMatrix = 
                GLKMatrix4Multiply(translateMatrix,
                                   GLKMatrix4Multiply(scaleMatrix,
                                                      GLKMatrix4Multiply(zRotationMatrix, 
                                                                         GLKMatrix4Multiply(yRotationMatrix, 
                                                                                            xRotationMatrix))));
                
                self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(self.viewMatrix, modelMatrix);
                
                self.effect.texture2d0.enabled = GL_TRUE;
                self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;
                self.effect.texture2d0.target = GLKTextureTarget2D;
                self.effect.texture2d0.name = texture.name;
                
                [self.effect prepareToDraw];
                
                glDrawArrays(GL_TRIANGLES, 0, 6);
            }
            y += 1/(float)[self numberValueLines];
            
        }
    }
    
    x = [self startX] + [self cubeWidth] ;
    y = [self startY] + [self cubeWidth] * ([self numberRows] + 1) - [self cubeWidth]/2.0;

    
    for (int i=0; i<([self numberColumns]); i++)
    {
        GLKTextureInfo *texture = [self.columnLegendTextures objectForKey:[NSNumber numberWithInt:i]];
        
        if (texture != nil)
        {
            glBindVertexArrayOES(_vertexLeftLegendPlane);
            GLKVector3 rotation = GLKVector3Make(0.0, -M_PI_2, 0.0);
            GLKVector3 position = GLKVector3Make(x, 0.0, y);
            GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
            GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
            GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
            GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale([self cubeWidth], 1.0, [self cubeWidth]);
            GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
            
            
            GLKMatrix4 modelMatrix = 
            GLKMatrix4Multiply(translateMatrix,
                               GLKMatrix4Multiply(scaleMatrix,
                                                  GLKMatrix4Multiply(zRotationMatrix, 
                                                                     GLKMatrix4Multiply(yRotationMatrix, 
                                                                                        xRotationMatrix))));

            self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(self.viewMatrix, modelMatrix);
            
            self.effect.texture2d0.enabled = GL_TRUE;
            self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;
            self.effect.texture2d0.target = GLKTextureTarget2D;
            self.effect.texture2d0.name = texture.name;
            [self.effect prepareToDraw];
            
            glDrawArrays(GL_TRIANGLES, 0, 6);
        }
        x += [self cubeWidth];
    }
    
    
    
    
    
    glDisable(GL_BLEND);
}

-(void) drawValueLines
{
    int numberLines = [self numberValueLines];
    
    if (numberLines <=0) return;
    
    self.effect.light0.diffuseColor = GLKVector4Make(0.7f,0.7f,0.7f, 1.0f);
    self.effect.material.diffuseColor = GLKVector4Make(0.7f,0.7f,0.7f, 1.0f);

    glBindVertexArrayOES(_vertexArrayHLine);
      

    for (int l = 0; l<numberLines; l++)
    {
        float y = (l + 1)/(float)numberLines;
        
        float x = [self startX];
        float z = [self startY];
    #define NUMBER_DASHES 20
        for (int i=0; i<NUMBER_DASHES; i++)
        {
            GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
            GLKVector3 position = GLKVector3Make(x, y, z);

            GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
            GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
            GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
            
            GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale(0.015, 0.0, 0.0);
            GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
            
            GLKMatrix4 modelMatrix = 
            GLKMatrix4Multiply(translateMatrix,
                               GLKMatrix4Multiply(scaleMatrix,
                                                  GLKMatrix4Multiply(zRotationMatrix, 
                                                                     GLKMatrix4Multiply(yRotationMatrix, 
                                                                                        xRotationMatrix))));
            
            self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(self.viewMatrix, modelMatrix);
            
            [self.effect prepareToDraw];
            glLineWidth(2.0);
            glDrawArrays(GL_LINES, 0, 2);
            
            x += [self cubeWidth] * [self numberColumns] / NUMBER_DASHES ;
        }
    }
}

-(void) drawGrid
{
    // draw the grid starting with our horizontal plane.
    {
        float x = [self startX];
        float y = [self startY];
        
        self.effect.light0.diffuseColor = GLKVector4Make(0.7f,0.7f,0.7f, 0.8f);
        self.effect.material.diffuseColor = GLKVector4Make(0.7f,0.7f,0.7f, 0.8f);
        
        self.effect.texture2d0.enabled = GL_FALSE;
        
        glBindVertexArrayOES(_vertexArrayBasePlane);
        GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
        GLKVector3 position = GLKVector3Make(x, 0.0, y);
        GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
        GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
        GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
        
        GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale([self cubeWidth] * [self numberColumns], 1.0, [self cubeWidth] * [self numberRows]);
        GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
        
        GLKMatrix4 modelMatrix = 
        GLKMatrix4Multiply(translateMatrix,
                           GLKMatrix4Multiply(scaleMatrix,
                                              GLKMatrix4Multiply(zRotationMatrix, 
                                                                 GLKMatrix4Multiply(yRotationMatrix, 
                                                                                    xRotationMatrix))));
        
        self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(self.viewMatrix, modelMatrix);
        
        [self.effect prepareToDraw];
        
        
        glEnable(GL_POLYGON_OFFSET_FILL);
        glPolygonOffset(+1.0, 2.0);
        
        glDrawArrays(GL_TRIANGLES, 0, 6);
        
        glDisable(GL_POLYGON_OFFSET_FILL);
    }    
    
    self.effect.light0.diffuseColor = GLKVector4Make(0.75f,0.75f,0.75f, 1.0f);
    self.effect.material.diffuseColor = GLKVector4Make(0.75f,0.75f,0.75f, 1.0f);
    
    glBindVertexArrayOES(_vertexArrayHLine);
    
    float y = [self startY];
    float x = [self startX];
    for (int i=0; i<([self numberRows] + 1); i++)
    {
        GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
        GLKVector3 position = GLKVector3Make(x, 0.0, y);
        y += [self cubeWidth];
        GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
        GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
        GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
        
        GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale([self cubeWidth] * [self numberColumns], 1.0, 1.0);
        GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
        
        GLKMatrix4 modelMatrix = 
        GLKMatrix4Multiply(translateMatrix,
                           GLKMatrix4Multiply(scaleMatrix,
                                              GLKMatrix4Multiply(zRotationMatrix, 
                                                                 GLKMatrix4Multiply(yRotationMatrix, 
                                                                                    xRotationMatrix))));
        
        self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(self.viewMatrix, modelMatrix);
        
        [self.effect prepareToDraw];
        glLineWidth(3.0);
        glDrawArrays(GL_LINES, 0, 2);
    }
    
    glBindVertexArrayOES(_vertexArrayVLine);
    y = [self startY];
    x = [self startX];
    for (int i=0; i<([self numberColumns] + 1); i++)
    {
        GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
        GLKVector3 position = GLKVector3Make(x, 0.0, y);
        x += [self cubeWidth];
        GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
        GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
        GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
        
        GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale(1.0, 1.0, [self cubeWidth] * [self numberRows]);
        GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
        
        GLKMatrix4 modelMatrix = 
        GLKMatrix4Multiply(translateMatrix,
                           GLKMatrix4Multiply(scaleMatrix,
                                              GLKMatrix4Multiply(zRotationMatrix, 
                                                                 GLKMatrix4Multiply(yRotationMatrix, 
                                                                                    xRotationMatrix))));
        
        self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(self.viewMatrix, modelMatrix);
        
        [self.effect prepareToDraw];
        glLineWidth(3.0);
        glDrawArrays(GL_LINES, 0, 2);
    }
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
 
    float radius = 4.0;
    float startAngle = -3.1 * M_PI/4.0;
    
    self.effect.light0.position = GLKVector4Make(radius * cos(_offsetX - startAngle), 4.0 * (1.0+_offsetY), radius * sinf(_offsetX - startAngle), 0.0);
    
    [self drawLegend];
    
    [self drawGrid];
    
    [self drawValueLines];
    
    // draw the cubes

    glBindVertexArrayOES(_vertexArray);
    
    float x = [self startX];
    float y = [self startY];
    for (int i=0; i<[self numberRows]; i++)
    {
        for (int j=0; j< [self numberColumns]; j++)
        {
            if ([self hasBarForRow:i column:j])
            {
                float percentSize = [self cubePercentSizeForBarAtRow:i column:j];

                GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
                GLKVector3 position = GLKVector3Make(x + ([self cubeWidth] * (1-percentSize))/2.0, // make sure our bar is centered in the grid cell
                                                     -0.0, 
                                                     y + ([self cubeWidth] * (1-percentSize))/2.0);
                
                GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
                GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
                GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
                            
                float height = _currentBarHeights[i*[self numberColumns] + j];
                if (fabs(height) < 0.0001) height = 0.0001; // an actual 0 height is ugly, rendering constantly hesitates between black triangle and colored triangle
                GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale([self cubeWidth] * percentSize, 
                                                                 height, 
                                                                 [self cubeWidth] * percentSize);
                GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
                
                GLKMatrix4 modelMatrix = 
                GLKMatrix4Multiply(translateMatrix,
                                   GLKMatrix4Multiply(scaleMatrix,
                                                      GLKMatrix4Multiply(zRotationMatrix, 
                                                                         GLKMatrix4Multiply(yRotationMatrix, 
                                                                                            xRotationMatrix))));
                
                self.effect.transform.modelviewMatrix = GLKMatrix4Multiply(self.viewMatrix, modelMatrix);
                
                float r,g,b,a;
                int k = i*[self numberColumns] + j;
                r =  _currentColors[4*k+0];
                g =  _currentColors[4*k+1];
                b =  _currentColors[4*k+2];
                a =  _currentColors[4*k+3];

                self.effect.light0.diffuseColor = GLKVector4Make(r,g,b,a);
                self.effect.material.diffuseColor = GLKVector4Make(0.9 * r, 0.9 * g, 0.9 * b, 0.9 * a);
                [self.effect prepareToDraw];
                
                glDrawArrays(GL_TRIANGLES, 0, 36);
                
            }
            x += [self cubeWidth];
        }
        y += [self cubeWidth];
        x = [self startX];
    }
    glBindVertexArrayOES(0);
}


@end
