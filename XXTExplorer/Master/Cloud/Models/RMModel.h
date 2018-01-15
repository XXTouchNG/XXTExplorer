//
//  RMModel.h
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <JSONModel/JSONModel.h>
#import <PromiseKit/PromiseKit.h>

@interface RMModel : JSONModel

+ (PMKPromise *)promiseResponse:(NSDictionary *)resp;

+ (PMKPromise *)promiseGETRequest:(NSString *)url;
+ (PMKPromise *)promisePOSTRequest:(NSString *)url POSTFields:(NSDictionary *)fields;

@end
