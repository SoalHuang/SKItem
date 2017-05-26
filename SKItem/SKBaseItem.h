//
//  SKBaseItem.h
//  SOKit
//
//  Created by so on 16/5/30.
//  Copyright © 2016年 com.. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  @brief KVC base model struct
 Automatic implement NSCoding
 Automatic implement NSCopying
 Automatic implement description
 Automatic implement forwardInvocation
 Automatic implement recursion
 */

@interface SKBaseItem : NSObject <NSCoding, NSCopying>

+ (instancetype)item;

+ (instancetype)itemWithDictionary:(NSDictionary *)dictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionary;

@end


@interface NSArray (SKItems)
/**
 *  @brief itemClass must SKBaseItem's subclass
 */
+ (NSArray <__kindof SKBaseItem * > *)itemsWithItemClass:(Class)itemClass JSONArray:(NSArray <__kindof NSDictionary *> *)array;

@end

/**
 *  @brief  get all property of class
 */
NSDictionary <NSString *, NSString *> * SKPropertyKeyList(Class cls);
