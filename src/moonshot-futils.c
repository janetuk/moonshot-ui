#ifdef HAVE_GETPWUID
#include <stdlib.h>
#include <sys/types.h>
#include <pwd.h>
#endif

const char * GetUserName()
{
#ifdef HAVE_GETPWUID
   struct passwd *pwd = getpwuid(getuid());
   return pwd ? pwd->pw_name : "unknown";
#else
   return "unknown";
#endif
}

const char * GetFlatStoreUsersFilePath()
{
   return MOONSHOT_FLATSTORE_USERS;
}
