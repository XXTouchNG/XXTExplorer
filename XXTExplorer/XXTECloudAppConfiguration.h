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



@interface XXTECloudAppConfiguration : NSObject
{
    /**
     *  Api绑定的的AppKey，可以在“阿里云官网”->"API网关"->"应用管理"->"应用详情"查看
     */
    NSString* APP_KEY;
    
    /**
     *  Api绑定的的AppSecret，用来做传输数据签名使用，可以在“阿里云官网”->"API网关"->"应用管理"->"应用详情"查看
     */
    NSString* APP_SECRET;
    
    
    /**
     *  缓存策略:
     *  0:默认的缓存策略，使用协议的缓存策略
     *  1:每次都从网络加载
     *  2:返回缓存否则加载，很少使用
     *  3:只返回缓存，没有也不加载，很少使用
     */
    int APP_CACHE_POLICY;
    
    /**
     *  超时时间，单位为秒
     */
    int APP_CONNECTION_TIMEOUT;
}

+ (instancetype) instance;
@property (nonatomic) NSString* APP_KEY;
@property (nonatomic) NSString* APP_SECRET;
@property (nonatomic) int APP_CACHE_POLICY;
@property (nonatomic) int APP_CONNECTION_TIMEOUT;

@end

