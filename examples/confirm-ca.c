/*
 * Copyright (c) 2011-2014, JANET(UK)
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
#include <libmoonshot.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

int main (int argc, char *argv[])
{
    MoonshotError *error = NULL;
    int success;
    int i;

    if (argc < 4) {
        printf("Usage: confirm-ca <username> <realm> <ta_data_hex>\n");
        return 1;
    }

    char *username = argv[1],
         *realm = argv[2],
         *ta_data_str = argv[3],
         *ta_data = strdup(ta_data_str);

    // Convert to binary
    for (i=0; i<strlen(ta_data_str) / 2; i++)
        sscanf(&ta_data_str[i*2], "%02X", &ta_data[i]);

    success = moonshot_confirm_ca_certificate (username,
                                               realm,
                                               (unsigned char*) ta_data,
                                               strlen(argv[3]) / 2,
                                               &error);

    if (error) {
        printf ("Error: %s\n", error->message);
        return 1;
    }

    printf ("Confirmed: %d for %s@%s %s\n", success, username, realm, argv[3]);
    return 0;
}
