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

#import "XXTECloudApiSdk.h"
#import "XXTECloudHttpConstant.h"
#import "XXTECloudSDKConstant.h"
#import "XXTECloudSignUtil.h"

@implementation XXTECloudApiSdk


/**
 *
 *  使用单例模式
 *  保证NSURLSession对象可以复用
 *
 */
+ (instancetype)instance {
    static dispatch_once_t onceToken;
    static XXTECloudApiSdk *httpUtil = nil;
    dispatch_once(&onceToken, ^{
        httpUtil = [XXTECloudApiSdk new];
    });
    return httpUtil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}


/**
 *
 * 以GET的方法发送HTTP请求
 *
 * @param httpSchema
 * 使用HTTP还是HTTPS调用，请传入XXTECloudHttpConstant中的CLOUDAPI_HTTP或者CLOUDAPI_HTTPS
 *
 * @param host
 * 请传入主机域名或者ip比如："alibaba.com:8080"
 * 请务必注意不需要填写http://,也不需要在8080后传入"/",以下写法都是错误的：
 * http://alibaba.com,alibaba.com/
 *
 * @param path
 * 类似：/v2/getUserInfo/[userId]
 *
 * @param pathParams
 * Api定义中的path参数键值对，SDK会将本字典中的value替换掉path中的动态参数
 * 比如 path=/v2/getUserInfo/[userId]，pathParams 字典中包含 key:userId , value:10000003
 * 发送的请求中的path会变成/v2/getUserInfo/10000003
 *
 * @param queryParams
 * Api定义中的query参数键值对
 * SDK会将字典中的所有键值对拼接到path后，比如path=/v2/getUserInfo/10000003 ，半参数包含key:sex , value:boy
 * 发送的请求中的path会变成/v2/getUserInfo/10000003?sex=boy
 *
 * @param headerParams
 * Api定义中的header参数键值对
 *
 * @param completionBlock 回调函数
 */
- (void)httpGet:(NSString *)httpSchema
           host:(NSString *)host
           path:(NSString *)path
     pathParams:(NSDictionary *)pathParams
    queryParams:(NSDictionary *)queryParams
   headerParams:(NSMutableDictionary *)headerParams
completionBlock:(void (^)(NSData *, NSURLResponse *, NSError *))completionBlock {
    NSURLRequest *request = [XXTECloudApiSdk buildRequest:httpSchema
                                                   method:CLOUDAPI_GET
                                                     host:host
                                                     path:path
                                               pathParams:pathParams
                                              queryParams:queryParams
                                               formParams:nil
                                                     body:nil
                                       requestContentType:CLOUDAPI_CONTENT_TYPE_FORM
                                        acceptContentType:CLOUDAPI_CONTENT_TYPE_JSON
                                             headerParams:headerParams];

    NSURLSessionDataTask *task = [self.requestSession dataTaskWithRequest:request completionHandler:completionBlock];
    [task resume];
}


/**
 *
 * 以POST的方法发送HTTP请求
 * 请求Body为表单数据
 *
 * @param httpSchema
 * 使用HTTP还是HTTPS调用，请传入XXTECloudHttpConstant中的CLOUDAPI_HTTP或者CLOUDAPI_HTTPS
 *
 * @param host
 * 请传入主机域名或者ip比如："alibaba.com:8080"
 * 请务必注意不需要填写http://,也不需要在8080后传入"/",以下写法都是错误的：
 * http://alibaba.com,alibaba.com/
 *
 * @param path
 * 类似：/v2/getUserInfo/[userId]
 *
 * @param pathParams
 * Api定义中的path参数键值对，SDK会将本字典中的value替换掉path中的动态参数
 * 比如 path=/v2/getUserInfo/[userId]，pathParams 字典中包含 key:userId , value:10000003
 * 发送的请求中的path会变成/v2/getUserInfo/10000003
 *
 * @param queryParams
 * Api定义中的query参数键值对
 * SDK会将字典中的所有键值对拼接到path后，比如path=/v2/getUserInfo/10000003 ，半参数包含key:sex , value:boy
 * 发送的请求中的path会变成/v2/getUserInfo/10000003?sex=boy
 *
 * @param headerParams
 * Api定义中的header参数键值对
 *
 * @param formParams
 * Api定义中的form参数键值对
 *
 * @param completionBlock 回调函数
 */
- (void)httpPost:(NSString *)httpSchema
            host:(NSString *)host
            path:(NSString *)path
      pathParams:(NSDictionary *)pathParams
     queryParams:(NSDictionary *)queryParams
      formParams:(NSDictionary *)formParams
    headerParams:(NSMutableDictionary *)headerParams
 completionBlock:(void (^)(NSData *, NSURLResponse *, NSError *))completionBlock {
    NSURLRequest *request = [XXTECloudApiSdk buildRequest:httpSchema
                                                   method:CLOUDAPI_POST
                                                     host:host
                                                     path:path
                                               pathParams:pathParams
                                              queryParams:queryParams
                                               formParams:formParams
                                                     body:nil
                                       requestContentType:CLOUDAPI_CONTENT_TYPE_FORM
                                        acceptContentType:CLOUDAPI_CONTENT_TYPE_JSON
                                             headerParams:headerParams];

    NSURLSessionDataTask *task = [self.requestSession dataTaskWithRequest:request completionHandler:completionBlock];
    [task resume];
}


/**
 *
 * 以POST的方法发送HTTP请求
 * 请求Body为Byte数组
 *
 * @param httpSchema
 * 使用HTTP还是HTTPS调用，请传入XXTECloudHttpConstant中的CLOUDAPI_HTTP或者CLOUDAPI_HTTPS
 *
 * @param host
 * 请传入主机域名或者ip比如："alibaba.com:8080"
 * 请务必注意不需要填写http://,也不需要在8080后传入"/",以下写法都是错误的：
 * http://alibaba.com,alibaba.com/
 *
 * @param path
 * 类似：/v2/getUserInfo/[userId]
 *
 * @param pathParams
 * Api定义中的path参数键值对，SDK会将本字典中的value替换掉path中的动态参数
 * 比如 path=/v2/getUserInfo/[userId]，pathParams 字典中包含 key:userId , value:10000003
 * 发送的请求中的path会变成/v2/getUserInfo/10000003
 *
 * @param queryParams
 * Api定义中的query参数键值对
 * SDK会将字典中的所有键值对拼接到path后，比如path=/v2/getUserInfo/10000003 ，半参数包含key:sex , value:boy
 * 发送的请求中的path会变成/v2/getUserInfo/10000003?sex=boy
 *
 * @param headerParams
 * Api定义中的header参数键值对
 *
 * @param body
 * 在body中传输的Byte数组
 *
 * @param completionBlock 回调函数
 */
- (void)httpPost:(NSString *)httpSchema
            host:(NSString *)host
            path:(NSString *)path
      pathParams:(NSDictionary *)pathParams
     queryParams:(NSDictionary *)queryParams
            body:(NSData *)body
    headerParams:(NSMutableDictionary *)headerParams
 completionBlock:(void (^)(NSData *, NSURLResponse *, NSError *))completionBlock {

    NSURLRequest *request = [XXTECloudApiSdk buildRequest:httpSchema
                                                   method:CLOUDAPI_POST
                                                     host:host
                                                     path:path
                                               pathParams:pathParams
                                              queryParams:queryParams
                                               formParams:nil
                                                     body:body
                                       requestContentType:CLOUDAPI_CONTENT_TYPE_STREAM
                                        acceptContentType:CLOUDAPI_CONTENT_TYPE_JSON
                                             headerParams:headerParams];

    NSURLSessionDataTask *task = [self.requestSession dataTaskWithRequest:request completionHandler:completionBlock];
    [task resume];

}


/**
 *
 * 以PUT的方法发送HTTP请求
 * 请求Body为Byte数组
 *
 * @param httpSchema
 * 使用HTTP还是HTTPS调用，请传入XXTECloudHttpConstant中的CLOUDAPI_HTTP或者CLOUDAPI_HTTPS
 *
 * @param host
 * 请传入主机域名或者ip比如："alibaba.com:8080"
 * 请务必注意不需要填写http://,也不需要在8080后传入"/",以下写法都是错误的：
 * http://alibaba.com,alibaba.com/
 *
 * @param path
 * 类似：/v2/getUserInfo/[userId]
 *
 * @param pathParams
 * Api定义中的path参数键值对，SDK会将本字典中的value替换掉path中的动态参数
 * 比如 path=/v2/getUserInfo/[userId]，pathParams 字典中包含 key:userId , value:10000003
 * 发送的请求中的path会变成/v2/getUserInfo/10000003
 *
 * @param queryParams
 * Api定义中的query参数键值对
 * SDK会将字典中的所有键值对拼接到path后，比如path=/v2/getUserInfo/10000003 ，半参数包含key:sex , value:boy
 * 发送的请求中的path会变成/v2/getUserInfo/10000003?sex=boy
 *
 * @param headerParams
 * Api定义中的header参数键值对
 *
 * @param body
 * 在body中传输的byte数组
 *
 * @param completionBlock 回调函数
 */
- (void)httpPut:(NSString *)httpSchema
           host:(NSString *)host
           path:(NSString *)path
     pathParams:(NSDictionary *)pathParams
    queryParams:(NSDictionary *)queryParams
           body:(NSData *)body
   headerParams:(NSMutableDictionary *)headerParams
completionBlock:(void (^)(NSData *, NSURLResponse *, NSError *))completionBlock {
    NSURLRequest *request = [XXTECloudApiSdk buildRequest:httpSchema
                                                   method:CLOUDAPI_PUT
                                                     host:host
                                                     path:path
                                               pathParams:pathParams
                                              queryParams:queryParams
                                               formParams:nil
                                                     body:body
                                       requestContentType:CLOUDAPI_CONTENT_TYPE_STREAM
                                        acceptContentType:CLOUDAPI_CONTENT_TYPE_JSON
                                             headerParams:headerParams];

    NSURLSessionDataTask *task = [self.requestSession dataTaskWithRequest:request completionHandler:completionBlock];
    [task resume];
}


/**
 *
 * 以DELETE的方法发送HTTP请求
 *
 * @param httpSchema
 * 使用HTTP还是HTTPS调用，请传入XXTECloudHttpConstant中的CLOUDAPI_HTTP或者CLOUDAPI_HTTPS
 *
 * @param host
 * 请传入主机域名或者ip比如："alibaba.com:8080"
 * 请务必注意不需要填写http://,也不需要在8080后传入"/",以下写法都是错误的：
 * http://alibaba.com,alibaba.com/
 *
 * @param path
 * 类似：/v2/getUserInfo/[userId]
 *
 * @param pathParams
 * Api定义中的path参数键值对，SDK会将本字典中的value替换掉path中的动态参数
 * 比如 path=/v2/getUserInfo/[userId]，pathParams 字典中包含 key:userId , value:10000003
 * 发送的请求中的path会变成/v2/getUserInfo/10000003
 *
 * @param queryParams
 * Api定义中的query参数键值对
 * SDK会将字典中的所有键值对拼接到path后，比如path=/v2/getUserInfo/10000003 ，半参数包含key:sex , value:boy
 * 发送的请求中的path会变成/v2/getUserInfo/10000003?sex=boy
 *
 * @param headerParams
 * Api定义中的header参数键值对
 *
 * @param completionBlock 回调函数
 */
- (void)httpDelete:(NSString *)httpSchema
              host:(NSString *)host
              path:(NSString *)path
        pathParams:(NSDictionary *)pathParams
       queryParams:(NSDictionary *)queryParams
      headerParams:(NSMutableDictionary *)headerParams
   completionBlock:(void (^)(NSData *, NSURLResponse *, NSError *))completionBlock {
    NSURLRequest *request = [XXTECloudApiSdk buildRequest:httpSchema
                                                   method:CLOUDAPI_DELETE
                                                     host:host
                                                     path:path
                                               pathParams:pathParams
                                              queryParams:queryParams
                                               formParams:nil
                                                     body:nil
                                       requestContentType:CLOUDAPI_CONTENT_TYPE_FORM
                                        acceptContentType:CLOUDAPI_CONTENT_TYPE_JSON
                                             headerParams:headerParams];

    NSURLSessionDataTask *task = [self.requestSession dataTaskWithRequest:request completionHandler:completionBlock];
    [task resume];
}
@end

@implementation XXTECloudApiSdk (private)


/**
 *
 *  根据用户传来的参数生成Request对象
 *
 */
+ (NSURLRequest *)buildRequest:protocol
                        method:(NSString *)method
                          host:(NSString *)host
                          path:(NSString *)path
                    pathParams:(NSDictionary *)pathParams
                   queryParams:(NSDictionary *)queryParams
                    formParams:(NSDictionary *)formParams
                          body:(NSData *)body
            requestContentType:(NSString *)requestContentType
             acceptContentType:(NSString *)acceptContentType
                  headerParams:(NSMutableDictionary *)headerParams {

    /**
     * 将pathParams中的value替换掉path中的动态参数
     * 比如 path=/v2/getUserInfo/[userId]，pathParams 字典中包含 key:userId , value:10000003
     * 替换后path会变成/v2/getUserInfo/10000003
     */
    NSString *pathWithParam = [XXTECloudApiSdk combinePathParam:path pathParams:pathParams];
    NSString *queryString = [XXTECloudApiSdk buildParamsString:queryParams];
    /**
     *  拼接URL
     *  HTTP + HOST + PATH(With pathparameter) + Query Parameter
     */
    NSMutableString *url = [[NSMutableString alloc] initWithFormat:@"%@%@%@", protocol, host, pathWithParam];
    if (nil != queryParams && queryParams.count > 0) {
        [url appendFormat:@"?%@", queryString];
    }

    if (nil == headerParams) {
        headerParams = [[NSMutableDictionary alloc] init];
    }

    /**
     *  使用URL初始化一个NSMutableURLRequest类
     *  同时指定缓存策略和超时时间，这两个配置从XXTECloudAppConfiguration.h中设置
     */
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:[[XXTECloudAppConfiguration instance] APP_CACHE_POLICY] timeoutInterval:[[XXTECloudAppConfiguration instance] APP_CONNECTION_TIMEOUT]];

    request.HTTPMethod = method;

    //设置请求头中的时间戳
    NSDate *current = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [df setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss z"];
    [headerParams setObject:[df stringFromDate:current] forKey:CLOUDAPI_HTTP_HEADER_DATE];

    //设置请求头中的时间戳，以timeIntervalSince1970的形式
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    [headerParams setObject:[NSString stringWithFormat:@"%0.0lf", timeStamp] forKey:CLOUDAPI_X_CA_TIMESTAMP];

    //请求放重放Nonce,15分钟内保持唯一,建议使用UUID
    [headerParams setObject:[[NSUUID UUID] UUIDString] forKey:CLOUDAPI_X_CA_NONCE];

    //设置请求头中的UserAgent
    [headerParams setObject:CLOUDAPI_USER_AGENT forKey:CLOUDAPI_HTTP_HEADER_USER_AGENT];

    //设置请求头中的主机地址
    [headerParams setObject:host forKey:CLOUDAPI_HTTP_HEADER_HOST];

    //设置请求头中的Api绑定的的AppKey
    [headerParams setObject:[[XXTECloudAppConfiguration instance] APP_KEY] forKey:CLOUDAPI_X_CA_KEY];

    //设置签名版本号
    [headerParams setObject:CLOUDAPI_CA_VERSION forKey:CLOUDAPI_X_CA_VERSION];

    //设置请求数据类型
    [headerParams setObject:requestContentType forKey:CLOUDAPI_HTTP_HEADER_CONTENT_TYPE];

    //设置应答数据类型
    [headerParams setObject:acceptContentType forKey:CLOUDAPI_HTTP_HEADER_ACCEPT];


    /**
     *  如果formParams不为空
     *  将Form中的内容拼接成字符串后使用UTF8编码序列化成Byte数组后加入到Request中去
     */
    if (nil != formParams) {
        [request setHTTPBody:[[XXTECloudApiSdk buildParamsString:formParams] dataUsingEncoding:NSUTF8StringEncoding]];
    }

        /**
         *  如果类型为byte数组的body不为空
         *  将body中的内容MD5算法加密后再采用BASE64方法Encode成字符串，放入HTTP头中
         *  做内容校验，避免内容在网络中被篡改
         */
    else if (nil != body) {
        [request setHTTPBody:body];
        [headerParams setObject:[XXTECloudApiSdk md5:body] forKey:CLOUDAPI_HTTP_HEADER_CONTENT_MD5];

    }

    /**
     *  将Request中的httpMethod、headers、path、queryParam、formParam合成一个字符串用hmacSha256算法双向加密进行签名
     *  签名内容放到Http头中，用作服务器校验
     */
    [headerParams setObject:[XXTECloudSignUtil sign:method headers:headerParams path:pathWithParam queryParam:queryParams formParam:formParams] forKey:CLOUDAPI_X_CA_SIGNATURE];

    /**
     *  凑齐所有HTTP头之后，将头中的数据全部放入Request对象中
     *  Http头编码方式：先将字符串进行UTF-8编码，然后使用Iso-8859-1解码生成字符串
     */
    for (id key in headerParams) {
        [request setValue:[[NSString alloc] initWithData:[[headerParams objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding] encoding:NSISOLatin1StringEncoding] forHTTPHeaderField:key];

    }

    return request;

}


/**
 * 将pathParams中的value替换掉path中的动态参数
 * 比如 path=/v2/getUserInfo/[userId]，pathParams 字典中包含 key:userId , value:10000003
 * 替换后path会变成/v2/getUserInfo/10000003
 */
+ (NSString *)combinePathParam:(NSString *)path
                    pathParams:(NSDictionary *)pathParams {

    NSMutableString *result = [[NSMutableString alloc] initWithString:path];
    for (id key in pathParams) {
        NSString *value = [pathParams objectForKey:key];
        [result replaceCharactersInRange:[result rangeOfString:[NSString stringWithFormat:@"[%@]", key]] withString:value];
    }

    return result;

}

/**
 * 将Parameter中的value生成String：
 * abc=123&edf=456
 * 参数值都需要做URLEncode处理
 */
+ (NSString *)buildParamsString:(NSDictionary *)params {
    NSMutableString *result = [[NSMutableString alloc] init];
    if (nil != params) {
        bool isFirst = true;
        for (id key in params) {
            if (!isFirst) {
                [result appendString:@"&"];
            } else {
                isFirst = false;
            }

            [result appendFormat:@"%@=%@", key, [[params objectForKey:key] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        }
    }

    return result;

}

/**
 *  MD5加密后，使用BASE64方式编码成字符串
 */
+ (NSString *)md5:(NSData *)data {
    const char *original_str = (const char *) [data bytes];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; //CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(original_str, (uint) strlen(original_str), digist);
    NSData *md5data = [[NSData alloc] initWithBytes:digist length:sizeof(digist)];
    NSString *result = [md5data base64EncodedStringWithOptions:0];
    return result;
}

@end
