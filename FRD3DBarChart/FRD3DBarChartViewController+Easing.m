//
//  FRD3DBarChartViewController+Easing.m
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


#import "FRD3DBarChartViewController+Easing.h"

@implementation FRD3DBarChartViewController (Easing)

// easing equations grabbed from http://gizma.com/easing/
//

-(float) linearEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
    return c * t / d + b;
}

// quadratic easing in - accelerating from zero velocity

-(float) quadraticInEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d;
	return c*t*t + b;
}


// quadratic easing out - decelerating to zero velocity
-(float) quadraticOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d;
	return -c * t*(t-2) + b;
}


// quadratic easing in/out - acceleration until halfway, then deceleration
-(float) quadraticInOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d/2;
	if (t < 1) return c/2*t*t + b;
	t--;
	return -c/2 * (t*(t-2) - 1) + b;
}


-(float) expoOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
    return c * ( -pow( 2, -10 * t/d ) + 1 ) + b;
}

-(float) expoInEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
    return c * pow( 2, 10 * (t/d - 1) ) + b;
}

-(float) expoInOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
    t /= d/2;
    if (t < 1) return c/2 * pow( 2, 10 * (t - 1) ) + b;
    t--;
    return c/2 * ( -pow( 2, -10 * t) + 2 ) + b;
}

-(float) circularOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
    t /= d;
	t--;
	return c * sqrt(1 - t*t) + b;
}
-(float) circularInEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
    t /= d;
	return -c * (sqrt(1 - t*t) - 1) + b;
}
-(float) circularInOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
    t /= d/2;
	if (t < 1) return -c/2 * (sqrt(1 - t*t) - 1) + b;
	t -= 2;
	return c/2 * (sqrt(1 - t*t) + 1) + b;
}


// sinusoidal easing in - accelerating from zero velocity
-(float) sinInEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
    return -c * cosf(t/d * (M_PI_2)) + c + b;
}

// sinusoidal easing out - decelerating to zero velocity
-(float) sinOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	return c * sinf(t/d * (M_PI_2)) + b;
}


// sinusoidal easing in/out - accelerating until halfway, then decelerating
-(float) sinInOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	return -c/2 * (cosf(M_PI*t/d) - 1) + b;
}

// cubic easing in - accelerating from zero velocity
-(float) cubicInEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d;
	return c*t*t*t + b;
}

// cubic easing out - decelerating to zero velocity
-(float) cubicOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d;
	t--;
	return c*(t*t*t + 1) + b;
}

// cubic easing in/out - acceleration until halfway, then deceleration
-(float) cubicInOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d/2;
	if (t < 1) return c/2*t*t*t + b;
	t -= 2;
	return c/2*(t*t*t + 2) + b;
}


// quartic easing in - accelerating from zero velocity
-(float) quarticInEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d;
	return c*t*t*t*t + b;
}

// quartic easing out - decelerating to zero velocity
-(float) quarticOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d;
	t--;
	return -c * (t*t*t*t - 1) + b;
}

// quartic easing in/out - acceleration until halfway, then deceleration
-(float) quarticInOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d/2;
	if (t < 1) return c/2*t*t*t*t + b;
	t -= 2;
	return -c/2 * (t*t*t*t - 2) + b;
}


// quintic easing in - accelerating from zero velocity
-(float) quinticInEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d;
	return c*t*t*t*t*t + b;
}


// quintic easing out - decelerating to zero velocity
-(float) quinticOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d;
	t--;
	return c*(t*t*t*t*t + 1) + b;
}


// quintic easing in/out - acceleration until halfway, then deceleration
-(float) quinticInOutEasingWithCurrentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
	t /= d/2;
	if (t < 1) return c/2*t*t*t*t*t + b;
	t -= 2;
	return c/2*(t*t*t*t*t + 2) + b;
}

-(float) easingWithMethod:(kEasingMethods)method currentTime:(NSTimeInterval) t  startValue:(float) b changeInValue:(float) c duration:(NSTimeInterval) d
{
    switch (method)
    {
        case kEasingMethodLinear:
            return [self quarticInOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodQuadraticIn:
            return [self quadraticInEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodQuadraticOut:
            return [self quadraticInOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodQuadraticInOut:
            return [self quadraticInOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodCubicIn:
            return [self cubicInEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodCubicOut:
            return [self cubicOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodCubicInOut:
            return [self cubicInOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodQuarticIn:
            return [self quarticInEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodQuarticOut:
            return [self quarticOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodQuarticInOut:
            return [self quarticInOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodQuinticIn:
            return [self quinticInEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodQuinticOut:
            return [self quinticOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodQuinticInOut:
            return [self quinticInOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodExponentialIn:
            return [self expoInEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodExponentialOut:
            return [self expoOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodExponentialInOut:
            return [self expoInOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodCircularIn:
            return [self circularInEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodCircularOut:
            return [self circularOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodCircularInOut:
            return [self circularInOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodSinIn:
            return [self sinInEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodSinOut:
            return [self sinOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        case kEasingMethodSinInOut:
            return [self sinInOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
        default:
            return [self quinticOutEasingWithCurrentTime:t startValue:b changeInValue:c duration:d];
            break;
    }
}


@end
