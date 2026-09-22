#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <os/log.h>

// @lat: [[architecture#Architecture#Transparent background]]
// The descriptor flags were identified by pookjw/ClearAndBlurredWidgets.
// Use a native secure-coding round trip instead of rebuilding private Swift objects
// by directly invoking their Objective-C initializers.
@interface QCDescriptorEditor : NSObject <NSKeyedUnarchiverDelegate>
@end

@implementation QCDescriptorEditor
- (id)unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object {
    Class descriptorClass = NSClassFromString(@"CHSWidgetDescriptor");
    if (!descriptorClass || ![object isKindOfClass:descriptorClass]) return object;
    SEL kind = NSSelectorFromString(@"kind");
    if (![object respondsToSelector:kind] ||
        ![((id (*)(id, SEL))objc_msgSend)(object, kind) isEqual:@"QuietClock"] ||
        ![object respondsToSelector:@selector(mutableCopyWithZone:)]) return object;
    id edited = [object mutableCopy];
    SEL removable = NSSelectorFromString(@"setBackgroundRemovable:");
    SEL transparent = NSSelectorFromString(@"setTransparent:");
    SEL style = NSSelectorFromString(@"setPreferredBackgroundStyle:");
    if (![edited respondsToSelector:removable] || ![edited respondsToSelector:transparent] ||
        ![edited respondsToSelector:style]) return object;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(edited, removable, YES);
    ((void (*)(id, SEL, BOOL))objc_msgSend)(edited, transparent, YES);
    ((void (*)(id, SEL, NSInteger))objc_msgSend)(edited, style, 1);
    os_log(OS_LOG_DEFAULT, "QCBackground: descriptor flags applied");
    return edited;
}
@end

// Kept separate so failure and round-trip behavior can be tested without WidgetKit.
id QCApplyBackground(id result) {
    @try {
        NSError *error = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:result requiringSecureCoding:YES error:&error];
        if (!data || error) { os_log(OS_LOG_DEFAULT, "QCBackground: archive failed %{public}@", error); return result; }
        NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
        if (!decoder || error) return result;
        decoder.requiresSecureCoding = YES;
        decoder.decodingFailurePolicy = NSDecodingFailurePolicySetErrorAndReturn;
        QCDescriptorEditor *editor = [QCDescriptorEditor new];
        decoder.delegate = editor;
        id replacement = [decoder decodeObjectOfClass:[result class] forKey:NSKeyedArchiveRootObjectKey];
        [decoder finishDecoding];
        os_log(OS_LOG_DEFAULT, "QCBackground: decode result=%{public}@ error=%{public}@", NSStringFromClass([replacement class]), decoder.error);
        return replacement && !decoder.error ? replacement : result;
    } @catch (NSException *exception) {
        os_log(OS_LOG_DEFAULT, "QCBackground: fallback %{public}@", exception);
        return result;
    }
}

@interface QCBackgroundHook : NSObject
@end
@implementation QCBackgroundHook
+ (void)load {
    Class server = NSClassFromString(@"_TtCC9WidgetKit24WidgetExtensionXPCServer14ExportedObject");
    os_log(OS_LOG_DEFAULT, "QCBackground: hook server=%{public}@", server);
    if (!server) return;
    for (NSString *name in @[@"getAllCurrentDescriptorsWithCompletion:", @"getCurrentDescriptorsWithCompletion:"]) {
        Method method = class_getInstanceMethod(server, NSSelectorFromString(name));
        if (!method || method_getNumberOfArguments(method) != 3) continue;
        char argument[16] = {0};
        method_getArgumentType(method, 2, argument, sizeof(argument));
        char returnType[16] = {0};
        method_getReturnType(method, returnType, sizeof(returnType));
        if (strcmp(argument, "@?") || strcmp(returnType, "v")) continue;
        SEL selector = NSSelectorFromString(name);
        void (*original)(id, SEL, void (^)(id)) = (void *)method_getImplementation(method);
        IMP hook = imp_implementationWithBlock(^(id receiver, void (^completion)(id)) {
            original(receiver, selector, ^(id result) {
                id edited = result;
                @try {
                    os_log(OS_LOG_DEFAULT, "QCBackground: fetched %{public}@; requesting permanent transparency", NSStringFromClass([result class]));
                    edited = QCApplyBackground(result);
                }
                @catch (NSException *exception) { /* Preserve the original descriptor. */ }
                completion(edited);
            });
        });
        method_setImplementation(method, hook);
        os_log(OS_LOG_DEFAULT, "QCBackground: installed %{public}@", name);
    }
}
@end
