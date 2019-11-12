//
//  YMApplePay.m
//  AppInPurchasing
//
//  Created by Andrew on 2019/11/12.
//  Copyright © 2019 余默. All rights reserved.
//

#import "YMApplePay.h"

@interface YMApplePay () <SKProductsRequestDelegate,SKPaymentTransactionObserver>
{
    NSString *_purchID;
    IAPCompletionHandleBlock _handle;
}

@end

@implementation YMApplePay

/*注意事项：
 1.沙盒环境测试appStore内购流程的时候，请使用没越狱的设备。
 2.请务必使用真机来测试，一切以真机为准。
 3.项目的Bundle identifier需要与您申请AppID时填写的bundleID一致，不然会无法请求到商品信息。
 4.如果是你自己的设备上已经绑定了自己的AppleID账号请先注销掉,否则你哭爹喊娘都不知道是怎么回事。
 5.订单校验 苹果审核app时，仍然在沙盒环境下测试，所以需要先进行正式环境验证，如果发现是沙盒环境则转到沙盒验证。
 识别沙盒环境订单方法：
 1.根据字段 environment = sandbox。
 2.根据验证接口返回的状态码,如果status=21007，则表示当前为沙盒环境。
 苹果反馈的状态码：
 21000App Store无法读取你提供的JSON数据
 21002 订单数据不符合格式
 21003 订单无法被验证
 21004 你提供的共享密钥和账户的共享密钥不一致
 21005 订单服务器当前不可用
 21006 订单是有效的，但订阅服务已经过期。当收到这个信息时，解码后的收据信息也包含在返回内容中
 21007 订单信息是测试用（sandbox），但却被发送到产品环境中验证
 21008 订单信息是产品环境中使用，但却被发送到测试环境中验证
 */

#ifdef DEBUG
#define YMLog(...) NSLog(__VA_ARGS__)
#else
#define YMLog(...)
#endif

+ (instancetype)shareIAPManager {
    static YMApplePay *IAPManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IAPManager = [[YMApplePay alloc] init];
    });
    return IAPManager;
}

- (instancetype)init {
    if ([super init]) {
        // 购买监听写在程序入口,程序挂起时移除监听,这样如果有未完成的订单将会自动执行并回调 paymentQueue:updatedTransactions:方法
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

//添加内购产品
- (void)addPurchWithProductID:(NSString *)product_id completeHandle:(IAPCompletionHandleBlock)handle {
    //移除上次未完成的交易订单
    [self removeAllUncompleteTransactionBeforeStartNewTransaction];
    if (product_id) {
        if ([SKPaymentQueue canMakePayments]) {
            // 开始购买服务
            _purchID = product_id;
            _handle = handle;
            NSSet *nsset = [NSSet setWithArray:@[product_id]];
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
            request.delegate = self;
            [request start];
        }else{
            [self handleActionWithType:IAPPurchNotArrow data:nil];
        }
    }
}

- (void)handleActionWithType:(IAPPurchType)type data:(NSData *)data{
    switch (type) {
        case IAPPurchSuccess:
            YMLog(@"购买成功");
            break;
        case IAPPurchFailed:
            YMLog(@"购买失败");
            break;
        case IAPPurchCancel:
            YMLog(@"用户取消购买");
            break;
        case IAPPurchVerFailed:
            YMLog(@"订单校验失败");
            break;
        case IAPPurchVerSuccess:
            YMLog(@"订单校验成功");
            break;
        case IAPPurchNotArrow:
            YMLog(@"不允许程序内付费");
            break;
        default:
            break;
    }
}

#pragma mark - SKProductsRequestDelegate
// 交易结束
- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    // Your application should implement these two methods.
    NSString * productIdentifier = transaction.payment.productIdentifier;
    NSData *data = [productIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    NSString *receipt = [data base64EncodedStringWithOptions:0];
    
    YMLog(@"%@",receipt);
    if ([productIdentifier length] > 0) {
        // 向自己的服务器验证购买凭证
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        if (![[NSFileManager defaultManager] fileExistsAtPath:[receiptURL path]]) {
            // 取 receipt 的时候要判空,如果文件不存在,就要从苹果服务器重新刷新下载 receipt 了
            // SKReceiptRefreshRequest 刷新的时候,需要用户输入 Apple ID,同时需要网络状态良好
            SKReceiptRefreshRequest *receiptRefreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
            receiptRefreshRequest.delegate = self;
            [receiptRefreshRequest start];
            return;
        }
        NSData *data = [NSData dataWithContentsOfURL:receiptURL];
        /** 交易凭证*/
        NSString *receipt_data = [data base64EncodedStringWithOptions:0];
        /** 事务标识符(交易编号)  交易编号(必传:防止越狱下内购被破解,校验 in_app 参数)*/
        NSString *transaction_id = transaction.transactionIdentifier;
        NSString *goodID = transaction.payment.productIdentifier;
        
        //这里缓存receipt_data，transaction_id 因为后端做校验的时候需要用到这两个字段
        YMLog(@"%@",receipt_data);
        YMLog(@"%@",transaction_id);
        
        
        [self retquestApplePay:receipt_data transaction_id:transaction_id goodsID:goodID];
    }
    [self verifyPurchaseWithPaymentTransaction:transaction isTestServer:NO];
}

- (void)retquestApplePay:(NSString *)receipt_data transaction_id:(NSString *)transaction_id goodsID:(NSString *)goodsId {
    NSMutableDictionary *param = [NSMutableDictionary new];
    /* 将订单数据发送到后端验证
    param[@"userId"] = [AppSingleInstance sharedInstance].person.uid;
    param[@"transactionId"] = transaction_id;
    param[@"payload"] = receipt_data;
    param[@"iosGoodsId"] = _purchID;
    
    [HKMembersHandlers hk_payWithParam:param succeed:^(id  _Nonnull obj) {
        YMLog(@"%@",obj);
        [MBProgressHUD showSuccessMessage:@"支付成功"];
        [HKLocalCacheUserInfo removeAppleInfo];
        if(_handle){
            _handle(0,nil);
        }
    } failed:^(id  _Nonnull obj) {
        YMLog(@"%@",obj);
    }];
     */
}

// 交易失败
- (void)failedTransaction:(SKPaymentTransaction *)transaction{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [self handleActionWithType:IAPPurchFailed data:nil];
    }else{
        [self handleActionWithType:IAPPurchCancel data:nil];
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)transaction isTestServer:(BOOL)flag{
    //交易验证
    NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];
    
    if(!receipt){
        // 交易凭证为空验证失败
        [self handleActionWithType:IAPPurchVerFailed data:nil];
        return;
    }
    // 购买成功将交易凭证发送给服务端进行再次校验
    [self handleActionWithType:IAPPurchSuccess data:receipt];
    
    NSError *error;
    NSDictionary *requestContents = @{
                                      @"receipt-data": [receipt base64EncodedStringWithOptions:0]
                                      };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                          options:0
                                                            error:&error];
    
    if (!requestData) { // 交易凭证为空验证失败
        [self handleActionWithType:IAPPurchVerFailed data:nil];
        return;
    }
    
    //In the test environment, use https://sandbox.itunes.apple.com/verifyReceipt
    //In the real environment, use https://buy.itunes.apple.com/verifyReceipt
    
#ifdef DEBUG
#define serverString @"https://sandbox.itunes.apple.com/verifyReceipt"
#else
#define serverString @"https://buy.itunes.apple.com/verifyReceipt"
#endif
    
    NSURL *storeURL = [NSURL URLWithString:serverString];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [session dataTaskWithRequest:storeRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            // 无法连接服务器,购买校验失败
            [self handleActionWithType:IAPPurchVerFailed data:nil];
        } else {
            NSError *error;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!jsonResponse) {
                // 苹果服务器校验数据返回为空校验失败
                [self handleActionWithType:IAPPurchVerFailed data:nil];
            }
            
            // 先验证正式服务器,如果正式服务器返回21007再去苹果测试服务器验证,沙盒测试环境苹果用的是测试服务器
            NSString *status = [NSString stringWithFormat:@"%@",jsonResponse[@"status"]];
            if (status && [status isEqualToString:@"21007"]) {
                [self verifyPurchaseWithPaymentTransaction:transaction isTestServer:YES];
            }else if(status && [status isEqualToString:@"0"]){
                [self handleActionWithType:IAPPurchVerSuccess data:nil];
            }
            YMLog(@"----验证结果 %@",jsonResponse);
        }
    }];
    
    // 验证成功与否都注销交易,否则会出现虚假凭证信息一直验证不通过,每次进程序都得输入苹果账号
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    NSArray *product = response.products;
    if([product count] <= 0){
        YMLog(@"--------------没有商品------------------");
        return;
    }
    
    SKProduct *p = nil;
    for(SKProduct *pro in product){
        if([pro.productIdentifier isEqualToString:_purchID]){
            p = pro;
            break;
        }
    }
    
    YMLog(@"productID:%@", response.invalidProductIdentifiers);
    YMLog(@"产品付费数量:%lu",(unsigned long)[product count]);
    YMLog(@"%@",[p description]);
    YMLog(@"%@",[p localizedTitle]);
    YMLog(@"%@",[p localizedDescription]);
    YMLog(@"%@",[p price]);
    YMLog(@"%@",[p productIdentifier]);
    
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    YMLog(@"------------------错误-----------------:%@", error);
}

- (void)requestDidFinish:(SKRequest *)request{
    YMLog(@"------------反馈信息结束-----------------");
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    for (SKPaymentTransaction *tran in transactions) {
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
                YMLog(@"商品添加进列表");
                break;
            case SKPaymentTransactionStateRestored:
                YMLog(@"已经购买过商品");
                // 消耗型不支持恢复购买
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:tran];
                break;
            default:
                break;
        }
    }
}

#pragma mark -- 结束上次未完成的交易 防止串单
-(void)removeAllUncompleteTransactionBeforeStartNewTransaction{
    NSArray* transactions = [SKPaymentQueue defaultQueue].transactions;
    if (transactions.count > 0) {
        //检测是否有未完成的交易
        SKPaymentTransaction* transaction = [transactions firstObject];
        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            return;
        }
    }
}


@end
