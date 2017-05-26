//
//  TestItem.h
//  SOKit
//
//  Created by so on 16/5/30.
//  Copyright © 2016年 com.. All rights reserved.
//

#import "SKBaseItem.h"

@interface Address : SKBaseItem
@property (copy, nonatomic) NSString *province;
@property (copy, nonatomic) NSString *city;
@property (copy, nonatomic) NSString *district;
@end


@interface Person : SKBaseItem
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *gender;
@property (assign, nonatomic) NSInteger age;
@end


@interface Family : SKBaseItem
@property (strong, nonatomic) Address *address;
@property (strong, nonatomic) NSArray <Person *> *members;
@end
