//
//  NativePaymentWidgetViewRegistry.m
//

#import "NativePaymentWidgetViewRegistry.h"

@implementation NativePaymentWidgetViewRegistry {
    // Weak values so views are removed automatically when deallocated.
    NSMapTable<NSNumber *, UIView *> *_map;
}

+ (instancetype)shared {
    static NativePaymentWidgetViewRegistry *sInstance = nil;
    static dispatch_once_t sOnce;
    dispatch_once(&sOnce, ^{
        sInstance = [[NativePaymentWidgetViewRegistry alloc] init];
    });
    return sInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        // Strong keys (NSNumber is value-like), weak object values.
        _map = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}

- (void)registerView:(UIView *)view forTag:(NSNumber *)tag {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_map setObject:view forKey:tag];
    });
}

- (void)unregisterForTag:(NSNumber *)tag {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_map removeObjectForKey:tag];
    });
}

- (nullable UIView *)viewForTag:(NSNumber * _Nonnull)tag {
    @synchronized (self) {
        return [_map objectForKey:tag];
    }
}

@end
