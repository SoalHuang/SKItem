//
//  SKBaseItem.m
//  SOKit
//
//  Created by so on 16/5/30.
//  Copyright © 2016年 com.. All rights reserved.
//

#import <objc/runtime.h>
#import "SKBaseItem.h"

static NSMutableDictionary * _SKItemPropertyKeyListCache = nil;

static NSArray * _SKItemPropertyKeyIgnoreKeys = nil;

NSDictionary * SKParseProperty(objc_property_t property) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    const char *p_name = property_getName(property);
    const char *p_att = property_copyAttributeValue(property, "T");
    NSString *key = [NSString stringWithCString:p_name encoding:NSUTF8StringEncoding];
    NSString *value = [NSString stringWithCString:p_att encoding:NSUTF8StringEncoding];
    NSString *prefix = @"@\""; NSString *suffix = @"\"";
    if ([value hasPrefix:prefix]) {
        value = [value substringFromIndex:prefix.length];
    }
    if ([value hasSuffix:suffix]) {
        value = [value substringToIndex:value.length - suffix.length];
    }
    [dict setValue:value forKey:key];
    return dict;
}

id SKObjectParseItem(id value) {
    if(!value) {
        return (nil);
    }
    if([value isKindOfClass:[NSDictionary class]]) {
        return (value);
    }
    if([value isKindOfClass:[SKBaseItem class]]) {
        return ([(SKBaseItem *)value dictionary]);
    }
    if([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *mtlArr = [NSMutableArray array];
        for(id obj in value) {
            id parsedValue = SKObjectParseItem(obj);
            if (parsedValue) {
                [mtlArr addObject:parsedValue];
            }
        }
        return (mtlArr);
    }
    return (value);
}

NSDictionary <NSString *, NSString *> * SKPropertyKeyList(Class cls) {
    @synchronized (cls) {
        if(!cls || ![cls isSubclassOfClass:[SKBaseItem class]]) {
            return (nil);
        }
        NSString *clsName = NSStringFromClass(cls);
        if(!clsName) {
            return (nil);
        }
        if(!_SKItemPropertyKeyListCache) {
            _SKItemPropertyKeyListCache = [[NSMutableDictionary alloc] init];
        }
        NSMutableDictionary *pts = _SKItemPropertyKeyListCache[clsName];
        if(pts) {
            return (pts);
        }
        pts = [[NSMutableDictionary alloc] init];
        while (cls != NULL && ![cls isEqual:[NSObject class]]) {
            @autoreleasepool {
                unsigned int outCount = 0;
                objc_property_t *property_list = class_copyPropertyList(cls, &outCount);
                for(unsigned int i = 0; i < outCount; i ++) {
                    objc_property_t p = property_list[i];
                    NSDictionary *pdict = SKParseProperty(p);
                    if(pdict.allKeys.firstObject && ![_SKItemPropertyKeyIgnoreKeys containsObject:pdict.allKeys.firstObject]) {
                        [pts setValue:pdict.allValues.firstObject forKey:pdict.allKeys.firstObject];
                    }
                }
                if(property_list != NULL) {
                    free(property_list);
                    property_list = NULL;
                }
                cls = class_getSuperclass(cls);
            }
        }
        [_SKItemPropertyKeyListCache setObject:pts forKey:clsName];
        return (pts);
    }
}


@interface SKKillErrorObj : NSObject
@end
@implementation SKKillErrorObj
@end
static SKKillErrorObj *killErrorObj = nil;
SKKillErrorObj * SKSharedKillErrorObj() {
    if(!killErrorObj) {
        killErrorObj = [[SKKillErrorObj alloc] init];
    }
    return (killErrorObj);
}

@implementation SKBaseItem

#pragma mark - life cycle
+ (void)load {
    _SKItemPropertyKeyIgnoreKeys = [@[@"hash",
                                      @"superclass",
                                      @"description",
                                      @"debugDescription"] copy];
}

+ (instancetype)item {
    return ([[[self class] alloc] init]);
}

+ (instancetype)itemWithDictionary:(NSDictionary *)dictionary {
    return ([[self alloc] initWithDictionary:dictionary]);
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
    if(self) {
        if(!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
            return (self);
        }
        NSDictionary *pps = SKPropertyKeyList([self class]);
        [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            if(!key || !value || [value isKindOfClass:[NSNull class]]) {
                return;
            }
            if([value isKindOfClass:[NSDictionary class]]) {
                Class parseClass = NSClassFromString(pps[key]);
                if(!parseClass || ![parseClass isSubclassOfClass:[SKBaseItem class]]) {
                    [self setValue:value forKey:key];
                    return;
                }
                id subItem = [parseClass itemWithDictionary:value];
                [self setValue:subItem forKey:key];
                return;
            }
            if([value isKindOfClass:[NSArray class]]) {
                Class parseClass = [self parseClassWithKey:key];
                if(!parseClass || ![parseClass isSubclassOfClass:[SKBaseItem class]]) {
                    [self setValue:value forKey:key];
                    return;
                }
                NSArray *valueArray = (NSArray *)value;
                NSArray *subItems = [NSArray itemsWithItemClass:parseClass JSONArray:valueArray];
                [self setValue:subItems forKey:key];
                return;
            }
            [self setValue:value forKey:key];
        }];
    }
    return (self);
}

- (instancetype)init {
    self = [super init];
    if(self) {
        
    }
    return (self);
}
#pragma mark -

#pragma mark - override
- (NSUInteger)hash {
    __block NSUInteger hh = 0;
    NSArray *ptlist = SKPropertyKeyList([self class]).allKeys;
    [ptlist enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [self valueForKey:key];
        if(!value) {
            return;
        }
        hh ^= [value hash];
    }];
    return (hh);
}

- (NSString *)description {
    NSString *hs = [NSString stringWithFormat:@"\n<%s : %p;\n", object_getClassName(self), self];
    NSArray *keys = SKPropertyKeyList([self class]).allKeys;
    NSDictionary *dict = [self dictionaryWithValuesForKeys:keys];
    if(!dict) {
        return ([hs stringByAppendingString:@">"]);
    }
    NSMutableString *desc = [NSMutableString stringWithFormat:@"%@", dict];
    [desc replaceCharactersInRange:[desc rangeOfString:@"{\n"] withString:hs];
    [desc replaceCharactersInRange:NSMakeRange([desc length] - 1, 1) withString:@">"];
    return (desc);
}
#pragma mark -

#pragma mark - getter
- (Class)parseClassWithKey:(NSString * _Nonnull)key {
    NSString *parseKey = [NSString stringWithFormat:@"%@ParseClass", key];
    Class parseClass = [self valueForKey:parseKey];
    return (parseClass);
}

- (NSDictionary *)dictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *propertyList = SKPropertyKeyList([self class]).allKeys;
    for(NSString *key in propertyList) {
        id value = [self valueForKey:key];
        [dict setValue:SKObjectParseItem(value) forKey:key];
    }
    return (dict);
}
#pragma mark -

#pragma mark - <NSKeyValueCoding>
- (nullable id)valueForUndefinedKey:(NSString *)key {
    NSLog(@"%s -> value undefine key:%@", object_getClassName(self), key);
    return (nil);
}

- (void)setValue:(nullable id)value forUndefinedKey:(NSString *)key {
    NSLog(@"%s -> set value undefine key:%@", object_getClassName(self), key);
}
#pragma mark -

#pragma mark - <NSCopying>
- (id)copyWithZone:(NSZone *)zone {
    SKBaseItem *item = [[[self class] alloc] init];
    NSArray *ptlist = SKPropertyKeyList([self class]).allKeys;
    [ptlist enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        [item setValue:[self valueForKey:key] forKey:key];
    }];
    return (item);
}
#pragma mark -

#pragma mark - <NSCoding>
- (void)encodeWithCoder:(NSCoder *)aCoder {
    NSArray *ptlist = SKPropertyKeyList([self class]).allKeys;
    [ptlist enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
    }];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        NSArray *ptlist = SKPropertyKeyList([self class]).allKeys;
        [ptlist enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
            [self setValue:[aDecoder decodeObjectForKey:key] forKey:key];
        }];
    }
    return (self);
}
#pragma mark -

#pragma mark - invocation
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL seletor = [anInvocation selector];
    if ([self respondsToSelector:seletor]) {
        [anInvocation invokeWithTarget:self];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature* signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        SKKillErrorObj *killErrorObj = SKSharedKillErrorObj();
        if(![killErrorObj respondsToSelector:aSelector]) {
            class_addMethod([killErrorObj class], aSelector, (IMP)sel_getName(aSelector), "@@:");
        }
        signature = [killErrorObj methodSignatureForSelector:aSelector];
    }
    return (signature);
}
#pragma mark -

@end

@implementation NSArray (SKItems)

+ (NSArray <__kindof SKBaseItem * > *)itemsWithItemClass:(Class)itemClass JSONArray:(NSArray <__kindof NSDictionary *> *)array {
    if(!array || ![array isKindOfClass:[NSArray class]]) {
        return (nil);
    }
    if(!itemClass || ![itemClass isSubclassOfClass:[SKBaseItem class]]) {
        itemClass = [SKBaseItem class];
    }
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSDictionary *dict in array) {
        [items addObject:[itemClass itemWithDictionary:dict]];
    }
    return ([items copy]);
}

@end
