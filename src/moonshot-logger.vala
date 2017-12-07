/*
 * Copyright (c) 2011-2016, JANET(UK)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of JANET(UK) nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


public MoonshotLogger get_logger(string name) {
    return new MoonshotLogger(name);
}


#if USE_LOG4VALA

static void glib_default_log_handler(string? log_domain, LogLevelFlags log_level, string message)
{
    Log4Vala.Logger logger = Log4Vala.Logger.get_logger(log_domain ?? "Glib");
    stderr.printf(log_level.to_string() + " : " + message ?? "" + "\n");
    logger.error("Glib error level: " + log_level.to_string() + " : " + (message ?? ""));
}

/** Logger class that wraps the Log4Vala logger */
public class MoonshotLogger : Object {
    static bool logger_is_initialized = false;

    private Log4Vala.Logger logger;

    public MoonshotLogger(string name) {
        if (!logger_is_initialized) {
            Log.set_default_handler(glib_default_log_handler);

#if IPC_MSRPC
            // Look for config file in the app's current directory.
            string conf_file = "log4vala.conf";
#else
            string conf_file = GLib.Environment.get_variable("MOONSHOT_UI_LOG_CONFIG");
#endif
            Log4Vala.init(conf_file);
            logger_is_initialized = true;
        }

        logger = Log4Vala.Logger.get_logger(name);
    }

    /**
     * Log a trace message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void trace(string message, Error? e = null) {
        logger.trace(message, e);
    }


    /**
     * Log a debug message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void debug(string message, Error? e = null) {
        logger.debug(message, e);
    }


    /**
     * Log an info message.
     * @param e optional Error to be logged
     */
    public void info(string message, Error? e = null) {
        logger.info(message, e);
    }

    /**
     * Log a warning message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void warn(string message, Error? e = null) {
        logger.warn(message, e);
    }

    /**
     * Log an error message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void error(string message, Error? e = null) {
        logger.error(message, e);
    }

    /**
     * Log a fatal message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void fatal(string message, Error? e = null) {
        logger.fatal(message, e);
    }
}


#else

/** Logger that currently does nothing, but may eventually write to stdout or a file if enabled */
public class MoonshotLogger : Object {
    FileStream? stream = null;
    internal MoonshotLogger(string name) {
        string? filename = GLib.Environment.get_variable("MOONSHOT_LOG_FILE");
        if (filename != null)
            stream = FileStream.open(filename, "a");
    }

    /**
     * Log a trace message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void trace(string message, Error? e = null) {
        if (stream != null) {
            stream.printf(message + "\n");
            stream.flush();
        }
    }


    /**
     * Log a debug message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void debug(string message, Error? e = null) {
        trace(message, e);
    }


    /**
     * Log an info message.
     * @param e optional Error to be logged
     */
    public void info(string message, Error? e = null) {
        trace(message, e);
    }

    /**
     * Log a warning message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void warn(string message, Error? e = null) {
        trace(message, e);
    }

    /**
     * Log an error message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void error(string message, Error? e = null) {
        trace(message, e);
    }

    /**
     * Log a fatal message.
     * @param message log message
     * @param e optional Error to be logged
     */
    public void fatal(string message, Error? e = null) {
        trace(message, e);
    }
}

#endif
