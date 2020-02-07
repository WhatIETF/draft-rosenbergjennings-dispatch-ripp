# draft-rosenbergjennings-dispatch-ripp
real time internet peering protocol



# How to build these drafts

## Docker

Get a docker image with the tools by doing
`docker pull fluffy/rfc `
Or you can build the tool image yourself

Build the drafts with
`
    docker run --rm --mount type=bind,source="$(pwd)",destination=/data
    fluffy/rfc
` 

## Native

If you have all the right tools installed you can just type make

