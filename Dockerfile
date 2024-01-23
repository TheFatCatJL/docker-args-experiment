### ARG BLOCK ###
ARG VAR_1="I am VAR_1 in the first ARG block"
ARG VAR_2="I am VAR_2 in the first ARG block"
ARG VAR_BOX_CHOICE=box-a
ARG VAR_TAG_135=busybox:1.35.0

### box-a ###
FROM busybox as box-a
RUN echo "----------ECHO FROM box-a----------"
RUN echo "Variable VAR_1 value: ${VAR_1}"
RUN echo "Variable VAR_2 value: ${VAR_2}"
ARG VAR_TAG_123=busybox:1.23
ENV VAR_0="I am VAR_0 in the box-a block"
CMD ["tail", "/dev/null"]

### box-b ###
FROM ${VAR_BOX_CHOICE} as box-b
RUN echo "----------ECHO FROM box-b----------"
CMD ["tail", "/dev/null"]
# We can see this echo without error because ARG is declared before FROM

### box-c ###
# FROM ${VAR_TAG_123} as box-c
# RUN echo "----------ECHO FROM box-c----------"
# RUN strings /bin/busybox | grep 'BusyBox'
# CMD ["tail", "/dev/null"]
# failed to solve with frontend dockerfile.v0: failed to create LLB definition: base name (${VAR_TAG_123}) should not be blank
# VAR_TAG needs to be an ARG to be used by builder and has to be declare BEFORE FROM
# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact

### box-d ###
FROM ${VAR_TAG_135} as box-d
RUN echo "----------ECHO FROM box-d----------"
RUN strings /bin/busybox | grep 'BusyBox'
CMD ["tail", "/dev/null"]
# We can that busybox v1.35.0 is installed since we pass in ARG VAR_TAG_135


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