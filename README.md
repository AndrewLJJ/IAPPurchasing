# IAPPurchasing
App内购demo

### 使用方法

//product_id  是需要在开发者账号注册的内购产品的id，这个id是自定义的，最好定义要有规律

//此外在开发者账号平台上注册一个沙箱测试账号，用于内购支付（这个邮箱不能跟苹果有任何关联，最好使用企业邮箱）如：com.harryTest.kid.test_12 这里我在为测试使用的id

[[YMApplePay shareIAPManager] addPurchWithProductID:produc_id completeHandle:^(IAPPurchType type, NSData * _Nonnull data) {
//购买成功后的操作
}];

### 成功下单，获取苹果服务器返回的订单数据，在SKProductsRequestDelegate 代理方法
// 交易结束

- (void)completeTransaction:(SKPaymentTransaction *)transaction ;

中 获取 

NSString * productIdentifier = transaction.payment.productIdentifier;

NSData *data = [productIdentifier dataUsingEncoding:NSUTF8StringEncoding];

NSString *receipt = [data base64EncodedStringWithOptions:0];

NSString *receipt_data = [data base64EncodedStringWithOptions:0];

/** 事务标识符(交易编号)  交易编号(必传:防止越狱下内购被破解,校验 in_app 参数)*/

NSString *transaction_id = transaction.transactionIdentifier;

NSString *goodID = transaction.payment.productIdentifier;

得到的 transaction_id  receipt_data  goodID需要上传到app 服务器校验（具体看后端的需求）

### 点击购买，成功下单，苹果会返回内购产品的数据，如图：

![image](https://github.com/AndrewLJJ/IAPPurchasing/blob/master/Images/%E6%88%90%E5%8A%9F%E6%B7%BB%E5%8A%A0%E4%BA%A7%E5%93%81.png)

### 成功下单后，会弹出一个界面，这里是输入已经在沙箱注册的app id 
 ![image](https://github.com/AndrewLJJ/IAPPurchasing/blob/master/Images/%E8%BE%93%E5%85%A5appid%E8%B4%A6%E5%8F%B7%E8%B4%AD%E4%B9%B0.png)
 
 ### 购买成功后，苹果服务器会返回，订单信息
 ![image](https://github.com/AndrewLJJ/IAPPurchasing/blob/master/Images/%E4%B8%8B%E5%8D%95%E6%88%90%E5%8A%9F%E8%8B%B9%E6%9E%9C%E8%BF%94%E5%9B%9E%E7%9A%84%E8%AE%A2%E5%8D%95.png)

