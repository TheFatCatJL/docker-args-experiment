# DOCKERFILE ARG Experiment
This repository is created to quickly explore the peculiar rules of docker args, especially in the sequence of their appearance in the file.

## Rule 1 - ARG declared before FROM Statements
These args are meant to used by FROM statements and:
1. They cannot be called other than in the FROM statement 
2. They are the means for dynamic values in the FROM statement (note we cannot use them for the alias)


### ARG outside the FROM statement is not available to the rest of the Build

```bash
# RUN THIS IN TERMINAL
docker build --no-cache --progress=plain --target box-a .

# RESULT
#5 0.469 Variable VAR_1 value: 
#6 0.523 Variable VAR_2 value: 
```

```DOCKERFILE
ARG VAR_1="I am VAR_1 in the first ARG block"
ARG VAR_2="I am VAR_2 in the first ARG block"
### box-a ###
FROM busybox as box-a
RUN echo "----------ECHO FROM box-a----------"
RUN echo "Variable VAR_1 value: ${VAR_1}"
RUN echo "Variable VAR_2 value: ${VAR_2}"
ARG VAR_TAG_123=busybox:1.23
ENV VAR_0="I am VAR_0 in the box-a block"
CMD ["tail", "/dev/null"]
```

### ARG outside the FROM statement can be accessed by FROM statements

```bash
# RUN THIS IN TERMINAL
docker build --no-cache --progress=plain --target box-b .

# RESULT
#8 0.541 ----------ECHO FROM box-b----------
# We can see this echo without error because ARG is declared before FROM
```

```DOCKERFILE
ARG VAR_BOX_CHOICE=box-a
### box-b ###
FROM ${VAR_BOX_CHOICE} as box-b
RUN echo "----------ECHO FROM box-b----------"
CMD ["tail", "/dev/null"]
```

```bash
# RUN THIS IN TERMINAL
docker build --no-cache --progress=plain --target box-d .

# RESULT
#5 0.541 ----------ECHO FROM box-d----------
#6 0.436 syslogd started: BusyBox v1.35.0
# We can that busybox v1.35.0 is installed since we pass in ARG VAR_TAG_135
```

```DOCKERFILE
### box-d ###
FROM ${VAR_TAG_135} as box-d
RUN echo "----------ECHO FROM box-d----------"
RUN strings /bin/busybox | grep 'BusyBox'
CMD ["tail", "/dev/null"]
```

### ARG after the FROM statement is not accessible by FROM statements

```bash
# RUN THIS IN TERMINAL
docker build --no-cache --progress=plain --target box-c .

# RESULT
# failed to solve with frontend dockerfile.v0: failed to create LLB definition: base name (${VAR_TAG_123}) should not be blank

# VAR_TAG needs to be an ARG to be used by builder and has to be declare BEFORE FROM
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
```

```DOCKERFILE
### box-c ###
FROM ${VAR_TAG_123} as box-c
RUN echo "----------ECHO FROM box-c----------"
RUN strings /bin/busybox | grep 'BusyBox'
CMD ["tail", "/dev/null"]
```

## Rule 2 - ARG declared after FROM Statements
These args are meant to used by the other statements in the build:
1. They persist from the stage which they are declared (CURRENT STAGE), and will be CARRIED over to the next built stage (if CURRENT STAGE is declared in FROM) - However, they will not persist in RUNTIME (as always for ARG)
2. ARG values can be declared in many ways, eg. via default values, env-file, built-arg etc.

### build-arg as a way to pass in dynamic BUILD values

```bash
# RUN THIS IN TERMINAL
docker build --no-cache --progress=plain --target --build-arg VAR_4="test value for VAR_4" box-e .

# RESULT
#9 0.579 Variable VAR_3 value: I am VAR_3 in the box-e block
#10 0.592 Variable VAR_4 value: test value for VAR_4
```

```DOCKERFILE
### box-e ###
FROM box-a as box-e
RUN echo "----------ECHO FROM box-e----------"
ARG VAR_3="I am VAR_3 in the box-e block"
ARG VAR_4
RUN echo "Variable VAR_3 value: ${VAR_3}"
RUN echo "Variable VAR_4 value: ${VAR_4}"

ENV VAR_4 ${VAR_4}
# ENV can be passed to runtime stage

CMD ["tail", "/dev/null"]
```

### All ARG values will not persist in RUN TIME

```bash
# RUN THIS IN TERMINAL
docker build --no-cache --progress=plain --target box-f --build-arg VAR_4="test value for VAR_4" -t busyexperiment .
docker run --rm busyexperiment env

# RESULT
# VAR_0=I am VAR_0 in the box-a block
# VAR_4=test value for VAR_4
```

```DOCKERFILE
### box-f ###
FROM box-e as box-f
RUN echo "----------ECHO FROM box-f----------"
RUN env | grep VAR_3
# VAR_3 will only be available during BUILD TIME
RUN env | grep VAR_4
# VAR_4 is carried forward to next stage as env
RUN env | grep VAR_0
# VAR_0 is carried forward since the first stage

CMD ["tail", "/dev/null"]
```
