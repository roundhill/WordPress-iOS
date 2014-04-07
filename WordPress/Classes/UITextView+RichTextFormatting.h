#import <UIKit/UIKit.h>

@interface UITextView (RichTextFormatting)

- (void)addOrRemoveFontTraitWithName:(NSString *)traitName andValue:(uint32_t)traitValue;
- (void)underlineText;

@end



