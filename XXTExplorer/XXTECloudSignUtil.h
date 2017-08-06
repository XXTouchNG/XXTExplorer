/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>
#import "XXTECloudHttpConstant.h"
#import "XXTECloudSDKConstant.h"
#import "XXTECloudAppConfiguration.h"


/**
 *
 *  签名工具类
 *  客户端需要对Request中的关键内容做签名处理，将生成的签名字符串放入到请求头中
 *  网关在收到Request后，在验证签名合法后才将请求转发给后端服务，否则返回400
 *  签名采用hmacSha256算法，秘钥在“阿里云官网”->"API网关"->"应用管理"->"应用详情"查看
 *
 */
@interface XXTECloudSignUtil : NSObject


/**
 *  签名方法
 *  本方法将Request中的httpMethod、headers、path、queryParam、formParam合成一个字符串用hmacSha256算法双向加密进行签名
 */
+ (NSString *)sign:(NSString *)httpMethod
           headers:(NSDictionary *)headers
              path:(NSString *)path
        queryParam:(NSDictionary *)queryParam
         formParam:(NSDictionary *)formParam;

@end

@interface XXTECloudSignUtil (private)

/**
 * 将Request中的httpMethod、headers、path、queryParam、formParam合成一个字符串
 */
+ (NSString *)buildStringToSign:(NSDictionary *)headers
                           path:(NSString *)path
                     queryParam:(NSDictionary *)queryParam
                      formParam:(NSDictionary *)formParam
                         method:(NSString *)method;

/**
 * 将headers合成一个字符串
 */
+ (NSString *)buildHeaders:(NSDictionary *)headers;


/**
 * 将path、queryParam、formParam合成一个字符串
 */
+ (NSString *)buildResource:(NSString *)path queryParam:(NSDictionary *)queryParam formParam:(NSDictionary *)formParam;


/**
 *  对字符串进行hmacSha256加密，然后再进行BASE64编码
 */
+ (NSString *)hmacSha256:(NSString *)key data:(NSString *)data;

@end
