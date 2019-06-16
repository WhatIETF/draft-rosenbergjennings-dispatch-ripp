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
heavily focused on HTTP based services. Furthemore, RIPP requires
STIR-based secure caller ID, and facilitates easy provisioning.

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
HTTP3. QUIC is based on UDP, and it introduces the concept of a stream
that can be set up with zero RTT. These streams are carried over UDP,
and though are still reliable, there is no head of line blocking
across streams. This change has made it possible for HTTP to support
VoIP applications.


# Solution Requirements

The protocol defined here is based on the following requirements:

REQ1: The solution shall not require extensions or modifications to
HTTP3.

REQ2: The solution shall work with both L4 and L7 HTTP load balancers

REQ3: The solution shall work in ways that are compatible with best
practices for load balancers and proxies supporting HTTP3, and not
require any special changes to these load balancers in order to
function.

REQ4: The solution should hide the number of servers behind the load
balancer, allow the addition or removal of servers from the cluster at
will, and not expose any of this information to the peer

REQ5: The solution shall enable the usage of autoscaling technologies
used in cloud platforms

REQ6: The solution shall provide call reliability in the face of
failures of the server or client

REQ7: The solution shall support built-in migration, allowing a server
to quickly shed load in order to be restarted or upgraded, without any
impact to calls in progress

REQ8: The solution will be easy to interoperate with SIP

REQ9: The solution shall be incrementally deployable - specifically it
must be designed for easy implementation by SBCs and easy deployment
by PSTN termination and origination providers who do not utilize cloud
platforms

REQ10: The solution shall build-in callerID security and protections
from robocalling at the outset

REQ11: The solution shall provide low latency for media

REQ12: The solution shall support only audio, but be extensible to
video or other media in the future

REQ13: The solution must support secure caller ID out of the gate and
not inherit any of the insecure techniques used with SIP


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

To handle this RIPP, specifies that the domain associated with the
caller implements the RIPP client, and the domain receiving the calls
is the RIPP server. For any particular call, the roles of client and
server do not change. To facilitate calls in either direction, a
domain can implement both RIPP client and RIPP server roles. However,
there is no relationship between the two directions.

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
convey any IP addresses or ports. Furthermore, the client never
provides addressing to the server - all traffic is sent in the reverse
direction over the connection. 

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

To make it possible to easily pass calls in both directions, RIPP
allows one domain to act as the customer of another, the provider. The
customer domain authenticates with the provider and obtains an OAuth
token using traditional techniques. RIPP then allows the customer
domain to automatically create a bearer token for inbound calls and
pass it to the provider. 


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

## Calls Separate from Connections

In SIP, there is a fuzzy relationship between calls and
connections. In some cases, connection failures cause call
terminations, and vice a versa.

HTTP, on the otherhand, very clearly separates the state of the
resource being manipulated, with the state of the HTTP connection used
to manipulate it. This design principle is inherited by
RIPP. Consequently, call state on both client and server exist
independently from the connections which manipulate them. This allows
for greater availability my enabling connections for the same call to
move between machines in the case of failures.

## Path Validation, not ICE

HTTP3 is designed to work through NAT as a client-server protocol. It
has built in techniques for dealing with NAT rebindings, IP address
changes due to a client moving between networks (e.g., wifi to
cellular data). It has built in path validation that ensures that HTTP
cannot be used for amplification attacks.

SIP has, over the years, solved these problems to some degree, but not
efficiently nor completely. To work with HTTP, RIPP must utilize the
HTTP approaches for these problems. Consequently, RIPP does not
utilize ICE and has no specific considerations for NAT traversal, as
these are handled by HTTP3 itself.


# Reference Architecture

The RIPP reference architecture is shown in Figure 1.

~~~ ascii-art
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

~~~
                                           
A RIPP client is an HTTP3 client that wishes to initiate a call to a
user in another administrative domain. To do that, it initiates an
HTTP3 connection, which will often (though it is not required to)
terminate on one or more L4 or L7 HTTP load balancers. Using nothing
more than traditional HTTP load balancing techniques, the connection
terminates on one of several RIPP servers that sit behind the load
balancer. 

Because RIPP clients and servers are nothing more than HTTP3
applications, the behavior or RIPP is specified entirey by describing
how various RIPP procedures map to the core HTTP3 primitives available
to applications - opening connections, closing connections, sending
requests and responses, receiving requests and responses, and setting
header fields. That's it.

When two domains wish to exchange calls in both directions, they
implement both the HTTP3 client and server roles. We refer to this as
fluid HTTP - since either domain can act as either client, or server,
depending on the need. Fluid HTTP is shown in Figure 2:

~~~ ascii-art
  Domain A                    Domain B

                 Calls
+-------------+  From      +-------------+
|             |  A to B    |             |
|             |            |             |
|  Client     | +--------> |  Server     |
|             |            |             |
|             |            |             |
+-------------+            +-------------+

                Calls
+-------------+ From       +-------------+
|             | B to A     |             |
|             |            |             |
|  Server     | <--------+ |  Client     |
|             |            |             |
|             |            |             |
+-------------+            +-------------+
~~~


# Terminology

This specification follows the terminology of HTTP3 - specifically:

RIPP Client: The entity that initiates a call, by acting as an HTTP
client.

RIPP Server: The entity that receives a call, by acting as an HTTP
server.

RIPP Connection: An HTTP connection between a RIPP client and RIPP
server.

RIPP Endpoint: Either a RIPP client or RIPP server.

RIPP Peer: An endpoint.  When discussing a particular endpoint, "peer"
refers to the endpoint that is remote to the primary subject of
discussion.

Call: A VoIP session established by a RIPP client for the purposes of
exchanging audio and signaling information.

RIPP Domain: An administrative domain that can implement a RIPP
client, RIPP server, or both, for the purposes of making and receiving
calls. 

Originating Domain: The domain that initiates a call, therefore
acting as an HTTP and RIPP client.

Terminating Domain: The domain that receives a call, therefore acting
as an HTTP and RIPP server.

Customer Domain: A domain that purchases telephony services from
another.

Provider Domain: A domain that sells telephony services to a customer
domain. 

# Overview of Operation

RIPP begins with a provisioning phase, which happens when a customer
domain purchases telephony service from a provider. Using normal OAuth
techniques, the customer authorizes the domain software handling RIPP
to access their provider account on their behalf. The customer domain
will mint a bearer token and push it to the provider domain, along
with other configuration data, enabling authenticated inbound
calls. Consequently, RIPP facilitates one-click provisioning and does
not require any manual configuration of IP, ports or other
information.

Once provisioned, either domain can initiate calls by sending an HTTP
request to the other. Calls are initiating by posting to a URL used to
intiate calls. This request returns a call-specific URL. Either side
can also post a capabilities document to the other side, in advance of
any call. This capabilities document declares the receive capabilities
of that domain. Defaults are defined for each capability, in case a
document has not been posted. These documents are cached and apply to
all future calls. 

Once a call has been created, a long-lived HTTP transaction is
initiated from the client to the server for purposes of
signaling. This transaction enables bidirectional data flow, tunneled
within the body of a long-running HTTP request and response. This data
flow is called a byway. A separate byway is established by the client
for signaling, one for media control, and multiple byways for
media. HTTP3 ensures zero RTT for setup of these byways.

Signaling commands are encoded into the signaling byway using
streaming JSON in both direcitons. The media control and media byways
carry a simple binary encoding in both directions. 

To eliminate HOL blocking for media, a media packet is sent on a media
byway when it is first established. After the first packet, the client
cannot be sure a subsequent packet will be delayed due to the ordering
guarantees provided by HTTP3 within a stream. To combat this, both
sides acknowledge the receipt of each packet using the media control
byway. Once a media packet is acknowledged, the media byway can be
used once again without fear of HOL blocking.

Finally, RIPP provides a simple technique for allowing a call to
seamlessly migrate from one client instance to another on a different
host, or from one server instance on one host to another. For a
client, it need only end the byways in use for the call and
re-initiate from a different instance. Similarly, a server can request
migration, and this triggers the client to perform this same
action. The call state persists independently of the state of the HTTP
connection or the byways embedded in HTTP transactions, so that a
reconnect can continue where things left off.


# Detailed Behaviors

This section provides an overview of the operation of RIPP.

## Discovery and Provisioning

RIPP does not provide any technique for discovery. It is assumed that
peering is arranged bilaterally through some out of bands means. For
example, a RIPP domain can offer a web site through which customers
can order termination services. This website can provide the RIPP
client domain with the information needed to inject calls into that
domain. For bidirectional peering arrangements, each side would need
to perform this function independently. 

Automated techniques for provisioning bidirecitonal peering
relationships are beyond the scope of this specification.

Two pieces - and only two pieces of information - are required for a
client domain to initiate calls to a server domain:

1. The root URI for placing calls,
2. A valid OAuth token

It is RECOMMENDED that these be provided via a website operated by the
terminating domain. This also means the process of authentication of
the originating domain to the terminating domai is fully outside the
scope of this spceification, and can follow any desired technique by
the terminating domain that ultimately results in the issuance of an
OAuth token. 

The root URI MUST be a valid HTTPS URI. The terminating domain MUST be
compliant with HTTP3 in processing requests. The root URI MAY contain
a path component, though this is optional.

All requests to create a new call are initiated by the client towards
this URI.

As an example, the following is a valid RIPP root URI:

https://telco.com/calls


## Initiating Calls

To initiate a new call, a client initiates a connection to the root
URI for the domain to which it wishes to place the call. This MUST be
an HTTP3 request, and MUST be made to an HTTPS URI. If the client
already has a connection open to the server, it MAY reuse that
connection. It is RECOMMENDED that clients keep their connections open
to the server, in order to speed up call setup delays. Furthermore, it
is RECOMMENDED that the underlying HTTP client implementation make use
of 0-RTT connections to further improve call setup times in cases
where the HTTP connection has been dropped.

To place the call, the RIPP client MUST initiate a POST request to
this URI. It MUST append the root URI with the attribute
"newcall". For example:

POST https://telco.com/calls?newcall

This request MUST contain the OAuth token that the client has
obtained out-of-band.

The server will validate the OAuth token, authorize the creation of a
new call, and then either accept or reject the request. If accepted,
it indicates that the server is willing to create this call. The
server MUST return a 201 Created response, and MUST include a Location
header field containing an HTTPS URI which identifies the call that
has been created. The URI identifying the call MUST include a path
segment which contains a type 4 UUID, ensuring that call identifiers
are unique across time and space. 

An example URI that identifies a call is:

https://telco.com/calls/id/ha8d7f6fso29s88clzopapie8x8c

The server MAY include an HTTP session cookie in the 201 response. 

The usage of an HTTP URI to identify the call itself, combined with
session cookies,  gives the terminating RIPP domain a great deal of
flexibility in how it manages state for the call. In traditional
softswitch designs, call and media state is held in-memory in the
server and not placed into databases. In such a design, a RIPP server
can use the session cookie in combination with sticky session routing
in the load balancers to ensure that subsequent requests for the same
call go to the same call server. Alternatively, if the server is not
using any kind of HTTP load balancer at all, it can use a specific
hostname in the URI to route all requests for this call to a specific
instance of the server. This technique is particularly useful for
telcos who have not deployed HTTP infrastructure, but do have
SBCs. The root URI can use a domain whose A records identify all of
the perimeter SBCs. Once a call has landed on a particular SBC, the
call URI can indicate the specific hostname of the SBC.

For example, the root URI for such a telco operator might be:

https://sbc-farm.telco.com/calls

and the call URIs could be of the form:

https://sbc-host-{instance-number}.sbc-farm.telco.com/calls/id/{UUID}

However, the HTTP URI for the call MUST NOT contain an IP address; it
MUST utilize a valid host or domain name. This is to ensure that TLS
certificate validation functions properly without manual
configuration of certificates (a practice which is required still for
SIP based peering).

Neither the request, nor the response, contain bodies.

FFS: Inclusion of bodies in requests and responses for signaling
capabilities? 


## Establishing the Signaling and Media Transactions

To perform signaling and to exchange media for this call, once the
client has the call URI, it simultaneously creates a set of new
request transactions towards the call URI. These are called signaling
transactions and media transactions respectively.

Both the media and signaling transactions are long running. This means
that the client initiates the connections, sends the headers, and then
sends the body as a long-running stream (e.g., streaming
requests). ((TODO: must confirm that this works with http3 servers -
it seems ok according to the specs though)). Similarly, the server
receives the request, and if it accepts the request, immediately
generates a 200 response and begins streaming the response body back
towards the client. This has the property of creating a bidirectional
data stream between the client, and the server. RIPP specific
information is carried in that data stream.

The client SHOULD open a single signaling transaction, and SHOULD open
at least 10 ((FFS: what is the right number and how to negotiate
proper ranges of values)) media transactions. The use of multiple
media transactions is essential to low latency operation of RIPP. This
is because, as describe below, media packets are sprayed across these
transactions in order to ensure that there is never head-of-line
blocking. This is possible because, in HTTP3, each transaction is
carried over a separate QUIC stream, and QUIC streams run ontop of
UDP. ((FFS: is there some configuration required to make sure that
QUIC dosnt multiplex data from different streams into the same UDP
packet?? This wont cause HOL blocking but will cause amplification of
packet loss))

The state of the connection is separate from the state of the
call. The client MAY terminate the connection at any time, and
re-establish it. Similarly, the server or cient may end the signaling
or media transactions, and restart them too. RIPP provides identifiers
and sequencing at the application layer in order to facilitate this
process. This process is an essential part of this specification, due
to the high likelihood that streams, connections, and servers fail at
some point during a call. This is described in more detail below.

To initiate a signaling transaction, the client MUST initiate a POST
request to the call URI, and MUST include the signaling URI
parameter. To initiate a media transaction, it MUST include the media
URI parameter. These requests MUST NOT include the newcall URI
parameter. A client MUST NOT include both the media and signaling
parameters in a request. This is because media and signaling utilize
different framing within the data stream and cannot be multiplexed.

The requests to create these transactions MUST include headers for any
applicable session cookies.

When opening a media transaction, the client MUST include a RIPP-Media
header field in the request headers. Simiarly, the server MUST include
this header in the response headers. This header contains a channel
number, the name of the codec used in the stream, and a timestamp
conveying the wall clock time corresponding to the time at which the
media packets in that stream were received or generated by the
client. The timestamp also includes timestamps received from any
upstream servers, providing an e2e timing trace for the media
path. ((TODO: need to fill in details)).

RIPP supports multiple channels, meant for handling stereo
audio. Each channel MUST be its own media transaction. Channel number
zero is reserved for the media command channel. The media command
channel - unlike the media channels - requires reliability, and thus
media frames on this channel are never acknowledged. Indeed, the
primary purpose of the media command channel is to convey
acknowledgements for media packets. The client MUST open at least one
media transaction on channel 0. 


((FFS: any other headers we need to talk
about??))


## Terminating and Re-establishing Media and Signaling Transactions

The originating domain MUST ensure that there is always at least one
signaling connection, and at least 10 media conncetions between the
originating domain and the call URI, for a specific call. As such, if
a transaction ends or the connection breaks or is migrated, the client
MUST re-initiate these transactions immediately, or risk loss of media
and signaling events. However, to deal with the fact that
re-establishment takes time, both client and server MUST buffer their
signaling and media streams for at least 5 seconds, and then once the
connections and streams are re-established, it sends all buffered data
immediately.

Note that it is the sole responsibility of the client to make sure
these connections are re-established if they fail unexpectedly. 

These rules result in the creation of at least one bidirectional byte
stream between originating and terminating server to be used for
signaling, and at least ten bidirectional byte streams for media.


## Media Negotiation

There is no offer-answer model. Only two codecs are supported - G711
and Opus. All entities must support both. Without the need to signal
media destinations - IP and ports - there is no longer a need for
SDP. Either side can modify codecs at will, without signaling. They
can also adjust frame sizes within a range defined by this
specification. There is no SRTP, as described above.

Future extensions will consider the addition of a declarative model,
where each side can send settings which are then cached and span
across multiple calls, in much the same way it works with HTTP/3
itself.

## Framing

Both signaling and media are carried over a bidirectional byte stream
that is established by the client. Signaling uses self-delineating
text frames. This is done to enable end users to initiate signaling
easily from command line applications like curl, and through
interactive developer portals. Media is sent using a simple binary
framing, similar to - but not identical to - RTP.

### Signaling Framing

Signaling is carried as a series of valid JSON objects. If there is
more than one object to be sent over a transaction, the JSON objects
are separated by a visual separator consistenting of ten contiguous
instances of the ascii dash "-", followed by a CRLF. As a result, the
JSON itself MUST NOT ever contain more than ten dashes in a row. Since
the JSON is extensible, future extensions MUST NOT ever specify new
fields which contain 10 or more dashes.

The usage of the dashes allows the receiving client to extract
independent objects from the stream without performing JSON parsing or
validation. ((TODO: should we limit the size of an individual JSON
object?))

HTTP compression is used to reduce the on-the-wire penalty for using
JSON. Since this is transparent, it enables an easy developer
interface to RIPP without the penalty of text encoding. ((TODO:
specify more details on how this works - assumes that HTTP does in
fact do payload compression vs. requiring the application to do it??))

### Media Framing

Media is carried as a series of binary objects. These binary objects
contain a 7 bit payload type value (mirroring RTP), a 32 bit sequence
number (twice as large as RTP), and a single bit for reserved. This is
followed by a variable length length field that describes the length
of the data which follows, in bytes. The data which follows is the
codec frame. The minimum length for the length
field is 8 bits. This means the framing has a minimum size of 6 bytes,
significantly smaller than the RTP minimum of 12 bytes. Consequently,
RIPP is more bandwidth efficient than RTP when used with long running
transactions.

Because there is no separate timestamp, RIPP does not permit the use
of non-exitent frames to convey silence. The encoder used by the
client MUST emit a contiuous series of frames based on its sending
clock. If there is a desire to use lower bandwidth during silence
periods, the encode must transcode to Opus (which is more efficient
during silence periods), or else fill in the time gap with comfort
noise using RFC3389, whose support is required by this
specification. See details below on usage of RFC3389 with RIPP.

The sequence number space is unique for each direction, and unique for
each call (as identified by the call URI). Each side MUST start the
sequence number at zero, and MUST inccrement it by one for each
subsequent media frame. With 32 bits of sequence space, starting at
zero, with a minimum frame size of 10ms, RIPP can support call
durations as long as 11,930 hours. Rollover of the sequence number is
not permitted, the client or server MUST end the call before
rollover. This means that the combination of call URI, direction
(client to server, or server to client), channel number, and sequence
number represent a unique identifier in space and time for media packets. 

## Signaling - Events

Signaling is performed by having the client and server exchange
events. Each event is a JSON object embedded in the signaling
stream, which conveys the event as perceived by the client or
server. Each event has a sequence number, which starts at zero for a
call, and increases by one for each event. The sequence number space
is unique in each direction. The event also contains a direction
field, which indicates whether the event was sent from client to
server, or server to client. It also contains a timestamp field, which
indicates the time of the event as perceived by the sender. This
timestamp is not updated when retransmissions happen; the timestamp
exists at the RIPP application layer and RIPP cannot directly observe
HTTP retransmits.

It also contains a call field, which contains the URI of the call in
question. 

Finally, there is an event type field, which conveys the type of
event. This is followed by additional fields which are specific to the
event type.

This structure means that each event carried in the signaling is
totally self-describing, irregardless of the enclosing connection and
stream. This greatly facilitates logging, debugging, retransmissions,
retries, and other race conditions which may deliver the same event
multiple times, or deliver an event to a server which is not aware of
the call.

This specification defines the following events:

start: Passed from client to server, it tells the server to begin
processing of the specific call. This event is the first event
delivered to the call URI by the client.

started: Passed from server to client, confirming that the call is now
in the start state as far as it is concerned.

alerting: Passed from server to client, indicating that the recipint
is alerting.

accepted: Passed from server to client, indicating that the call was
accepted.

rejected: Passed from server to client, indicating that the call was
rejected by the user.

failed: Passed from server to client, indicating that the call was
rejected by server or downstream servers, not by the user, but due to
some kind of error condition. This event contains a response code and
reason phrase, which are identical to the response codes and reason
phrases in SIP.

noanswer: Passed from server to client, indicating that the call was
delivered to the receiving user but was not answered, and the server
or a downstream server timed out the call.

end: initiated by either client or server, it indicates that the call
is to be terminated. Note that this does NOT delete the HTTP resource,
it merely changes its state to call end. Furthermore, a call cannot be
ended with a DELETE against the call URI; DELETE is not permitted and
MUST be rejected by the server.

migrate: sent from server to client, it instructs the client to
terminate the connections and restablish them to a new URI which
replaces the URI for the call. The event contains the new URI to use.


## Signaling State Machine

### Client

The call begins in the CREATED state. This state is entered the moment
the cient receives the 201 response from the server with the call
URI. That creates an instance of the state machine associated with
that URI.

The states are:

CREATED
STARTING
PENDING
ALERTING
ANSWERED
TERMINATED

When in the CREATED state, when the client sends a start event on the
signaling transaction, it transitions to the STARTING state. Once in
the starting state, it MUST open 10 media connections. Once it has
opened these connections and also receive a started event from the
server, it transitions to the PENDING state. The receipt of an
alerting event moves it to the ALERTING state. From ALERTING, receipt
of an answered event moves it to the ANSWERED state. Receipt of a
noanwer or failed moves it to the terminated state. From any state,
receipt or transmission of an end event moves it to the terminated
event.

A migrate event does not change the state of the call; it merely
causes the client to re-initiate the connection to the new URI.


### Server

TODO - mirrors the client. 

## Media

((TODO: this is rambling, need to split it up - introduce channels,
command channel, relationships between all of these things,
description of the ack mechanism as multi-hop for latency
troubleshooting.))

THe approach for media is media striping. Once call is in the STARTING
state, the client opens N (N=10 maybe? 20?) streams using N requests,
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
packet loss tolerance. ((TODO: Need some math here.))

RIPP media acknowledgement packets MUST be sent on channel zero. Like
media packets, media acknowledgement packets have a sequence number, a
payload type, and a reserved it. The mapping of payload types to
object structure is conveyed in the Media headers upon opening of the
transaction. Media ackowledgement packets follow a simple format. They
contain the sequence number and channel number of the media packet
being acknowledged, and the timestamp at which that media packet was
received by the endpoint, and a flag indicating whether the endpoint
dropped the media packet or sent it onwards.

This protocol also supports conveyance of ack messages that indicate
packet disposition at downstream and upstream endpoints. If a RIPP
server acts as a RIPP client, and sends a packet to the next-hop RIPP
server, the RIPP client will receive an acknowledgement for that
packet. Once received, it adds a hop counter (in this case, a hop
count of 1) and passes the ACK upstream. In addition, if the RIPP
client receives an ACK with a hop count greater than 0, it increments
the hop count and passes it upstream.

For this to be effective, RIPP servers acting as clients MUST NOT
perform sequence renumbering.

A RIPP endpoint that receives a media packet on a stream will not know
whether this packet had been retransmitted or not. However, it can
compute the time of transmission of the media packet, as the timestamp
of the start of the transaction, times the difference between the
first and most recent sequence numbers, times the framing for the
codec. ((TODO: hmm this means we need fixed framing if we want to
avoid adding timestamps)). With this information it can compute the
one way hop delay, accurate to within the clock delta between the
sender and receiver. Based on these, it can can determine whether the
incremental hop delay is small enough to merit continued transmission
of the media packet.


After a client sends the headers for a media transaction, it MAY
immediately send a single media packet. AFter that, it MUST mark the
transaction as blocked. Once it receives an acknowledgement that the
packet was received, it MUST mark the transaction as unblocked. A
server behaves similarly, once it has received the request headers and
sent its response headers, it MAY immediately send a single media
packet, and then it MUST mark the transaction as blocked. Once it
receives an acknowledgement that the packet was received, it MUST mark
the transaction as unblocked. An endpoint SHOULD NOT send a media
packet on a blocked connection.

IF a client reaches 75% of its media transactions as in the blocked
state, it MUST begin opening new media transactions to ensure that
media can continue to flow uninterrupted. A server cannot open new
connections. However, if the server has marked 75% of the connections
as blocked, it MUST send a command on the media command channel
instructing the client to open another connection. Once this command
is received, the client MUST open a new connection.

A client MAY terminate media transactions gracefully if they have not
sent or received packets on that connection for 5 or more
seconds. This is to clean up unused transactions.

There is no need for sender or receiver reports. The equivalent
information is knowable from the application layer acks.  

## Call Termination

Signaling allows an application layer call end to be sent. This will
also cause each side to termiante the request and media streams with
end flags per HTTP3 specs. However, the opposite is not true - ending
of the transactions or connection does not impact the call state.

A server MUST maintain a timer, with a value equal to 5 seconds, for
which it will hold the call in its current state without any active
signaling transaction. If the server does not receive a signaling
transaction before the expiration of this timer, it MUST consider the
call as ended and transition its state to TERMINATED.

If the server receives a signaling or media connection for a call that
is in the TERMINATED, it MUST reject the transaction with an XX
response code.

Note that the call resource itself - the URI - still exists. POST
transactions for signaling and media are not permitted against it once
the call is in an ended state. However, a server MUST maintain the
resource for at least one day, to facilitate a GET request against
it. As described below, a GET request against a call resource allows
the client to catch up with the state of the call, facilitating
stateless migration of clients.

## GET Transactions

A client MAY initiate a GET request against the call URI at any
time. This returns the current state of the resource. This request
returns an objet which is the concatenation of all call events, sent
by the server and received by the server, in the order in whch the
server applied them to the state machine.

The response also contains a summary of media packet statistics up to
that point ((TODO: specify)). 

## Graceful Call Migration: Server

To facilitate operational maintenance, the protocol has built in
support for allowing a server instance to drain all active calls to
another server instance.

The server can issue a migrate event over the signaling channel,
which includes a new call URI that the peer should use. Once received,
the client closes all transactions to the current call URI. It then
establishes new signaling transactions to the URI it just received,
and in parallel re-establishes media transactions. All media received
during the migration phase is buffered to ensure there is no packet
loss (though there will be jitter) during the migration period.

If the server receives a GET request to the old call URI, it MUST
return a 3xx response redirecting to the new call URI.

We dont use QUIC layer connection migration, as that is triggered by
network changes and not likely to be exposed to applications.

## Graceful Call Migration: Client

Clients can move a call from one client instance to another easily. No
commands are required. The client simply ends the in-progress
transactions for signaling and media, and then reinitiates them to the
existing call URI from whatever server is to take over. Note that the
client MUST do this within 5s or the server will end the call. 

## Ungraceful Call Migration

Since all media packets are acknowledged at the application layer, it
is possible for endpoints to very quickly detect remote failures,
network failures, and other related problems.

Failure detection falls entirely at the hands of the client. A failure
situation is detected when any one of the following happens:

1. The QUIC connection closss unexpectedly
2. Any outstanding signaling or media transactions are reset by the
peer
3. No media packets are received from the peer for 5s
4. No acknowledgements are received for packets that have been sent in
the last 5s

If the client detects such a failure, it MUST abort all ongoing
transactions to the server, terminate the QUIC connection, and then
establish a new connection using 0-RTT, and re-establish signaling and
media transactions.

TOOD: need to specify back-off timers and retry algorithms


# Detailed Protocol Semantics

To be filled in.

# Syntx

To be filled in.


# SIP to RIPP Gatewaying


# RIPP to SIP Gatewaying

# IANA Considerations

# Security Considerations

# Acknowledgements


{backmatter}

