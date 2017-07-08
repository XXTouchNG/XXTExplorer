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

/**
 * 通用常量
 */


static NSString* const CLOUDAPI_USER_AGENT = @"ALIYUN-OBJECTC-DEMO";

//换行符
static char const CLOUDAPI_LF = '\n';

//参与签名的系统Header前缀,只有指定前缀的Header才会参与到签名中
static NSString* const CLOUDAPI_CA_HEADER_PREFIX = @"X-Ca-";

static const NSString *CLOUDAPI_CA_VERSION = @"1";



/**
 * 系统HTTP头常量
 */

//签名Header
static NSString* const CLOUDAPI_X_CA_SIGNATURE = @"X-Ca-Signature";

//所有参与签名的Header
static NSString* const CLOUDAPI_X_CA_SIGNATURE_HEADERS = @"X-Ca-Signature-Headers";

//请求时间戳
static NSString* const CLOUDAPI_X_CA_TIMESTAMP =  @"X-Ca-Timestamp";

//请求放重放Nonce,15分钟内保持唯一,建议使用UUID
static NSString* const CLOUDAPI_X_CA_NONCE = @"X-Ca-Nonce";

//APP KEY
static NSString* const CLOUDAPI_X_CA_KEY = @"X-Ca-Key";

//签名算法版本号
static NSString* const CLOUDAPI_X_CA_VERSION =  @"X-Ca-Version";
