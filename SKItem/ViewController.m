//
//  ViewController.m
//  SKItem
//
//  Created by soal on 2017/5/26.
//  Copyright © 2017年 SO. All rights reserved.
//

#import "ViewController.h"
#import "TestItem.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self parse];
}

- (void)parse {
    
    NSDictionary *ad = @{@"province":@"pro", @"city":@"ci", @"district":@"di"};
    Address *address = [Address itemWithDictionary:ad];
    NSLog(@"address: %@", address);
    
    NSDictionary *f = @{@"name":@"father-name", @"age":@"26", @"gender":@"male"};
    Person *father = [Person itemWithDictionary:f];
    NSLog(@"father: %@", father);
    
    NSDictionary *m = @{@"name":@"mother-name", @"age":@"25", @"gender":@"gender"};
    Person *mother = [Person itemWithDictionary:m];
    NSLog(@"mother: %@", mother);
    
    NSDictionary *fm = @{@"address":ad, @"members":@[f, m]};
    Family *family = [Family itemWithDictionary:fm];
    NSLog(@"family: %@", family);
    
    NSLog(@"\nfamily:%@", family.dictionary);
}

@end
