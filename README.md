#YSImageRequest

[SDWebImage](https://github.com/rs/SDWebImage) + [UIImage filter](https://github.com/yusuga/YSImageFilter).

##Usage

```
YSImageFilter *filter = [[YSImageFilter alloc] init];
filter.size = CGSizeMake(200.f, 200.f);
filter.quality = kCGInterpolationHigh;
filter.trimToFit = NO;
filter.mask = YSImageFilterMaskRoundedCorners;
filter.borderWidth = 5.f;
filter.borderColor = [UIColor redColor];
filter.maskCornerRadius = 10.f;
    
[self.imageView ys_setImageWithURL:url
                  placeholderImage:placeholder
                            filter:filter
                          progress:progressBlock
                        completion:completion];
```