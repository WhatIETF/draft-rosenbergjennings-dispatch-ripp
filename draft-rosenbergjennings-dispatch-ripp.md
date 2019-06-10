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

## Background

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
balancing, scaling, and HTTP request routing.

Another example are HTTP tracing tools, which facilitate the tracing
of requests through distributed microservices. These tools can
autogenerate sequence diagrams and facilitate in troubleshooting.

Yet another example are API gateways (such as APIGee and Kong), which
provide authentication and authorization, provisioning of
applications, rate limiting, analytics, sandboxing for testing,
embedded documentation, and so on.

And yet another example are denial-of-service prevention techniques,
typically done using BGP peering and re-routing. Though in principle
these technicques can work for VoIP, they are deployed in conjunction
with the load balancers which represent the entry point into these
cloud provider networks. Consequently, the protections these cloud
providers offer do not extend to applications which merely use these
platforms for virtual machines. 

A more recent technology are service meshes, such as Istio, which
utilize sidecar HTTP proxies to facilitate inter-service
communications. These systems come with robust control planes which
enable additional routing features, such as canary deploys, percentage
based routing, and so on. 

## Problem Statement

Unfortunately, there are many applications being deployed into these
cloud platforms which require interconnection with the public switched
telephone network (PSTN). Examples of such applications include cloud
PBXs, cloud contact centers, cloud meetings applications, and so
on. Furthermore, commerce websites would like to allow customers
to call into the telephone network for customer support.

In order for these applications to connect to the PSTN, they typically
deploy SIP-based servers - SBCs, SIP proxies, and softswitches, to
provide this interconnection. Unfortunately, SIP based applications
cannot make use of the many capabilities these cloud platforms afford
to HTTP based applications. These SIP servers are usually deployed on
bare metal or VMs at best. Application developers must build their own
load balancing, HA, failover, clustering, security, and scaling
technologies, rather than using the capabilities of these platforms.

This has creating a barrier to entry, particularly for applications
such as websites which are not expert in VoIP
technologies. Furthermore, it has meant that VoIP applications have
been unable to take advantage of the many technology improvements that
have come to networking and protocol design since the publication of
RFC 3261 in 2002.

## Solution

The goal of RIPP is to enable one administrative domain to send and
receive voice calls with another domain. In this regard, RIPP replaces
the usage of SIP, SDP and RTP for this particular use case. RIPP does
not actually deprecate or replace SIP itself, as it covers only a
small subset of the broader functionality that SIP provides. It is
designed to be the minimum protocol required to interconnect voice.

In order to make use of new HTTP based technologies as described
above, RIPP is not an extension to HTTP3, but rather is a usage of
it. The goal is to ride the coattails of advancement in HTTP based
technologies without requiring them to do anything special for the
benefit of VoIP.

## Why Now?

The idea of reconverging HTTP and SIP is certainly not new, and indeed
has been discussed in the hallways of IETF for many years. However,
several significant limitations made this previously infeasibile:

1. HTTP utilized TCP, which meant that it created head-of-line
blocking which would delay lost packets rather than just discard
them. This will often provide intolerable latency for VoIP.

2. HTTP was request response, allowing the client to send requests and
receive a response. There as no way for a server to asynchronously
send information to the client in an easy fashion.

HTTP2 addressed the second of these with the introduction of pushes
and long running requests. However, its usage of TCP was still a
problem. This has finally been addressed with the arrival of QUIC and
HTTP3. QUIC is based on UDP, and it introduces the concept of a
stream. These streams are carried over UDP, and though are still
reliable, there is no head of line blocking across streams. This
change has made it possible for HTTP to support VoIP applications.


# Solution Requirements

The protocol defined here is based on the following requirements:

REQ1: The solution shall not require extensions or modifications to
HTTP3.

REQ2: The solution shall work with both L4 and L7 HTTP load balancers

REQ3: The solution shall work in ways that are compatible with best
practices for load balancers and proxies supporting HTTP3, and not
require any special changes to these load balancers in order to function.

REQ4: The solution shall enable the usage of autoscaling technologies
used in cloud platforms

REQ4: The solution shall provide call reliability in the face of
failures of the server or client

REQ5: The solution shall support built-in migration, allowing a server
to quickly shed load in order to be restarted or upgraded, without any
impact to calls in progress

REQ6: The solution will be easy to interoperate with SIP

REQ7: The solution shall be incrementally deployable - specifically it
must be designed for easy implementation by SBCs and easy deployment
by PSTN termination and origination providers who do not utilize cloud
platforms

REQ8: The solution shall build-in callerID security and protections
from robocalling at the outset

REQ9: The solution shall provide low latency for media

REQ10: The solution shall support only audio, but be extensible to
video or other media in the future

# Design Approaches

To meet the requirements stated above, RIPP makes several fundamental
changes compared to SIP. These changes, and their motivations, are
described in the sections below.

## HBH, not E2E

SIP was designed as an end-to-end protocol. As such, it explicitly
incorporates features which presume the existence of a network of
elements - proxies and registrars in particular. SIP provides many
features to facilitate this - Via headers, record-routing, and so on.

HTTP on the other hand - is strictly a hop-by-hop technology. Though
it does support the notion of proxies (ala the CONNECT method for
reverse proxies), the protocol is fundamentally designed to be between
a client and an authoritative server. What happens beyond that
authoritative server is beyond the scope of HTTP, and can (and often
does) include additional HTTP transactions.

Consequently, in order to reside within HTTP, RIPP follows the same
pattern and only concerns itself with HBH behaviors. Like HTTP, a RIPP
server can of course act as a RIPP client and further connect calls to
downstream elements. However, such behavior requires no additional
specification and is therefore not discussed by RIPP.

## Client-Server, not Agent-to-Agent

SIP is based fundamentally on the User Agent, and describes the
communications between a pair of user agents. Either user agent can
initiate requests towards the other. SIP defines the traditional role
of client and server as bound to a specific transaction.

HTTP does not operate this way. In HTTP, one entity is a client, and
the other is a server. There is no way for the server to send messages
asynchronously towards the client. HTTP3 does enable two distinct
techniques that facilitate server messaging towards the client. But to
use them, RIPP must abide by HTTP3 rules, and that means distinct
roles for clients and servers. Clients must always initiate
connections and send requests, not servers.

To handle this RIPP, specifies that the calling domain implements the
RIPP client, and the domain receiving the calls is the RIPP
server. For any particular call, the roles of client and server do not
change. To facilitate calls in either direction, a domain can
implement both RIPP client and RIPP server roles. However, there is no
relationship between the two directions. 

## Signaling and Media Together

One of the most fundamental design properties of SIP was the
separation of signaling and media. This was fundamental to the success
of SIP, since it enabled high quality, low latency media between
endpoints inside of an enterprise or consumer domain.

This design technique is quite hard to translate to HTTP, especially
when considering load balancing and scaling techniques. HTTP load
balancing is effective because it treats each request/response pair as
an independent action which can route to any number of backends. In
essence, the request/response transaction is atomic, and
consequentially RIPP needs to operate this way as well. 

Though SIP envisioned that signaling and media separation would also apply to
inter-domain calls, in practice this has not happened. Inter-domain
interconnect - used primarily for interconnection with the PSTN - is
done traditionally with SBCs which terminate and re-originate
media. Since this specification is targeted solely at these peering
use cases, RIPP fundamentally combines signaling and media together on
the same connection. To ensure low latency, it uses multiple
independent request/response transactions - each running in parallel
over unique QUIC streams - to transmit media. 


## URIs not IPs

SIP is full of IP addresses and ports. They are contained in Via
headers, in Route and Record-Route headers. In SDP. In Contact
headers. The usage of IPs is one of the main reasons why SIP is so
difficult to deploy into cloud platforms. These platforms are based on
the behavior of HTTP which has been baed on TCP connections and
therefore done most of its routing at the connection layer, and not
the IP layer.

Furthermore, modern cloud platforms are full of NATs and private IP
space, making them inhospitale to SIP based applications which still
struggle with NAT traversal.

HTTP of course does not suffer from this. In general, "addressing", to
the degree it exists at all, is done with HTTP URIs. RIPP follows this
pattern. RIPP - as an application ontop of HTTP3 - does not use or
convey any IP addresses or ports.

## OAuth not MTLS or private IP

When used in peering arrangements today, authentiation for the SIP
connections is typically done using mutual TLS. It is also often the
case that security is done at the IP layer, and sometimes even via
dedicated MPLS connections which requre
pre-proivisioning. Unfortunately, these techniques are quite
incompatible with how modern cloud platforms work.

HTTP - due to its client-server nature, uses asymmetric technicques
for authentication. Most notably, certificate based authentication is
done by the client to verify that it is speaking to the server it
thinks it should be speaking to. For the server to identify the
client, modern platforms make use of OAuth2.0. Though OAuth is not
actually an authentication protocol, the use of OAuth has allowed
authentication to be done out of band via separate login servers which
produce OAuth tokens which can then be used for authentication of the
client.

Consequently, RIPP follows this same approach. For each call, one
domain acts as the client, and the other, as the server. When acting
as a server, the domain authenticates itself with TLS and verifies the
client with OAuth tokens. For calls in the reverse direction, the
roles are reversed.

Consequently, if two domains want to be able to send calls to each
other in either direction, both domains must acquire Oauth tokens
valid for placing calls to the other, and both domains must obtain
traditional web TLS certificates to prove their server identities to
the other.

## TLS1.3 not SRTP or SIPS

SIP has provided encryption of both signaling and media, through the
usage of SIP over TLS and SIPS, and SRTP, respectively. Unfortunately,
these have not been widely deployed. The E2E nature of SRTP has made
keying an ongoing challenge, with multiple technologies developed over
the years. SIP itself has seen greater uptake of TLS transport, but
this remains uncommon largely due to the commonality of private IP
peering as an alternative.

Because of the HBH nature of RIPP, security is done fundamentally at
the connection level - identically to HTTP. Since media is also
carrier over the HTTP connection, both signaling and media are covered
by the connection security provided by HTTP3 - which is TLS1.3.

Because of the mandatory usage of TLS1.3 with HTTP3, and the expected
widespread deployment of HTTP3, running VoIP ontop of HTTP3 will bring
built-in encryption of media and signaling between peering domains,
which is a notable improvement over the current deployment
situation. It is also necessary in order to utilize HTTP3.

Because of this, RIPP does not support SRTP. If a client receives a
SIP call with SRTP, it must terminate the SRTP and decrypt media
before sending it over RIPP. This matches existing practice in any
case. 

E2E media believers - fire away!


## Authenticated CallerID

Robocalling is seeing a dramatic rise in volume, and efforts to combat
it continue. One of the causes of this problem is the ease of which
SIP enables one domain to intiate calls to another domain without
authenticated caller ID.

With RIPP, we remedy this by requiring the client and servers to
implement STIR. Since RIPP is meant for peering between providers (and
not client-to-server connections), STIR is applicable. RIPP clients
must either insert a signed passport, or pass one through if it
exists. Similarly, RIPP servers must act as verifying parties and
reject any calls that omit a passport. 


# Reference Architecture

The RIPP reference architecture is shown in Figure 1.


                                           +------------+ 
                                           |            | 
                                           |  RIPP      | 
                                          >|  Server    | 
                                         / |            | 
                                        /  |            | 
                                       /   +------------+ 
                                      /                   
                                     /                    
                                    /                     
                                   /                      
                   +---------+    /                       
                   |         |   /                        
+------------+     |         |  /          +------------+ 
|            |     |         | /           |            | 
| RIPP       |     |  L4/L7  |/            |  RIPP      | 
| Client     |---->|  LB     | ----------->|  Server    | 
|            |     |         |\            |            | 
|            |     |         | \           |            | 
+------------+     |         |  \          +------------+   
                   +---------+   \                          
                                  \                         
                                   \                        
                                    \                       
                                     \                      
                                      \    +------------+   
                                       \   |            |   
                                        \  |  RIPP      |    
                                         > |  Server    |    
                                           |            |    
                                           |            |    
                                           +------------+

A RIPP client is an HTTP3 client that wishes to initiate a call to a
user in another administrative domain. To do that, it initiates an
HTTP3 connection, which will often (though it is not required to)
terminate on one or more L4 or L7 HTTP load balancers. Using nothing
more than traditional HTTP load balancing techniques, the connection
terminates on one of several RIPP servers that sit behind the load
balancer. 



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

