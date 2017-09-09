
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <string.h> 
#include <ctype.h>
#include "jsmn.h"

typedef enum {
    MOONSHOT_ERROR_UNABLE_TO_START_SERVICE,
    MOONSHOT_ERROR_NO_IDENTITY_SELECTED,
    MOONSHOT_ERROR_INSTALLATION_ERROR,
    MOONSHOT_ERROR_OS_ERROR,
    MOONSHOT_ERROR_IPC_ERROR
} MoonshotErrorCode;

typedef struct {
    int   code;    /* A MoonshotErrorCode */
    char *message;
} MoonshotError;

char * system_output(char *command) {
  	FILE *fp;

	char buf[100];
	char *str = NULL;
	char *temp = NULL;
	unsigned int size = 1;  // start with size of 1 to make room for null terminator
	unsigned int strlength;

 	fp = popen(command, "r");

    if (fp == NULL) {
        printf("Failed to run command\n" );
        return 0;
    }

	while (fgets(buf, sizeof(buf), fp) != NULL) {
	    strlength = strlen(buf);
	    temp = realloc(str, size + strlength);  // allocate room for the buf that gets appended
	    if (temp == NULL) {
	      // allocation error
	    } else {
	      str = temp;
	    }
	    strcpy(str + size - 1, buf);     // append buffer to str
	    size += strlength; 
	}
	   pclose(fp);
    return str;
}

static int jsoneq(const char *json, jsmntok_t *tok, const char *s) {
    if ((int) strlen(s) == tok->end - tok->start && strncmp(json + tok->start, s, tok->end - tok->start) == 0) {
        return 0;
    }
    return -1;
}

char *trimwhitespace(char *str)
{
    char *end;

    while(isspace((unsigned char)*str)) str++;

    if(*str == 0)  // All spaces?
      return str;

    end = str + strlen(str) - 1;
    while(end > str && isspace((unsigned char)*end)) end--;

    *(end+1) = 0;

    return str;
}


int moonshot_get_identity (const char     *nai,
                           const char     *password,
                           const char     *service,
                           char          **nai_out,
                           char          **password_out,
                           char          **server_certificate_hash_out,
                           char          **ca_certificate_out,
                           char          **subject_name_constraint_out,
                           char          **subject_alt_name_constraint_out,
                           MoonshotError **error) {

    int totalChars = sizeof(nai) + sizeof(password) + sizeof(service) + 197; // 198 is the char count of the format string.
    char *appleScript = (char*)malloc(totalChars+1);
    sprintf(appleScript, "osascript -e 'tell application \"Moonshot\"\nrequest_get_identity nai \"%s\" password \"%s\" service \"%s\"\nrepeat until status_get_identity\ndelay 1.0\nend repeat\nresult_get_identity\nend tell'", nai, password, service);
    char *jsonUntrimmedResult = system_output(appleScript);
    char *jsonResult = trimwhitespace(jsonUntrimmedResult);


    //Quit the identity selector
    system_output("osascript -e 'tell application \"Moonshot\"\nquit\nend tell'");

    // Parse the json
    int parsedKeys;
    jsmn_parser p;
    jsmntok_t t[128]; /* We expect no more than 128 tokens */
    jsmn_init(&p);
    parsedKeys = jsmn_parse(&p, jsonResult, strlen(jsonResult), t, sizeof(t)/sizeof(t[0]));
    if (parsedKeys < 0) {
      printf("Failed to parse JSON: %d\n", parsedKeys);
      return 0;
    }

    for (int keyIndex = 1; keyIndex < parsedKeys; keyIndex++) {
        if (jsoneq(jsonResult, &t[keyIndex], "nai_out") == 0) {
            *nai_out = malloc(t[keyIndex+1].end-t[keyIndex+1].start+1);
            sprintf(*nai_out,"%.*s", t[keyIndex+1].end-t[keyIndex+1].start,jsonResult + t[keyIndex+1].start);
            keyIndex++;
        }

        if (jsoneq(jsonResult, &t[keyIndex], "password_out") == 0) {
            *password_out = malloc(t[keyIndex+1].end-t[keyIndex+1].start+1);
            sprintf(*password_out,"%.*s", t[keyIndex+1].end-t[keyIndex+1].start,jsonResult + t[keyIndex+1].start);
            keyIndex++;
        }

        if (jsoneq(jsonResult, &t[keyIndex], "server_certificate_hash_out") == 0) {
            *server_certificate_hash_out = malloc(t[keyIndex+1].end-t[keyIndex+1].start+1);
            sprintf(*server_certificate_hash_out,"%.*s", t[keyIndex+1].end-t[keyIndex+1].start,jsonResult + t[keyIndex+1].start);
            keyIndex++;
        }

        if (jsoneq(jsonResult, &t[keyIndex], "ca_certificate_out") == 0) {
            *ca_certificate_out = malloc(t[keyIndex+1].end-t[keyIndex+1].start+1);
            sprintf(*ca_certificate_out,"%.*s", t[keyIndex+1].end-t[keyIndex+1].start,jsonResult + t[keyIndex+1].start);
            keyIndex++;
        }

        if (jsoneq(jsonResult, &t[keyIndex], "subject_name_constraint_out") == 0) {
            *subject_name_constraint_out = malloc(t[keyIndex+1].end-t[keyIndex+1].start+1);
            sprintf(*subject_name_constraint_out,"%.*s", t[keyIndex+1].end-t[keyIndex+1].start,jsonResult + t[keyIndex+1].start);
            keyIndex++;
        }

        if (jsoneq(jsonResult, &t[keyIndex], "subject_alt_name_constraint_out") == 0) {
            *subject_alt_name_constraint_out = malloc(t[keyIndex+1].end-t[keyIndex+1].start+1);
            sprintf(*subject_alt_name_constraint_out,"%.*s", t[keyIndex+1].end-t[keyIndex+1].start,jsonResult + t[keyIndex+1].start);
            keyIndex++;
        }
    }

    return 0;
}

int main() {

	char *nai = NULL;
    char *password = NULL;
    char *serverCertificateHash = NULL;
    char *caCertificate = NULL;
    char *subjectNameConstraint = NULL;
    char *subjectAltNameConstraint = NULL;
    MoonshotError *error = NULL;

    moonshot_get_identity("naidummy",
    				"passworddummy",
    				"servicedummy",
    				&nai,
    				&password,
    				&serverCertificateHash,
    				&caCertificate,
    				&subjectNameConstraint,
    				&subjectAltNameConstraint,
    				&error);
    printf("nai: %s\n", nai);
    printf("password: %s\n", password);

    return 0;
}

