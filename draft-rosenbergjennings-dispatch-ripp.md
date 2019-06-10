%%%

#
# RIPP - real time internet peering protocol
#
# Generation tool chain:
#   mmark (https://github.com/miekg/mmark)
#   xml2rfc (http://xml2rfc.ietf.org/)
#


Title = "Real Time Internet Peering Protocol"
abbrev = "RIPP"
category = "std"
docName = "draft-rosenbergjennings-dispatch-ripp-00"
ipr= "trust200902"
area = "Internet"
keyword = ["RTP"]

[pi]
symrefs = "yes"
sortrefs = "yes"

[[author]]
initials = "C."
surname = "Jennings"
fullname = "Cullen Jennings"
organization = "Cisco Systems"
  [author.address]
  email = "fluffy@iii.ca"

[[author]]
initials = "J."
surname = "Rosenberg"
fullname = "Jonathan Rosenberg"
organization = "Five9"
  [author.address]
  email = "jdrosen@jdrosen.net"

%%%

.# Abstract

This document specifies the Realtime Internet Peering Protocol
(RIPP). RIPP is used to provide telephony peering between two
providers, and is targeted specifically at interconnections between a
telephony provider and an application provider (such as a cloud
contact center) that wishes to send and receive calls to the telephone
network. RIPP is an alternative to SIP and RTP for this use case, and
is designed to run ontop of HTTP/3. Using HTTP/3 allows application
providers to more easily build their applications ontop of cloud
platforms, such as AWS, Azure and Google Cloud, all of which are
heavily focused on HTTP based services.

{mainmatter}

# Introduction

Cloud computing platforms, such as those provided by Amazon, Azure,
and Google, have now become mainstream for the development of software
applications. These platforms are targeted at enabling web
applications, and as such many of their features are based on the
usage of HTTP.

One example are HTTP load balancers. Cloud computing platforms provide
highly scalable, geographically distributed, redundant load
balancers. These load balancers can monitor the state of downstream
servers and can uniformly distribute load amongst them. The load
balancers can compensate for failure of individual nodes and send new
traffic to other nodes.

Autoscaling is another example. The cloud computing platforms can
automatically add new instances of a server backend, or remove them,
and automatically configure the load balancers to include them in the
pool of available servers.

Yet another example is Kubernetes, which allows web-based applications
to be deployed into containers (typically Docker), with load
balancing, scaling, and HTTP request routing. A more recent technology
is Istio, which utilizes an HTTP proxy (Envoy) to provide managed
routing between HTTP services, with features such as canary deploys.

Another example are HTTP tracing tools, which facilitate the tracing
of requests through distributed microservices. These tools can
autogenerate sequence diagrams and facilitate in troubleshooting.

Unfortunately, there are many applications being deployed into these
cloud platforms which require interconnection with the public switched
telephone network (PSTN). Examples of such applications include cloud
PBXs, cloud contact centers, cloud meetings applications, and so
on. Furthermore, commerce websites would like to allow customers
to call into the telephone network for support.

In order for these applications to connect to the PSTN, they typically
deploy SIP-based servers - SBCs, SIP proxies, and softswitches, to
provide this interconnection. Unfortunately, SIP based applications
cannot make use of the many capabilities these cloud platforms afford
to HTTP based applications. These SIP servers are usually deployed on
bare metal or VMs at best. Application developers must build their own
load balancing, HA, failover, clustering, and scaling techniques,
rather than using the capabilities of these platforms.

The goal of this specification is to define a new protocol that can be
used instead of SIP and RTP for the purposes of interconnection of
cloud-based applications to the PSTN. This protocol does not actually
deprecate or replace SIP itself, as it covers only a small subset of
the broader functionality that SIP provides.

# Reference Architecture

Two use cases - SIP provider to cloud app, and cloud app to cloud app.

## SIP Provider to Cloud Provider

## Cloud Provider to Cloud Provider

# Solution Requirements

Stuff like: no changes to http3, work through load balancers, one or
more load balancers in tandem, autoscaling, rolling upgrades. Support
case where all media goes to same server for a call, or can be sprayed
across them. Quick recovery from failed servers, which never take call
down. Low latency for RTP. Audio only.

# Design Approaches

What are the big changes from SIP and why.

## Client to Server

Not a multihop protocol, only specified between a client and an
authoritative server.

## Signaling and Media Together

Media flows with signaling, not separate. Separation of media and
signaling not used today on peering links.

## No IPs

Unlike SIP, everything is an HTTP resource.

## HTTP Security

Authentication is OAuth based from client to server; cert-based for
server to client. Calls in each direction require each side to obtain
OAuth tokens. No usage of MTLS. Secure only using HTTP3 which requires
TLS1.3. Since media over HTTP, media is encrypted. No SRTP as a result
- must be decrypted if in use at the SBC.

## Easy Gateway to SIP

Easy to implement in existing SBCs. SIP headers with e2e significance
are copied through (e.g., Identity).

## Authenticated CallerID

STIR is required.

# Overview of Operation

## Initiating Calls

Client initiates the call. Call initiation is an HTTP request and will
be sent over a new stream. The response is a reference to a call
object that was created, identified by a URI. Structure of this URI
allows flexibility in design for receiving side of calls. If you want
all further transactions for this specific call to go to same backend
server, you can use a URI which is configured to route to that
specific server. In other words, each server instance is its own REST
endpoint.

Alternative: to get all mid-call requests and media to the same
instance we can use session stickiness - common feature in http load
balancers. This might be better - but we'd need to check on how well
this is supported. 

## Ongoing Signaling

New request immediately initiated by the client to the URI learned in
the response to the initial call request. This request is a long lived
request - headers, followed by a series of data frames. Final
trailing header only sent once the call is over. SImilarly, server
sends a response immediately - provisonal headers, final headers,
followed by a long stream of data frames. This creates a bidirectional
stream of data frames which are used to convey signaling for the
call.

Ongoing signaling operations are used to move the call along a defined
state machine - from created (the result of the initial call request),
to pending, to ringing, to connected or terminated. Once established,
mid-call signaling exists to terminate the call, and to gracefully
move the call to another server instance to facilitate
maintenance. There is no equivalent of re-INVITE.

## Media Negotiation

There is no offer-answer model. Only two codecs are supported - G711
and Opus. All entities must support it. Without the need to signal
media destinations - IP and ports - there is no longer a need for
SDP. Either side can modify codecs at will, without signaling. They
can also adjust frame sizes within a range defined by this
specification. There is no SRTP.

Future extensions will consider the addition of a declarative model,
where each side can send settings which are then cached and span
across multiple calls, in much the same way it works with HTTP/3
itself. 

## Media

THe approach for media is media striping. Once call is in pending
state, client opens N (N=10 maybe? 20?) streams using N requests,
targeted to the URI associated with the call. As with signaling, these
are long lived for the duration of the call and establish a
bidirectional data stream.

To avoid HOL blocking, we cannot send a second media packet on a stream
until we are sure the first media packet was received. This is why we
open N streams. A media packet is sent on a stream by the client. Once
it is sent, that stream is no longer used for media. Once the other
side receives the media packet, it sends back an application-layer ack
that informs the sender that the media packet was receivd and
therefore there is no blocking on that stream. The sender may then
once again use that stream. This causes media packets to be sprayed
across the streams sequentially. The number of streams that must be
opened to ensure no HOL blocking are a function of the RTT delay and
packet loss tolerance. TOOD: Need some math here.

There is no need for sender or receiver reports. The equivalent
information is knowable from the application layer acks. This allows
either endpoint to generate receiver and sender reports in gateway
functions. 

## Call Termination

Signaling allows an application layer call end to be sent. This will
also cause each side to termiante the request and media streams with
end flags per HTTP3 specs.

## Graceful Call Migration

To facilitate operational maintenance, the protocol has built in
support for allowing a server instance to drain all active calls to
another server instance.

Either endpoint can issue a move command over the signaling channel,
which includes a new URI that the peer should use. Once received, the
streams are closed and the peer initiates a new signaling connection
to the URI it just received, and in parallel re-establishes media. All
media received during the migration phase is buffered to ensure there
is no packet loss (though there will be jitter) during the migration
period.

We dont use QUIC layer connection migration, as that is triggered by
network changes and not likely to be exposed to applications.

## Ungraceful Call Migration

Since all media packets are acknowledged at the application layer, it
is possible for endpoints to very quickly detect server failures,
network failures, and other related problems. The protocol specifies
how such failures are detected. In response to them, the client
generates a request to the top-level URI for establishing new calls,
but indicates its a re-establishment due to failure. A normal call
setup proceeds but the far side knows this is re-establishing a prior
call. It can then reconnect it to the next-hop. 

# Protocol Semantics

## Client Behavior

## Server Behavior

# Protocol Syntax

Use SIP header field syntax, but with QPACK compression.

# SIP to RIPP Gatewaying

# RIPP to SIP Gatewaying

# IANA Considerations

# Security Considerations

# Acknowledgements


{backmatter}

