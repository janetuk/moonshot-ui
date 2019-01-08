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

#include <stdio.h>

int main (int    argc,
          char *argv[])
{
    MoonshotError *error = NULL;
    int success;

    char *nai,
         *password,
         *server_certificate_hash,
         *ca_certificate,
         *subject_name_constraint,
         *subject_alt_name_constraint;

    success = moonshot_get_identity ("",
                                     "",
                                     "",
                                     &nai,
                                     &password,
                                     &server_certificate_hash,
                                     &ca_certificate,
                                     &subject_name_constraint,
                                     &subject_alt_name_constraint,
                                     &error);

    if (success) {
        printf ("Got identity: %s %s %s\n", nai, password, server_certificate_hash);

        moonshot_free (nai);
        moonshot_free (password);
        moonshot_free (server_certificate_hash);
        moonshot_free (ca_certificate);
        moonshot_free (subject_name_constraint);
        moonshot_free (subject_alt_name_constraint);

        return 0;
    } else {
        printf ("Error: %s\n", error->message);
        return 1;
    }
}
