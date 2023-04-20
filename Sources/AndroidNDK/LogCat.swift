//
// Created by Andriy Druk on 9/11/18.
//

import CAndroidNDK

/*
    API for sending log output.
*/
public struct LogCat {

    /*
        Send a VERBOSE log message.
    */
    public static func v(_ tag: String, _ message: String) {
        android_log(ANDROID_LOG_VERBOSE, tag, message)
    }

    /*
        Send a DEBUG log message.
    */
    public static func d(_ tag: String, _ message: String) {
        android_log(ANDROID_LOG_DEBUG, tag, message)
    }

    /*
        Send a INFO log message.
    */
    public static func i(_ tag: String, _ message: String) {
        android_log(ANDROID_LOG_INFO, tag, message)
    }

    /*
        Send a WARN log message.
    */
    public static func w(_ tag: String, _ message: String) {
        android_log(ANDROID_LOG_WARN, tag, message)
    }

    /*
        Send a ERROR log message.
    */
    public static func e(_ tag: String, _ message: String) {
        android_log(ANDROID_LOG_ERROR, tag, message)
    }

    /*
        What a Terrible Failure: Report a condition that should never happen. 
        The error will always be logged at level ASSERT with the call stack. 
        Depending on system configuration, a report may be added to the DropBoxManager and/or the process may be terminated immediately with an error dialog.
    */
    public static func wtf(_ tag: String, _ message: String) {
        android_log(ANDROID_LOG_FATAL, tag, message)
    }
}
