#ifndef AndroidNDK_h
#define AndroidNDK_h

#include <android/log.h>
#include <android/looper.h>

#include <pthread.h>

#include <CoreFoundation/CoreFoundation.h>

void android_log(android_LogPriority priority, const char* tag, const char* message) {
    __android_log_print(priority, tag, "%s", message);
}

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

int looperCallback(int fd, int events, void *data) {
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

void setup() {
    CFRunLoopRef mainLoop = CFRunLoopGetMain();
    InternalCFRunLoop *loop = mainLoop;
    __CFPort fd = loop->_wakeUpPort;
    ALooper *looper = ALooper_forThread();
    ALooper_addFd(looper, fd, 0, ALOOPER_EVENT_INPUT, &looperCallback, NULL);

}

#endif
