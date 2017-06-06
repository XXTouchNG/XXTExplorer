//
//  XXTEDispatchDefines.h
//  XXTExplorer
//
//  Created by Zheng on 01/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTEDispatchDefines_h
#define XXTEDispatchDefines_h

#import <pthread.h>

/**
 Whether in main queue/thread.
 */
static inline bool dispatch_is_main_queue() {
    return pthread_main_np() != 0;
}

/**
 Submits a block for asynchronous execution on a main queue and returns immediately.
 */
static inline void dispatch_async_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/**
 Submits a block for execution on a main queue and waits until the block completes.
 */
static inline void dispatch_sync_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

#endif /* XXTEDispatchDefines_h */
