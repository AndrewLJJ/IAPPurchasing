# IAPPurchasing
App内购demo

### 使用方法

//product_id  是需要在开发者账号注册的内购产品的id，这个id是自定义的，最好定义要有规律
//此外在开发者账号平台上注册一个沙箱测试账号，用于内购支付（这个邮箱不能跟苹果有任何关联，最好使用企业邮箱）如：com.harryTest.kid.test_12 这里我在为测试使用的id
[[YMApplePay shareIAPManager] addPurchWithProductID:produc_id completeHandle:^(IAPPurchType type, NSData * _Nonnull data) {
//购买成功后的操作
}];

### 点击购买，成功下单，苹果会返回内购产品的数据，如图：

![image](https://github.com/AndrewLJJ/IAPPurchasing/blob/master/Images/%E6%88%90%E5%8A%9F%E6%B7%BB%E5%8A%A0%E4%BA%A7%E5%93%81.png)

### 
 ![image](https://github.com/AndrewLJJ/IAPPurchasing/blob/master/Images/%E4%B8%8B%E5%8D%95%E6%88%90%E5%8A%9F%E8%8B%B9%E6%9E%9C%E8%BF%94%E5%9B%9E%E7%9A%84%E8%AE%A2%E5%8D%95.png)

### 
