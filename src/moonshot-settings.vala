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

using Gtk;

   
private MoonshotLogger logger()
{
    return get_logger("MoonshotSettings");
}

static const string KEY_FILE_NAME="moonshot-ui.config";

private KeyFile get_keyfile()
{
    KeyFile key_file = new KeyFile();
    string config_dir = Environment.get_user_config_dir();
    logger().trace("get_keyfile: config_dir=" + config_dir);

    File dir = File.new_for_path(config_dir);
    string path = dir.get_child(KEY_FILE_NAME).get_path();

    try {
        if (key_file.load_from_file(path, KeyFileFlags.NONE))
            logger().trace("get_keyfile: load_from_file returned successfully");
        else
            logger().trace("get_keyfile: load_from_file returned false");            
    }
    catch (FileError e) {
        logger().trace("get_keyfile: FileError: " + e.message);
    }
    catch (KeyFileError e) {
        logger().trace("get_keyfile: KeyFileError: " + e.message);
    }

    return key_file;
}


private void save_keyfile(KeyFile key_file)
{
    string config_dir = Environment.get_user_config_dir();
    File dest = null;

    // Make the directory if it doesn't already exist; ignore errors.
	try {
		File dir = File.new_for_path(config_dir);
        dest = dir.get_child(KEY_FILE_NAME);
		dir.make_directory_with_parents();
	} catch (Error e) {
        logger().trace("save_keyfile: make_directory_with_parents threw error (this is usually ignorable) : " + e.message);
	}

    // It would be nice to use key_file.save_to_file, but the binding doesn't exist
    // in earlier versions of valac
    // key_file.save_to_file(path.get_path());

    string data = key_file.to_data();
    try {
        logger().trace("save_keyfile: saving to file path '%s'".printf(dest.get_path()));
        // FileOutputStream s = dest.create(FileCreateFlags.REPLACE_DESTINATION | FileCreateFlags.PRIVATE);
        // var ds = new DataOutputStream(s);
        // ds.put_string(data);
        string new_etag;
        dest.replace_contents(data.data, null, false, FileCreateFlags.REPLACE_DESTINATION | FileCreateFlags.PRIVATE, out new_etag);
    }
    catch(Error e) {
        logger().error("save_keyfile: error when writing to file: " + e.message);
    }

    // streams close automatically
}

internal void set_bool_setting(string group_name, string key_name, bool value, KeyFile? key_file=null)
{
    KeyFile tmp_key_file = null;
    if (key_file == null) {
        // Use tmp_key_file to hold an owned reference (since key_file is unowned)
        tmp_key_file = get_keyfile();
        key_file = tmp_key_file;
    }

    key_file.set_boolean(group_name, key_name, value);

    if (tmp_key_file != null) {
        // This is a "one-shot" settings update; save it now.
        save_keyfile(key_file);
    }
}

internal bool get_bool_setting(string group_name, string key_name, bool default=false, KeyFile? key_file=null)
{
    KeyFile tmp_key_file = null;
    if (key_file == null) {
        // Use tmp_key_file to hold an owned reference (since key_file is unowned)
        tmp_key_file = get_keyfile();
        key_file = tmp_key_file;
    }

    if (key_file == null)
        return default;

    try {
        if (!key_file.has_key(group_name, key_name))
        {
            logger().info(@"get_bool_setting : key file doesn't contain key '$key_name' in group '$group_name'");
            return default;
        }
    }
    catch(KeyFileError e) {
        logger().info(@"get_bool_setting : KeyFileError checking if key '$key_name' exists in group '$group_name' (maybe ignorable?) : " + e.message);
    }

    try {
        // throws KeyFileError if key is not found
        return key_file.get_boolean(group_name, key_name);
    }
    catch (KeyFileError e) {
        logger().info("get_bool_setting got KeyFileError (may be ignorable) : " + e.message);
    }
    return default;
}


internal void set_string_setting(string group_name, string key_name, string value, KeyFile? key_file=null)
{
    KeyFile tmp_key_file = null;
    if (key_file == null) {
        // Use tmp_key_file to hold an owned reference (since key_file is unowned)
        tmp_key_file = get_keyfile();
        key_file = tmp_key_file;
    }

    key_file.set_string(group_name, key_name, value);
    if (tmp_key_file != null) {
        // This is a "one-shot" settings update; save it now.
        save_keyfile(key_file);
    }
}

internal string get_string_setting(string group_name, string key_name, string default="", KeyFile? key_file=null)
{
    KeyFile tmp_key_file = null;
    if (key_file == null) {
        // Use tmp_key_file to hold an owned reference (since key_file is unowned)
        tmp_key_file = get_keyfile();
        key_file = tmp_key_file;
    }

    if (key_file == null)
        return default;

    try {
        if (!key_file.has_key(group_name, key_name))
        {
            logger().info(@"get_string_setting : key file doesn't contain key '$key_name' in group '$group_name'");
            return default;
        }
    }
    catch(KeyFileError e) {
        logger().info(@"get_string_setting : KeyFileError checking if key '$key_name' exists in group '$group_name' (maybe ignorable?) : " + e.message);
    }

    try {
        // throws KeyFileError if key is not found
        return key_file.get_string(group_name, key_name);
    }
    catch (KeyFileError e) {
        logger().info("get_string_setting got KeyFileError (may be ignorable) : " + e.message);
    }
    return default;
}
