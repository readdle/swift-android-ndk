#ifndef AndroidNDK_h
#define AndroidNDK_h

#include <android/looper.h>
#include <android/log.h>

#include <pthread.h>

#include <CoreFoundation/CoreFoundation.h>
#include <dispatch/dispatch.h>

typedef struct _per_run_data {
    uint32_t a;
    uint32_t b;
    uint32_t stopped;
    uint32_t ignoreWakeUps;
} _per_run_data;

typedef pthread_mutex_t _CFRecursiveMutex;
typedef struct __CFRunLoopMode *CFRunLoopModeRef;

// eventfd/timerfd descriptor
typedef int __CFPort;

typedef struct __CFRunLoop {
    CFRuntimeBase _base;
    _CFRecursiveMutex _lock;            /* locked for accessing mode list */
    __CFPort _wakeUpPort;           // used for CFRunLoopWakeUp 
    volatile _per_run_data *_perRunData;              // reset for runs of the run loop
    _CFThreadRef _pthread;
    uint32_t _winthread;
    CFMutableSetRef _commonModes;
    CFMutableSetRef _commonModeItems;
    CFRunLoopModeRef _currentMode;
    CFMutableSetRef _modes;
    struct _block_item *_blocks_head;
    struct _block_item *_blocks_tail;
    CFAbsoluteTime _runTime;
    CFAbsoluteTime _sleepTime;
    CFTypeRef _counterpart;
    _Atomic(uint8_t) _fromTSD;
    Boolean _perCalloutARP;
    CFLock_t _timerTSRLock;
} InternalCFRunLoop;


#define APPNAME "MyApp"

int looperCallback(int fd, int events, void *data) {
    __android_log_print(ANDROID_LOG_VERBOSE, APPNAME, "Start looper callback");
    while (true) {
        int result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, true);
        if (result == kCFRunLoopRunFinished) {
            return 1; // continue listening for events
        }
        if (result == kCFRunLoopRunStopped) {
            return 0; // stop listening
        }
        if (result == kCFRunLoopRunTimedOut) {
            return 1; // continue listening for events   
        }
        if (result != kCFRunLoopRunHandledSource) {
            abort();
            return 0;
        }
    }
    return 1; // continue listening for events
}

int _dispatch_get_main_queue_port_4CF(void);

void setupMainQueue() {
    CFRunLoopRef mainLoop = CFRunLoopGetMain();
    InternalCFRunLoop *loop = mainLoop;
    __CFPort fd = loop->_wakeUpPort;
    ALooper *looper = ALooper_forThread();
    int result = ALooper_addFd(looper, fd, 0, ALOOPER_EVENT_INPUT, &looperCallback, NULL);
    __android_log_print(ANDROID_LOG_VERBOSE, APPNAME, "Setup Main Queue with fd %d with result %d", fd, result);
    loop->_perRunData->ignoreWakeUps = 0x0;

    int d = _dispatch_get_main_queue_port_4CF();
    result = ALooper_addFd(looper, d, 0, ALOOPER_EVENT_INPUT, &looperCallback, NULL);
    __android_log_print(ANDROID_LOG_VERBOSE, APPNAME, "Setup Main Queue with fd %d with result %d", d, result);
}

#endif
