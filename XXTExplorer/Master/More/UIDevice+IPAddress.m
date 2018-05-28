//
//  UIDevice+IPAddress.m
//  XXTExplorer
//
//  Created by Zheng on 2018/5/28.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "UIDevice+IPAddress.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>

#define IP_ADDR_IPv4 @"ipv4"
#define IP_ADDR_IPv6 @"ipv6"

@implementation UIDevice (IPAddress)

- (NSArray <NSDictionary *> *)getIPAddresses
{
    NSMutableArray <NSDictionary *> *addresses = [NSMutableArray arrayWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if (!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for (interface=interfaces; interface; interface=interface->ifa_next) {
            if (!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if (addr && (addr->sin_family == AF_INET || addr->sin_family == AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type = nil;
                if (addr->sin_family == AF_INET) {
                    if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if (type) {
                    NSString *addr = [NSString stringWithUTF8String:addrBuf];
                    [addresses addObject:@{ @"name": name, @"type": type, @"address": addr }];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    
    return [addresses count] ? addresses : nil;
}

@end
