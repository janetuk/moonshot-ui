# Makefile for use with NMAKE

# Base path of MSVC installation
VC_PATH=c:\Program Files\Microsoft SDKs\Windows\v6.0\VC

# Base path of Windows SDK installation
SDK_PATH=c:\Program Files\Microsoft SDKs\Windows\v6.0

CL=$(VC_PATH)\bin\cl.exe
LINK=$(VC_PATH)\bin\link.exe

all: msvc-example.exe

msvc-example.obj: msvc-example.c
	"$(CL)" msvc-example.c -c -I..\..\libmoonshot -I"$(VC_PATH)\INCLUDE" -F$@

msvc-example.exe: msvc-example.obj
	"$(LINK)" msvc-example.obj ..\..\libmoonshot\libmoonshot.lib -LIBPATH:"$(VC_PATH)\LIB" -LIBPATH:"$(SDK_PATH)\LIB" -OUT:$@
