#ifndef AndroidNDK_h
#define AndroidNDK_h

#include <android/log.h>
#include <android/looper.h>

static inline android_log(android_LogPriority priority, const char* tag, const char* message) {
    __android_log_print(priority, tag, "%s", message);
}

#endif
