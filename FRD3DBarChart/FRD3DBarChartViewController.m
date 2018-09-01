//
//  FRD3DBarChartViewController.m
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


#import "FRD3DBarChartViewController.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/CoreAnimation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "FRD3DBarChartViewController+Easing.h"
#import "Shapes.h"
#import <OpenGLES/ES2/glext.h>

#if __has_feature(objc_arc)
#else
#error You must enable ARC to use this control. Come on! It is 2012, time has come!
#endif

@interface FRD3DBarChartViewController () {

    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    
    
    // cylinderBuffer is generated in code
    GLfloat *cylinderBuffer;
    
    // bunch of variable openGL needs.
    GLuint _vertexArray;
    GLuint _vertexArrayHLine;
    GLuint _vertexArrayVLine;
    GLuint _vertexArrayBasePlane;
    GLuint _vertexLeftLegendPlane;
    GLuint _vertexCylinder;
    GLuint _vertexTopText;
    
    GLuint _vertexBuffer;
    GLuint _vertexBuffer2;
    GLuint _vertexBuffer3;
    GLuint _vertexBuffer4;
    GLuint _vertexBuffer5;
    GLuint _vertexBuffer6;
    GLuint _vertexBuffer7;
    
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
    
    // when animating bar heights (or color) the time at which the animation should complete.
    // Used with _barHeightsAnimationStartTime by the easing function to compute intermediary
    // values between start and target values for bar heights and color.
    CFAbsoluteTime _barHeightAnimationCompletionTime;
    CFAbsoluteTime _barHeightsAnimationStartTime; // bar animation start time.
    
    // same as above to compute intermediary values when animating position (offsetX, offsetY and radiusScale).
    CFAbsoluteTime _positionAnimationCompletionTime;
    CFAbsoluteTime _positionAnimationStartTime;
    
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
@property (nonatomic, strong) NSMutableDictionary *topLabelTextures;

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
@synthesize topLabelTextures = _topLabelTextures;
@synthesize radiusScale = _radiusScale;
@synthesize offsetX = _offsetX;
@synthesize offsetY = _offsetY;

@synthesize useCylinders = _useCylinders;
@synthesize frd3dBarChartDelegate = _frd3dBarChartDelegate;



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
            CGFloat r,g,b,a;
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
        _barHeightAnimationCompletionTime = CFAbsoluteTimeGetCurrent();
    }
    else
    {
        _barHeightsAnimationStartTime = CFAbsoluteTimeGetCurrent();
        _barHeightAnimationCompletionTime = _barHeightsAnimationStartTime+duration;
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

-(void) setTopLabelTextures:(NSMutableDictionary *)topLabelTextures
{
    if (topLabelTextures != _topLabelTextures)
    {
        // problem with texture is they are not freed on their own since they are retained by GL.
        for (NSNumber *number in [_topLabelTextures keyEnumerator])
        {
            GLKTextureInfo *text = [_topLabelTextures objectForKey:number];
            GLuint name = text.name;
            glDeleteTextures(1, &name);
        }
        // now we have cleaned up everything we can override the dictionary.
        _rowLegendTextures = topLabelTextures;
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
                    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:YES], GLKTextureLoaderApplyPremultiplication, nil];
                    GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:&error];
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
                    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:YES], GLKTextureLoaderApplyPremultiplication, nil];
                    GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:&error];
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
                    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:YES], GLKTextureLoaderApplyPremultiplication, nil];
                    GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:&error];
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
#define COLUMNOFFSETID 0x10000

// lazy loading of top label textures
-(NSMutableDictionary *) topLabelTextures
{
    if (_topLabelTextures == nil)
    {
        _topLabelTextures = [[NSMutableDictionary alloc] init];
        
        NSString *fontName;
        
        if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerTopTextFontName:)])
        {
            fontName = [self.frd3dBarChartDelegate frd3DBarChartViewControllerTopTextFontName:self];
        }
        if ([fontName length] == 0) fontName = @"Helvetica"; // our default
        
        if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerHasTopText:)] &&
            [self.frd3dBarChartDelegate frd3DBarChartViewControllerHasTopText:self])
        {
            
            for (int i=0; i<[self numberRows];i++)
            {
                for (int j=0; j<[self numberColumns];j++)
                {
                    NSString *legendText = @"";
                    
                    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewController:topTextForBarAtRow:column:)])
                    {
                        legendText = [self.frd3dBarChartDelegate frd3DBarChartViewController:self topTextForBarAtRow:i column:j];
                    }
                    
                    UIColor *color = nil;
                    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewController:colorForTopTextBarAtRow:column:)])
                    {
                        color = [self.frd3dBarChartDelegate frd3DBarChartViewController:self colorForTopTextBarAtRow:i column:j];
                    }
                    if (color == nil) color = [UIColor whiteColor];
  
                    if ([legendText length] > 0)
                    {
                        UIImage *image = [self topImageWithText:legendText
                                                       fontName:fontName
                                                          color:color
                                                          width:100.0
                                                         height:100.0];
                        NSError *error = nil;
                        NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:YES], GLKTextureLoaderApplyPremultiplication, nil];
                        GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:image.CGImage options:options error:&error];
                        if (error == nil)
                        {
                            [_topLabelTextures setObject:texture forKey:[NSNumber numberWithInt:i * COLUMNOFFSETID + j]];
                        }
                    }
                }
            }
        }
    }
    return _topLabelTextures;
}

CTFontRef CTFontCreateFromUIFont(UIFont *font)
{
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName,
                                            font.pointSize,
                                            NULL);
    return ctFont;
}

+ (id)fontWithCTFont:(CTFontRef)ctFont
{
    CFStringRef fontName = CTFontCopyFullName(ctFont);
    CGFloat fontSize = CTFontGetSize(ctFont);
    
    UIFont *ret = [UIFont fontWithName:(__bridge NSString *)fontName size:fontSize];
    CFRelease(fontName);
    return ret;
}

+ (id)mutableAttributedStringWithString:(NSString *)string font:(UIFont *)font color:(UIColor *)color alignment:(CTTextAlignment)alignment

{
    CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    
    if (string != nil)
        CFAttributedStringReplaceString (attrString, CFRangeMake(0, 0), (CFStringRef)string);
    
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), kCTForegroundColorAttributeName, color.CGColor);
    
    CTFontRef theFont = CTFontCreateFromUIFont(font);
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), kCTFontAttributeName, theFont);
    CFRelease(theFont);
    
    CTParagraphStyleSetting settings[] = { kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment };
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(settings[0]));
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFAttributedStringGetLength(attrString)), kCTParagraphStyleAttributeName, paragraphStyle);
    CFRelease(paragraphStyle);
    
    // ARC sees assignment to ret increment ret's refcnt .
    NSMutableAttributedString *ret = (__bridge NSMutableAttributedString *)attrString;
    // The other increment to attrString's (aka ret's) refcnt occurring under
    // manual CF management when attrString was created should be decremented
    // via CFRelease before returning.
    CFRelease(attrString);
    
    return ret;
}



-(UIImage *) topImageWithText:(NSString *)text
                     fontName:(NSString *)fontName
                        color:(UIColor *)color
                        width:(float)width
                       height:(float)height
{
    // draw your things into _composedImageContext
    char* txt	= (char *)[text cStringUsingEncoding:NSASCIIStringEncoding];
    if (txt == NULL) return nil;
    
    float fontSize = 60;
    // Default value correct for txt = "$25.3B" in Helvetica 60.
    CGSize expectedLabelSize = CGSizeMake(190.166015625, 60);;
    CGFloat ascent = 0;
    CGFloat descent = 0;
    CGFloat leading = 0;
    while (fontSize >= 6) {

        CFAttributedStringRef attrString = (__bridge CFAttributedStringRef)([FRD3DBarChartViewController mutableAttributedStringWithString:text
                                                                                                                               font:[UIFont fontWithName:fontName
                                                                                                                                                    size:fontSize]
                                                                                                                              color:color
                                                                                                                          alignment:kCTTextAlignmentLeft]);
        CTLineRef line = CTLineCreateWithAttributedString(attrString);

        CGFloat textWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat textHeight = ascent+descent;

        CFRelease(line);
        
        expectedLabelSize = CGSizeMake(textWidth, textHeight);
        if (textHeight < height && textWidth < width)
            break;
        
        fontSize--;
    }
    
    // draw our string into the image.
    float y = height/2.0 - expectedLabelSize.height/2.0 + (descent)/2.0;
    float x = width/2.0 - expectedLabelSize.width/2.0;

    UIImage *image2 = [[UIImage alloc] init];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 1);
    [image2 drawInRect:CGRectMake(x, y, expectedLabelSize.width, expectedLabelSize.height) blendMode:kCGBlendModeNormal alpha:1.0f];
    [image2 drawAtPoint:CGPointMake(0.0f, 0.0f)];
    [text drawAtPoint:CGPointMake(x,y)
       withAttributes:@{NSFontAttributeName:[UIFont fontWithName:fontName size:fontSize],
                        NSForegroundColorAttributeName: color}];

    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}



-(UIImage *) imageWithText:(NSString *)text
                  fontName:(NSString *)fontName 
                     color:(UIColor *)color
                     width:(float)width 
                    height:(float)height 
                rightAlign:(BOOL) rightAlign
{

	CGRect textRect = [text boundingRectWithSize:CGSizeMake(width, height)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:[UIFont fontWithName:fontName size:60.0]}
                                         context:nil];
    
    CGSize expectedLabelSize = textRect.size;
    
    float offsetX = rightAlign ? (width - expectedLabelSize.width) : 0.0f;
    UIImage *image2 = [[UIImage alloc] init];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 1);
    [image2 drawInRect:CGRectMake(offsetX,
                                  expectedLabelSize.height / 2.0,
                                  expectedLabelSize.width,
                                  expectedLabelSize.height)
             blendMode:kCGBlendModeNormal
                 alpha:1.0f];
    [image2 drawAtPoint:CGPointMake(offsetX, 0.0f)];
    [text drawAtPoint:CGPointMake(offsetX,0.0f)
       withAttributes:@{NSFontAttributeName:[UIFont fontWithName:fontName size:60.0],
                        NSForegroundColorAttributeName: color}];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return result;
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
    _positionAnimationStartTime = CFAbsoluteTimeGetCurrent();
    _positionAnimationCompletionTime = _positionAnimationStartTime+timeInterval;
    
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
    
    if (fabs(diff.y) > fabs(diff.x))
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
    return [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8];
}

-(UIColor *) colorForColumnLabels
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerColumnLegendColor:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewControllerColumnLegendColor:self];
    }
    return [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8];
}

-(UIColor *) colorForValueLabels
{
    if ([self.frd3dBarChartDelegate respondsToSelector:@selector(frd3DBarChartViewControllerValueLegendColor:)])
    {
        return [self.frd3dBarChartDelegate frd3DBarChartViewControllerValueLegendColor:self];
    }
    return [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8];
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


-(int) numberCylinderFacets
{
    float n = 1000.0/ MAX([self numberColumns], [self numberRows]);
    if (n<16) n = 16;
    return (int)n;
}

-(void) generateCylinder
{
#define TWOPI (2.0f * M_PI)
    
    cylinderBuffer = (GLfloat *)malloc(4 * [self numberCylinderFacets] * 6 * 3 * sizeof(float));
    
    GLKVector3 centerBottom = GLKVector3Make(0.5f, 0.0, 0.5f);
    GLKVector3 centerTop = GLKVector3Make(0.5f, 1.0, 0.5f);
    float radius = 0.5f;
    
    int n = 0;
    
    for (int i=0; i<[self numberCylinderFacets]; i++) 
    {
        float theta1 = i * TWOPI / (float)[self numberCylinderFacets];
        float theta2 = (i + 1) * TWOPI / (float)[self numberCylinderFacets];
        
        // top circle and bottom circle:
        for (int c=0;c<2;c++)
        {
            GLKVector3 vect = c == 0 ? centerBottom : centerTop;
            float normalY = c == 0 ? -1 : +1;
            cylinderBuffer[n++] = vect.x;
            cylinderBuffer[n++] = vect.y;
            cylinderBuffer[n++] = vect.z;
            cylinderBuffer[n++] = 0.0f; // normal x
            cylinderBuffer[n++] = normalY; // normal y
            cylinderBuffer[n++] = 0.0f; // normal z
            
            cylinderBuffer[n++] = vect.x + radius * cosf(theta1);
            cylinderBuffer[n++] = vect.y;
            cylinderBuffer[n++] = vect.z + radius * sinf(theta1);
            cylinderBuffer[n++] = 0.0f; // normal x
            cylinderBuffer[n++] = normalY; // normal y
            cylinderBuffer[n++] = 0.0f; // normal z
            
            cylinderBuffer[n++] = vect.x + radius * cosf(theta2);
            cylinderBuffer[n++] = vect.y;
            cylinderBuffer[n++] = vect.z + radius * sinf(theta2);
            cylinderBuffer[n++] = 0.0f; // normal x
            cylinderBuffer[n++] = normalY; // normal y
            cylinderBuffer[n++] = 0.0f; // normal z
        }
        
        float normalX = cosf(theta1);
        float normalY = sinf(theta1);
        
        // now the side faces, two triangles per facet...
        cylinderBuffer[n++] = centerTop.x + radius * cosf(theta1);
        cylinderBuffer[n++] = centerTop.y;
        cylinderBuffer[n++] = centerTop.z + radius * sinf(theta1);
        cylinderBuffer[n++] = normalX; // normal x
        cylinderBuffer[n++] = 0.0; // normal y
        cylinderBuffer[n++] = normalY; // normal z
        
        cylinderBuffer[n++] = centerTop.x + radius * cosf(theta1);
        cylinderBuffer[n++] = centerBottom.y;
        cylinderBuffer[n++] = centerTop.z + radius * sinf(theta1);
        cylinderBuffer[n++] = normalX; // normal x
        cylinderBuffer[n++] = 0.0; // normal y
        cylinderBuffer[n++] = normalY; // normal z
        
        cylinderBuffer[n++] = centerTop.x + radius * cosf(theta2);
        cylinderBuffer[n++] = centerBottom.y;
        cylinderBuffer[n++] = centerTop.z + radius * sinf(theta2);
        cylinderBuffer[n++] = normalX; // normal x
        cylinderBuffer[n++] = 0.0; // normal y
        cylinderBuffer[n++] = normalY; // normal z
        
        
        cylinderBuffer[n++] = centerTop.x + radius * cosf(theta2);
        cylinderBuffer[n++] = centerBottom.y;
        cylinderBuffer[n++] = centerTop.z + radius * sinf(theta2);
        cylinderBuffer[n++] = normalX; // normal x
        cylinderBuffer[n++] = 0.0; // normal y
        cylinderBuffer[n++] = normalY; // normal z
        
        cylinderBuffer[n++] = centerTop.x + radius * cosf(theta2);
        cylinderBuffer[n++] = centerTop.y;
        cylinderBuffer[n++] = centerTop.z + radius * sinf(theta2);
        cylinderBuffer[n++] = normalX; // normal x
        cylinderBuffer[n++] = 0.0; // normal y
        cylinderBuffer[n++] = normalY; // normal z
        
        cylinderBuffer[n++] = centerTop.x + radius * cosf(theta1);
        cylinderBuffer[n++] = centerTop.y;
        cylinderBuffer[n++] = centerTop.z + radius * sinf(theta1);
        cylinderBuffer[n++] = normalX; // normal x
        cylinderBuffer[n++] = 0.0; // normal y
        cylinderBuffer[n++] = normalY; // normal z
        
        }
    
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
    
    if (self.useCylinders)
    {
        [self generateCylinder];
    }
        
    [self setupGL];
    
    [self updateChartAnimated:NO animationDuration:0.0 options:0];
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
    
    if (!self.useCylinders)
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
    else
    {
        glGenVertexArraysOES(1, &_vertexCylinder);
        glBindVertexArrayOES(_vertexCylinder);
        
        glGenBuffers(1, &_vertexBuffer6);   
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer6);
        glBufferData(GL_ARRAY_BUFFER, 4 * [self numberCylinderFacets] * 6 * 3 * sizeof(float), cylinderBuffer, GL_STATIC_DRAW);
        
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

    { // gTopTextData
        glGenVertexArraysOES(1, &_vertexTopText);
        glBindVertexArrayOES(_vertexTopText);
        
        glGenBuffers(1, &_vertexBuffer7);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer7);
        glBufferData(GL_ARRAY_BUFFER, sizeof(gTopTextData), gTopTextData, GL_STATIC_DRAW);
        
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
        glEnableVertexAttribArray(GLKVertexAttribNormal);
        
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(24));
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    }

    
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
        
    [self setupVBOs];
    
    glEnable(GL_DEPTH_TEST);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
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
    glDeleteBuffers(1, &_vertexBuffer2);
    glDeleteVertexArraysOES(1, &_vertexArrayBasePlane);
    glDeleteBuffers(1, &_vertexBuffer3);
    glDeleteVertexArraysOES(1, &_vertexArrayHLine);
    glDeleteBuffers(1, &_vertexBuffer4);
    glDeleteVertexArraysOES(1, &_vertexArrayVLine);
    glDeleteBuffers(1, &_vertexBuffer5);
    glDeleteVertexArraysOES(1, &_vertexLeftLegendPlane);
    glDeleteBuffers(1, &_vertexBuffer6);
    glDeleteVertexArraysOES(1, &_vertexCylinder);
    glDeleteBuffers(1, &_vertexBuffer7);
    glDeleteVertexArraysOES(1, &_vertexTopText);
    self.effect = nil;
}

#pragma mark - update stuff

- (void)update
{
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    
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

    // the repositioning animation (double tap)
    if (_isAnimatingPosition)
    {
        NSTimeInterval timeRemainingToPositionAnimationCompletion = _positionAnimationCompletionTime-CFAbsoluteTimeGetCurrent();
        
        NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent()-_positionAnimationStartTime;
        NSTimeInterval animationDuration = _positionAnimationCompletionTime-_positionAnimationStartTime;
        
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
    
    if (_isAnimatingBarHeights)
    {
        NSTimeInterval timeRemainingToHeightAnimationCompletion = _barHeightAnimationCompletionTime-CFAbsoluteTimeGetCurrent();
        
        BOOL animationCompleted = YES;

        NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent()-_barHeightsAnimationStartTime;
        NSTimeInterval animationDuration = _barHeightAnimationCompletionTime-_barHeightsAnimationStartTime;

                
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

-(float) startZ
{
    if ([self numberRows] > [self numberColumns])
    {
        return -1.0;
    }
    return -1 + [self cubeWidth] * ( [self numberColumns] - [self numberRows]) / 2.0;
}


-(void) drawLegend
{
    
    float minimumLabelHeight = 0.1;
    float maximumLabelHeight = 0.3;
    
    // draw the legend.
    glEnable(GL_BLEND);
    glBlendFunc( GL_ONE, GL_ONE_MINUS_SRC_ALPHA );

    glDepthMask(GL_FALSE); // required to make the texture bgnd transparent...

    // ideal label size is cubeWidth. however if there are a lot of rows, that turns our unreadable and
    // if there are very vew rows and columns it is freaky big. Adjust the size using minimumLabelHeight
    // and maximumLabelHeight.
    
    float labelHeight = [self cubeWidth];
    if (labelHeight > maximumLabelHeight) labelHeight = maximumLabelHeight;
    if (labelHeight < minimumLabelHeight) labelHeight = minimumLabelHeight;
    float labelHeightDifferenceWithCubeWidth = [self cubeWidth] - labelHeight;
    
    // our image is 300x100 so once scaled (by a labelHeight factor), its length will end up being 3 * labelHeight
    float x = [self startX];
    x -= (300.0/100.0) * labelHeight;
    // add a little bit of a margin:
    x +=  -labelHeight/1.5;
    
    float z = [self startZ] + labelHeightDifferenceWithCubeWidth/2.0f;
    
    for (int i=0; i<([self numberRows]); i++)
    {
        GLKTextureInfo *texture = [self.rowLegendTextures objectForKey:[NSNumber numberWithInt:i]];
        
        if (texture != nil)
        {
            glBindVertexArrayOES(_vertexLeftLegendPlane);
            GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
            GLKVector3 position = GLKVector3Make(x, 0.0, z);
            GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
            GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
            GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
            
            GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale(labelHeight,1.0,labelHeight);
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
        z += [self cubeWidth];
    }
    
    if ([self numberValueLines] > 0)
    {
#define HEIGHT_LABEL_SIZE 0.1
        // our image is 300x100 so its lenght is 3 * cubewidth
        float x = [self startX] - (300.0/100.0) * HEIGHT_LABEL_SIZE - HEIGHT_LABEL_SIZE/2.0;
        float y = 1.0 / [self numberValueLines] + HEIGHT_LABEL_SIZE/2.0;
        float z = [self startZ];
        
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
    
    x = [self startX] + [self cubeWidth] - labelHeightDifferenceWithCubeWidth / 2.0;
    z = [self startZ] + [self cubeWidth] * ([self numberRows] + 1) - [self cubeWidth] + labelHeight / 1.5;

    
    for (int i=0; i<([self numberColumns]); i++)
    {
        GLKTextureInfo *texture = [self.columnLegendTextures objectForKey:[NSNumber numberWithInt:i]];
        
        if (texture != nil)
        {
            glBindVertexArrayOES(_vertexLeftLegendPlane);
            GLKVector3 rotation = GLKVector3Make(0.0, -M_PI_2, 0.0);
            GLKVector3 position = GLKVector3Make(x, 0.0, z);
            GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
            GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
            GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
            GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale(labelHeight, 1.0, labelHeight);
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
    
    glDepthMask(GL_TRUE);
    glDisable(GL_BLEND);
}


-(void) drawTopText
{
    // draw the legend.
    glEnable(GL_BLEND);
    glBlendFunc( GL_ONE, GL_ONE_MINUS_SRC_ALPHA );
    
    glDepthMask(GL_FALSE); // required to make the texture bgnd transparent...
    
    float x = [self startX];
    float z = [self startZ];
    
    float marginRatio = 0.8; // 20% margin on all sides...
    
    // our image is 300x100 so once scaled (by a labelHeight factor), its length will end up being 3 * labelHeight
    for (int i=0; i<[self numberRows]; i++)
    {
        for (int j=0; j< [self numberColumns]; j++)
        {
            if ([self hasBarForRow:i column:j])
            {
                GLKTextureInfo *texture = [self.topLabelTextures objectForKey:[NSNumber numberWithInt:COLUMNOFFSETID * i + j]];
                
                if (texture != nil)
                {
                    glBindVertexArrayOES(_vertexTopText);
                    
                    float percentSize = [self cubePercentSizeForBarAtRow:i column:j] * marginRatio;
                    float height = _currentBarHeights[i*[self numberColumns] + j];
                    
                    GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
                    GLKVector3 position = GLKVector3Make(x, // make sure our bar is centered in the grid cell
                                                         height + 0.001,
                                                         z );
                    
                    GLKMatrix4 xRotationMatrix = GLKMatrix4MakeXRotation(rotation.x);
                    GLKMatrix4 yRotationMatrix = GLKMatrix4MakeYRotation(rotation.y);
                    GLKMatrix4 zRotationMatrix = GLKMatrix4MakeZRotation(rotation.z);
                    

                    GLKMatrix4 scaleMatrix     = GLKMatrix4MakeScale([self cubeWidth] * percentSize,
                                                                     0.0,
                                                                     [self cubeWidth] * percentSize);
                    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(position.x + [self cubeWidth] *(1-percentSize)/2.0, position.y, position.z + [self cubeWidth] *(1-percentSize)/2.0);
                    
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
            }
            x += [self cubeWidth];
        }
        x = [self startX];
        z += [self cubeWidth];
    }
    glBindVertexArrayOES(0);
    
    glDepthMask(GL_TRUE);
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
        float z = [self startZ];
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
        float z = [self startZ];
        
        self.effect.light0.diffuseColor = GLKVector4Make(0.7f,0.7f,0.7f, 0.8f);
        self.effect.material.diffuseColor = GLKVector4Make(0.7f,0.7f,0.7f, 0.8f);
        
        self.effect.texture2d0.enabled = GL_FALSE;
        
        glBindVertexArrayOES(_vertexArrayBasePlane);
        GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
        GLKVector3 position = GLKVector3Make(x, 0.0, z);
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
    
    float z = [self startZ];
    float x = [self startX];
    for (int i=0; i<([self numberRows] + 1); i++)
    {
        GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
        GLKVector3 position = GLKVector3Make(x, 0.0, z);
        z += [self cubeWidth];
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
    z = [self startZ];
    x = [self startX];
    for (int i=0; i<([self numberColumns] + 1); i++)
    {
        GLKVector3 rotation = GLKVector3Make(0.0, 0.0, 0.0);
        GLKVector3 position = GLKVector3Make(x, 0.0, z);
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


-(void) drawBars
{
    // draw the cubes
    
    if (!self.useCylinders)
        glBindVertexArrayOES(_vertexArray);
    else
        glBindVertexArrayOES(_vertexCylinder);
    
    float x = [self startX];
    float z = [self startZ];
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
                                                     z + ([self cubeWidth] * (1-percentSize))/2.0);
                
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
                
                if (!self.useCylinders)
                    glDrawArrays(GL_TRIANGLES, 0, 36);
                else
                    glDrawArrays(GL_TRIANGLES, 0, 4 * [self numberCylinderFacets] * 3);

                
            }
            x += [self cubeWidth];
        }
        z += [self cubeWidth];
        x = [self startX];
    }
    glBindVertexArrayOES(0);
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
 
    float radius = 4.0; // we are moving around the chart at 4 units from the center.
    float startAngle = -3.1 * M_PI/4.0;
    
    self.effect.light0.position = GLKVector4Make(radius * cos(_offsetX - startAngle), 4.0 * (1.0+_offsetY), radius * sinf(_offsetX - startAngle), 0.0);
    
    [self drawGrid];
    
    [self drawValueLines];

    [self drawBars];
    
    [self drawTopText];
    
    // drawLegend must drawn last because I am disabling the glDepthMask in it and that messes things up, 
    // even though I am reenabling it at the end of drawLegend. I'd like to understand why. Some day.
    // see http://stackoverflow.com/questions/9353210/rendering-glitch-with-gl-depth-test-and-transparent-textures 
    // answer from SigTerm.
    [self drawLegend];
}


-(void) dealloc
{
    [self tearDownGL];
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_targetBarHeights) free(_targetBarHeights);
    if (_currentBarHeights) free(_currentBarHeights);
    if (_barHeightAnimationDeltas) free(_barHeightAnimationDeltas);
    if (_targetColors) free(_targetColors);
    if (_currentColors) free(_currentColors);
    if (_colorDeltas) free(_colorDeltas);
    if (cylinderBuffer) free(cylinderBuffer);
}

@end
