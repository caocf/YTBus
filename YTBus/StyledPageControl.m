//
//  PageControl.m
//  PageControlDemo
//
/**
 * Created by honcheng on 5/14/11.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining 
 * a copy of this software and associated documentation files (the 
 * "Software"), to deal in the Software without restriction, including 
 * without limitation the rights to use, copy, modify, merge, publish, 
 * distribute, sublicense, and/or sell copies of the Software, and to 
 * permit persons to whom the Software is furnished to do so, subject 
 * to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be 
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT 
 * WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR 
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT 
 * SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
 * IN CONNECTION WITH THE SOFTWARE OR 
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * @author 		Muh Hon Cheng <honcheng@gmail.com> http://twitter.com/honcheng
 * @copyright	2011	Muh Hon Cheng
 * 
 */

#import "StyledPageControl.h"


@implementation StyledPageControl

#define COLOR_GRAYISHBLUE [UIColor colorWithRed:128/255.0 green:130/255.0 blue:133/255.0 alpha:1]
#define COLOR_GRAY [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1]

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
       
    }
    return self;
}
-(id)initWithCoder:(NSCoder *)aDecoder{
	self=[super initWithCoder:aDecoder];
	if (self) {
		[self setup];
	}
	return self;
}

-(void)setup{
	[self setBackgroundColor:[UIColor clearColor]];
	
	_strokeWidth = 2;
	_gapWidth = 10;
	_diameter = 12;
	_pageControlStyle = PageControlStyleDefault;
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapped:)];
	[self addGestureRecognizer:tapGestureRecognizer];
}

- (void)onTapped:(UITapGestureRecognizer*)gesture
{
    CGPoint touchPoint = [gesture locationInView:[gesture view]];
    
    if (touchPoint.x < self.frame.size.width/2)
    {
        // move left
        if (self.currentPage>0)
        {
            if (touchPoint.x <= 22)
            {
                self.currentPage = 0;
            }
            else
            {
                self.currentPage -= 1;
            }
        }
        
    }
    else
    {
        // move right
        if (self.currentPage<self.numberOfPages-1)
        {
            if (touchPoint.x >= (CGRectGetWidth(self.bounds) - 22))
            {
                self.currentPage = self.numberOfPages-1;
            }
            else
            {
                self.currentPage += 1;
            }
        }
    }
    [self setNeedsDisplay];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)drawRect:(CGRect)rect
{
    UIColor *coreNormalColor, *coreSelectedColor, *strokeNormalColor, *strokeSelectedColor;
    
    if (self.coreNormalColor) coreNormalColor = self.coreNormalColor;
    else coreNormalColor = COLOR_GRAYISHBLUE;
    
    if (self.coreSelectedColor) coreSelectedColor = self.coreSelectedColor;
    else
    {
        if (self.pageControlStyle==PageControlStyleStrokedSquare || self.pageControlStyle==PageControlStyleStrokedCircle || self.pageControlStyle==PageControlStyleWithPageNumber)
        {
            coreSelectedColor = COLOR_GRAYISHBLUE;
        }
        else
        {
            coreSelectedColor = COLOR_GRAY;
        }
    }
    
    if (self.strokeNormalColor) strokeNormalColor = self.strokeNormalColor;
    else 
    {
        if (self.pageControlStyle==PageControlStyleDefault && self.coreNormalColor)
        {
            strokeNormalColor = self.coreNormalColor;
        }
        else
        {
            strokeNormalColor = COLOR_GRAYISHBLUE;
        }
        
    }
    
    if (self.strokeSelectedColor) strokeSelectedColor = self.strokeSelectedColor;
    else
    {
        if (self.pageControlStyle==PageControlStyleStrokedSquare || self.pageControlStyle==PageControlStyleStrokedCircle || self.pageControlStyle==PageControlStyleWithPageNumber)
        {
            strokeSelectedColor = COLOR_GRAYISHBLUE;
        }
        else if (self.pageControlStyle==PageControlStyleDefault && self.coreSelectedColor)
        {
            strokeSelectedColor = self.coreSelectedColor;
        }
        else
        {
            strokeSelectedColor = COLOR_GRAY;
        }
    }
    
    // Drawing code
    if (self.hidesForSinglePage && self.numberOfPages==1)
	{
		return;
	}
	
	CGContextRef myContext = UIGraphicsGetCurrentContext();
	
	int gap = self.gapWidth;
    float diameter = self.diameter - 2*self.strokeWidth;
    
    if (self.pageControlStyle==PageControlStyleThumb)
    {
        if (self.thumbImage && self.selectedThumbImage)
        {
            diameter = self.thumbImage.size.width;
        }
    }
	
	int total_width = self.numberOfPages*diameter + (self.numberOfPages-1)*gap;
	
	if (total_width>self.frame.size.width)
	{
		while (total_width>self.frame.size.width)
		{
			diameter -= 2;
			gap = diameter + 2;
			while (total_width>self.frame.size.width) 
			{
				gap -= 1;
				total_width = self.numberOfPages*diameter + (self.numberOfPages-1)*gap;
				
				if (gap==2)
				{
					break;
					total_width = self.numberOfPages*diameter + (self.numberOfPages-1)*gap;
				}
			}
			
			if (diameter==2)
			{
				break;
				total_width = self.numberOfPages*diameter + (self.numberOfPages-1)*gap;
			}
		}
		
		
	}
	
	int i;
	for (i=0; i<self.numberOfPages; i++)
	{
		int x = (self.frame.size.width-total_width)/2 + i*(diameter+gap);

        if (self.pageControlStyle==PageControlStyleDefault)
        {
            if (i==self.currentPage)
            {
                CGContextSetFillColorWithColor(myContext, [coreSelectedColor CGColor]);
                CGContextFillEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
                CGContextSetStrokeColorWithColor(myContext, [strokeSelectedColor CGColor]);
                CGContextStrokeEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
            }
            else
            {
                CGContextSetFillColorWithColor(myContext, [coreNormalColor CGColor]);
                CGContextFillEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
                CGContextSetStrokeColorWithColor(myContext, [strokeNormalColor CGColor]);
                CGContextStrokeEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
            }
        }
        else if (self.pageControlStyle==PageControlStyleStrokedCircle)
        {
            CGContextSetLineWidth(myContext, self.strokeWidth);
            if (i==self.currentPage)
            {
                CGContextSetFillColorWithColor(myContext, [coreSelectedColor CGColor]);
                CGContextFillEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
                CGContextSetStrokeColorWithColor(myContext, [strokeSelectedColor CGColor]);
                CGContextStrokeEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
            }
            else
            {
                CGContextSetStrokeColorWithColor(myContext, [strokeNormalColor CGColor]);
                CGContextStrokeEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
            }
        }
        else if (self.pageControlStyle==PageControlStyleStrokedSquare)
        {
            CGContextSetLineWidth(myContext, self.strokeWidth);
            if (i==self.currentPage)
            {
                CGContextSetFillColorWithColor(myContext, [coreSelectedColor CGColor]);
                CGContextFillRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
                CGContextSetStrokeColorWithColor(myContext, [strokeSelectedColor CGColor]);
                CGContextStrokeRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
            }
            else
            {
                CGContextSetStrokeColorWithColor(myContext, [strokeNormalColor CGColor]);
                CGContextStrokeRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
            }
        }
        else if (self.pageControlStyle==PageControlStyleWithPageNumber)
        {
            CGContextSetLineWidth(myContext, self.strokeWidth);
            if (i == self.currentPage%_pointPerPage)
            {
                int _currentPageHeight = self.pageNumberStyleRectSize.height;
                int _currentPageWidth = self.pageNumberStyleRectSize.width; // width=20 满足fontSize=10的三位数的宽度
                float originX = (self.frame.size.width-total_width)/2 + i*(diameter+gap) - (_currentPageWidth-diameter)/2;
                float originY = (self.frame.size.height-_currentPageHeight)/2;
                // 矩形边框范围 CGRectMake(x,(self.frame.size.height-_currentPageHeight)/2,_currentPageWidth,_currentPageHeight)
                
                CGContextSetFillColorWithColor(myContext, [coreSelectedColor CGColor]);
                CGContextSetStrokeColorWithColor(myContext, [strokeSelectedColor CGColor]);
                // 椭圆边框
//                CGContextFillEllipseInRect(myContext, CGRectMake(originX,originY,_currentPageWidth,_currentPageHeight));
//                CGContextStrokeEllipseInRect(myContext, CGRectMake(originX,originY,_currentPageWidth,_currentPageHeight));
                
                // 圆角矩形边框
                float radius = 6.5f;
                CGMutablePathRef rectPath = CGPathCreateMutable();
                CGPathMoveToPoint(rectPath, NULL, originX+radius, originY);

                CGPathAddArcToPoint(rectPath, NULL,originX+_currentPageWidth, originY,
                                    originX+_currentPageWidth, originY+_currentPageHeight-radius,radius);
                CGPathAddArcToPoint(rectPath, NULL,originX+_currentPageWidth, originY+_currentPageHeight,
                                    originX+radius, originY+_currentPageHeight,radius);
                CGPathAddArcToPoint(rectPath, NULL,originX, originY+_currentPageHeight,
                                    originX, originY+radius,radius);
                CGPathAddArcToPoint(rectPath, NULL,originX,originY,
                                    originX+radius,originY,radius);
                CGPathCloseSubpath(rectPath);
                // 纵向阴影
                CGContextAddPath(myContext, rectPath);
                CFRelease(rectPath);
                CGContextSaveGState(myContext);
                CGContextSetShadowWithColor(myContext, CGSizeMake(0, 1.0), 1.0, [UIColor whiteColor].CGColor);
                CGContextFillPath(myContext);
                CGContextRestoreGState(myContext);
                
            
                NSString *pageNumber = [NSString stringWithFormat:@"%i", self.currentPage+1];
                CGContextSetFillColorWithColor(myContext, [[UIColor whiteColor] CGColor]);
                [pageNumber drawInRect:CGRectMake(originX,originY,_currentPageWidth,_currentPageHeight) withFont:[UIFont systemFontOfSize:10] lineBreakMode:UILineBreakModeCharacterWrap alignment:NSTextAlignmentCenter];
            }
            else
            {
                CGContextSetFillColorWithColor(myContext, [coreNormalColor CGColor]);
                CGContextFillEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
                CGContextSetStrokeColorWithColor(myContext, [strokeNormalColor CGColor]);
                CGContextStrokeEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
            }
        }
        else if (self.pageControlStyle==PageControlStylePressed1 || self.pageControlStyle==PageControlStylePressed2)
        {
            if (self.pageControlStyle==PageControlStylePressed1)
            {
                CGContextSetFillColorWithColor(myContext, [[UIColor colorWithRed:0 green:0 blue:0 alpha:1] CGColor]);
                CGContextFillEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2-1,diameter,diameter));
            }
            else if (self.pageControlStyle==PageControlStylePressed2)
            {
                CGContextSetFillColorWithColor(myContext, [[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1] CGColor]);
                CGContextFillEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2+1,diameter,diameter));
            }
            
            
            if (i==self.currentPage)
            {
                CGContextSetFillColorWithColor(myContext, [coreSelectedColor CGColor]);
                CGContextFillEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
                CGContextSetStrokeColorWithColor(myContext, [strokeSelectedColor CGColor]);
                CGContextStrokeEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
            }
            else
            {
                CGContextSetFillColorWithColor(myContext, [coreNormalColor CGColor]);
                CGContextFillEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
                CGContextSetStrokeColorWithColor(myContext, [strokeNormalColor CGColor]);
                CGContextStrokeEllipseInRect(myContext, CGRectMake(x,(self.frame.size.height-diameter)/2,diameter,diameter));
            }
        }
        else if (self.pageControlStyle==PageControlStyleThumb)
        {
            UIImage* thumbImage = [self thumbImageForIndex:i];
            UIImage* selectedThumbImage = [self selectedThumbImageForIndex:i];
            
            if (thumbImage && selectedThumbImage)
            {
                if (i==self.currentPage)
                {
                    [selectedThumbImage drawInRect:CGRectMake(x,(self.frame.size.height-selectedThumbImage.size.height)/2,selectedThumbImage.size.width,selectedThumbImage.size.height)];
                }
                else
                {
                    [thumbImage drawInRect:CGRectMake(x,(self.frame.size.height-thumbImage.size.height)/2,thumbImage.size.width,thumbImage.size.height)];
                }
            }
        }
	}
}

- (void)setPageControlStyle:(PageControlStyle)style
{
    _pageControlStyle = style;
    [self setNeedsDisplay];
}

- (void)setCurrentPage:(int)currentPoint
{
    if (_pointPerPage != 0){
        // 当前点在总的第几页,从1开始
        int currentPointInWhichPage = currentPoint/_pointPerPage+1 ;
        // 总的页数,从1开始
        int pointTotalPages = (self.allNumberOfPoints+_pointPerPage-1)/_pointPerPage;
        // numberOfPages 代表当前点所在页的总的点数
        if(currentPointInWhichPage < pointTotalPages){
            self.numberOfPages = _pointPerPage;
        }else{
            self.numberOfPages = self.allNumberOfPoints - (pointTotalPages-1)*_pointPerPage;
        }
    }
    _currentPage = currentPoint;
    [self setNeedsDisplay];
}

- (void)setNumberOfPages:(int)numOfPages
{
    _numberOfPages = numOfPages;
    [self setNeedsDisplay];
}

- (void)setThumbImage:(UIImage *)aThumbImage forIndex:(NSInteger)index {
    if (self.thumbImageForIndex == nil) {
        [self setThumbImageForIndex:[NSMutableDictionary dictionary]];
    }
    
    if ((aThumbImage != nil))
        [self.thumbImageForIndex setObject:aThumbImage forKey:@(index)];
    else
        [self.thumbImageForIndex removeObjectForKey:@(index)];
    
    [self setNeedsDisplay];
}

- (UIImage *)thumbImageForIndex:(NSInteger)index {
    UIImage* aThumbImage = [self.thumbImageForIndex objectForKey:@(index)];
    if (aThumbImage == nil)
        aThumbImage = self.thumbImage;
    
    return aThumbImage;
}

- (void)setSelectedThumbImage:(UIImage *)aSelectedThumbImage forIndex:(NSInteger)index {
    if (self.selectedThumbImageForIndex == nil) {
        [self setSelectedThumbImageForIndex:[NSMutableDictionary dictionary]];
    }
    
    if ((aSelectedThumbImage != nil))
        [self.selectedThumbImageForIndex setObject:aSelectedThumbImage forKey:@(index)];
    else
        [self.selectedThumbImageForIndex removeObjectForKey:@(index)];
    
    [self setNeedsDisplay];
}

- (UIImage *)selectedThumbImageForIndex:(NSInteger)index {
    UIImage* aSelectedThumbImage = [self.selectedThumbImageForIndex objectForKey:@(index)];
    if (aSelectedThumbImage == nil)
        aSelectedThumbImage = self.selectedThumbImage;
    
    return aSelectedThumbImage;
}

@end
