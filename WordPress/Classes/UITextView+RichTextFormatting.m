#import "UITextView+RichTextFormatting.h"

@implementation UITextView (RichTextFormatting)

- (void)addOrRemoveFontTraitWithName:(NSString *)traitName andValue:(uint32_t)traitValue {
    NSRange selectedRange = [self selectedRange];
    
    NSDictionary *currentAttributesDict = [self.textStorage attributesAtIndex:selectedRange.location
                                                               effectiveRange:nil];
    
    UIFont *currentFont = [currentAttributesDict objectForKey:NSFontAttributeName];
    
    UIFontDescriptor *fontDescriptor = [currentFont fontDescriptor];
    
    NSString *fontNameAttribute = [[fontDescriptor fontAttributes] objectForKey:UIFontDescriptorNameAttribute];
    UIFontDescriptor *changedFontDescriptor;
    
    if ([fontNameAttribute rangeOfString:traitName].location == NSNotFound) {
        uint32_t existingTraitsWithNewTrait = [fontDescriptor symbolicTraits] | traitValue;
        changedFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:existingTraitsWithNewTrait];
    }
    else{
        uint32_t existingTraitsWithoutTrait = [fontDescriptor symbolicTraits] & ~traitValue;
        changedFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:existingTraitsWithoutTrait];
    }
    
    UIFont *updatedFont = [UIFont fontWithDescriptor:changedFontDescriptor size:0.0];
    
    NSDictionary *dict = @{NSFontAttributeName: updatedFont};
    
    [self.textStorage beginEditing];
    [self.textStorage setAttributes:dict range:selectedRange];
    [self.textStorage endEditing];
}

- (void)underlineText {
    NSRange selectedRange = [self selectedRange];
    
    NSDictionary *currentAttributesDict = [self.textStorage attributesAtIndex:selectedRange.location
                                                               effectiveRange:nil];
    
    NSDictionary *dict;
    
    if ([currentAttributesDict objectForKey:NSUnderlineStyleAttributeName] == nil ||
        [[currentAttributesDict objectForKey:NSUnderlineStyleAttributeName] intValue] == 0) {
        
        dict = @{NSUnderlineStyleAttributeName: [NSNumber numberWithInt:1]};
        
    }
    else{
        dict = @{NSUnderlineStyleAttributeName: [NSNumber numberWithInt:0]};
    }
    
    [self.textStorage beginEditing];
    [self.textStorage setAttributes:dict range:selectedRange];
    [self.textStorage endEditing];
}

@end
