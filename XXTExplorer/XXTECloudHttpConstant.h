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
 * HTTP Schema常量
 */


//HTTP
static NSString* const CLOUDAPI_HTTP = @"http://";

//HTTPS
static NSString* const CLOUDAPI_HTTPS = @"https://";


/**
 * HTTP方法常量
 */


//GET
static NSString* const CLOUDAPI_GET = @"GET";

//POST
static NSString* const CLOUDAPI_POST = @"POST";

//PUT
static NSString* const CLOUDAPI_PUT = @"PUT";

//DELETE
static NSString* const CLOUDAPI_DELETE = @"DELETE";


/**
 * HTTP头常量
 */


//请求Header Accept
static NSString* const CLOUDAPI_HTTP_HEADER_ACCEPT = @"Accept";

//请求Body内容MD5 Header
static NSString* const CLOUDAPI_HTTP_HEADER_CONTENT_MD5 = @"Content-MD5";

//请求Header Content-Type
static NSString* const CLOUDAPI_HTTP_HEADER_CONTENT_TYPE = @"Content-Type";

//请求Header UserAgent
static NSString* const CLOUDAPI_HTTP_HEADER_USER_AGENT = @"User-Agent";

//请求Header Date
static NSString* const CLOUDAPI_HTTP_HEADER_DATE = @"Date";

//请求Header Host
static NSString* const CLOUDAPI_HTTP_HEADER_HOST = @"Host";


/**
 * 常用HTTP Content-Type常量
 */


//表单类型Content-Type
static NSString* const CLOUDAPI_CONTENT_TYPE_FORM = @"application/x-www-form-urlencoded; charset=UTF-8";

//流类型Content-Type
static NSString* const CLOUDAPI_CONTENT_TYPE_STREAM = @"application/octet-stream; charset=UTF-8";

//JSON类型Content-Type
static NSString* const CLOUDAPI_CONTENT_TYPE_JSON = @"application/json; charset=UTF-8";

//XML类型Content-Type
static NSString* const CLOUDAPI_CONTENT_TYPE_XML = @"application/xml; charset=UTF-8";

//文本类型Content-Type
static NSString* const CLOUDAPI_CONTENT_TYPE_TEXT = @"application/text; charset=UTF-8";





