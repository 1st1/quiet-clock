#import <Foundation/Foundation.h>

id QCApplyBackground(id result);

// Stand-in for the system descriptor exercises secure decoding and replacement.
@interface CHSWidgetDescriptor : NSObject <NSSecureCoding, NSMutableCopying>
@property(copy) NSString *kind;
@property BOOL backgroundRemovable;
@property BOOL transparent;
@property NSInteger preferredBackgroundStyle;
@end
@implementation CHSWidgetDescriptor
+ (BOOL)supportsSecureCoding { return YES; }
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        _kind = [coder decodeObjectOfClass:NSString.class forKey:@"kind"];
        _backgroundRemovable = [coder decodeBoolForKey:@"removable"];
        _transparent = [coder decodeBoolForKey:@"transparent"];
        _preferredBackgroundStyle = [coder decodeIntegerForKey:@"style"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.kind forKey:@"kind"];
    [coder encodeBool:self.backgroundRemovable forKey:@"removable"];
    [coder encodeBool:self.transparent forKey:@"transparent"];
    [coder encodeInteger:self.preferredBackgroundStyle forKey:@"style"];
}
- (id)mutableCopyWithZone:(NSZone *)zone {
    CHSWidgetDescriptor *copy = [CHSWidgetDescriptor new];
    copy.kind = self.kind;
    copy.backgroundRemovable = self.backgroundRemovable;
    copy.transparent = self.transparent;
    copy.preferredBackgroundStyle = self.preferredBackgroundStyle;
    return copy;
}
@end

@interface TestResult : NSObject <NSSecureCoding>
@property(copy) NSArray *widgets;
@property(copy) NSString *unrelated;
@end
@implementation TestResult
+ (BOOL)supportsSecureCoding { return YES; }
- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        _widgets = [coder decodeObjectOfClasses:[NSSet setWithObjects:NSArray.class, CHSWidgetDescriptor.class, nil] forKey:@"widgets"];
        _unrelated = [coder decodeObjectOfClass:NSString.class forKey:@"unrelated"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.widgets forKey:@"widgets"];
    [coder encodeObject:self.unrelated forKey:@"unrelated"];
}
@end

// @lat: [[tests#Validation#Private descriptor controls]]
int main(void) {
    @autoreleasepool {
        CHSWidgetDescriptor *clock = [CHSWidgetDescriptor new]; clock.kind = @"QuietClock";
        CHSWidgetDescriptor *other = [CHSWidgetDescriptor new]; other.kind = @"Other";
        TestResult *input = [TestResult new]; input.widgets = @[clock, other]; input.unrelated = @"preserved";
        TestResult *output = QCApplyBackground(input);
        CHSWidgetDescriptor *edited = output.widgets[0];
        assert(output != input && edited.transparent && edited.backgroundRemovable && edited.preferredBackgroundStyle == 1);
        assert(!clock.transparent && ![(CHSWidgetDescriptor *)output.widgets[1] transparent]);
        assert([output.unrelated isEqual:input.unrelated]);
        NSObject *uncodable = [NSObject new];
        assert(QCApplyBackground(uncodable) == uncodable);
        clock.preferredBackgroundStyle = 2;
        output = QCApplyBackground(input);
        edited = output.widgets[0];
        assert(edited.transparent && edited.backgroundRemovable && edited.preferredBackgroundStyle == 1);
        puts("Private descriptor controls, isolation, and fallback checks passed.");
    }
}
