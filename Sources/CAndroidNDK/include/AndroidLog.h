#ifndef AndroidLog_h
#define AndroidLog_h

#include <android/log.h>

static inline void android_log(android_LogPriority priority, const char* tag, const char* message) {
    __android_log_print(priority, tag, "%s", message);
}

#endif