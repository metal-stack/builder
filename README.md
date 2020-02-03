# Common Builder

## Makefile

Use this repository in your Makefile by including it:

~~~Makefile
BINARY := metal-api
MAINMODULE := <your package>
COMMONDIR := $(or ${COMMONDIR},../../common)

include $(COMMONDIR)/Makefile.inc

release:: all ;
~~~

You have to:

- specify the `BINARY` name. This will be the generated binary, it will be placed in the `bin` folder.
- specify the `MAINMODULE` path. This path should point to the folder of your `main.go`
- specify the `COMMONDIR` is the directory where this repository is located. you *MUST* evaluate if
  there is an environment variable `COMMONDIR` and use this one, so that our CI server
  and multistage builds can set this path to another location than on your local pc.
- overwrite the `release` target (note the two colons after the target name). Normally you should set
  this to the `all` which compiles your go code. But sometimes you want to do something before compiling
  (generate code, etcpp.).

Now you can simply `make` to build a binary

## Dockerfile for builder

You can use the image as a base builder image in your own Dockerfile:

~~~Dockerfile
FROM metalstack/builder:latest as builder
~~~

This base image wants you to have a `go.mod` and a `Makefile` where the default target
creates the binary. This binary will be located in the path `/work/bin/...`.