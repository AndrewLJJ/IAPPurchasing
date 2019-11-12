//
//  ViewController.m
//  AppInPurchasing
//
//  Created by Andrew on 2019/11/12.
//  Copyright © 2019 余默. All rights reserved.
//

#import "ViewController.h"
#import "YMApplePay.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

//com.harryTest.kid.test_12 是需要在开发者账号注册的内购产品的id，这个id是自定义的，最好定义要有规律
//此外在开发者账号平台上注册一个沙箱测试账号，用于内购支付（这个邮箱不能跟苹果有任何关联，最好使用企业邮箱）
//购买
- (IBAction)purchasingBtnClick:(id)sender {
    [[YMApplePay shareIAPManager] addPurchWithProductID:@"com.harryTest.kid.test_12" completeHandle:^(IAPPurchType type, NSData * _Nonnull data) {
        //购买成功后的操作
    }];
}



@end
