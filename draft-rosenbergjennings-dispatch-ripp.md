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
docName = "draft-rosenbergjennings-dispatch-ripp-04"
ipr= "trust200902"
area = "Internet"
keyword = ["RTP"]

[pi]
symrefs = "yes"
sortrefs = "yes"

[[author]]
initials = "J."
surname = "Rosenberg"
fullname = "Jonathan Rosenberg"
organization = "Five9"
  [author.address]
  email = "jdrosen@jdrosen.net"

[[author]]
initials = "C."
surname = "Jennings"
fullname = "Cullen Jennings"
organization = "Cisco Systems"
  [author.address]
  email = "fluffy@iii.ca"

[[author]] 
initials = "A." 
surname = "Minessale" 
fullname = "Anthony Minessale" 
organization = "Signalwire/Freeswitch"
  [author.address]
  email = "anthm@signalwire.com"

[[author]] 
initials = "J." 
surname = "Livingood" 
fullname = "Jason Livingood" 
organization = "Comcast"
  [author.address]
  email = "jason_livingood@comcast.com"

[[author]] 
initials = "J." 
surname = "Uberti" 
fullname = "Justin Uberti" 
organization = "Google"
  [author.address]
  email = "justin@uberti.name"
 

%%%

.# Abstract

This document specifies the Realtime Internet Peering Protocol
(RIPP). RIPP is used to provide peering of voice and video
communications between administrative domains. These include a
traditional voice trunking provider (such as a telco), and a trunking
consumer (such as an enterprise PBX or contact center), or between a
video conferencing endpoint deployed in an enterprise, and a video
conferencing SaaS service. RIPP is an alternative to SIP, SDP and RTP
for these use cases, and is designed as a web application using
HTTP/3. Using HTTP/3 allows implementors to build their applications
on top of cloud platforms, such as AWS, Azure and Google Cloud, all of
which are heavily focused on HTTP based services. RIPP also addresses
many of the challenges of traditional SIP-based peering. It supports
modern techniques for load balancing, autoscaling, call-preserving
failover, graceful call migrations, security by default, STIR-based
caller ID, provisioning, and capabilities - all of which have been
challenges with traditional SIP peering and voice trunking. Since it
runs over HTTP/3, it works through NATs and firewalls with the same
ease as HTTP does.

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
these techniques can work for VoIP, they are deployed in conjunction
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
cloud platforms which require interconnection with other
administrative domains providing real-time voice and video
services. One example is interconnection with the public switched
telephone network (PSTN). Examples of such applications include cloud
PBXs, cloud contact centers, cloud meetings applications, and so
on. Furthermore, commerce websites would like to allow customers
to call into the telephone network for customer support.

In order for these applications to connect to the PSTN, or to connect
voice and video services in other domains, they typically
deploy Session Initiation Protocol (SIP) [@RFC3261] based servers -
SBCs, SIP proxies, and softswitches, to provide this
interconnection. Unfortunately, SIP based applications cannot make use
of the many capabilities these cloud platforms afford to HTTP based
applications. These SIP servers are usually deployed on bare metal or
VMs at best. Application developers must build their own load
balancing, HA, failover, clustering, security, and scaling
technologies, rather than using the capabilities of these platforms.

Another problem has been call drops. SIP's original design where call
state lived only in the endpoints and media was sent p2p - provided
extremely high reliability. In practice, SIP networks are full of
state that resides in server intermediaries (softswitches, SBCs, and
so on), and has seen media transmitted through these
intermediaries. Unfortunately, the SIP protocol did not provide
built-in mechanisms which enable call preservation - the ability of a
call to survive failure of any server component without call drops. As
a result, many of these servers rely on layer 3 solutions (such as
shared VIPs with proprietary state replication), which are expensive,
hard to deploy, and of limited scale. In other cases, they are absent,
in which case a server failure will cause all calls to be dropped,
requiring the end user themselves to re-initiate the call.

The statefulness of most server components has also meant that
software upgrade is a manual process. To avoid dropped calls, it must
be performed late at night, causing a risk of downtime. Other
implementations have waited for calls to drain, and then performed
automated restarts. This almost always requires a timeout (typically
an hour or more) at which point calls longer than that get
dropped. The result is that rolling software upgrades have caused some
amount of call drops, and can take an extremely long time to propagate
through a cluster. This was acceptable perhaps in the era of
traditional client-server applications where software upgrades were
infrequent. Modern software systems perform updates many times a day,
which is incompatible with SIP-based systems. 

All of this has created a barrier to entry, particularly for
applications such as websites which are not expert in VoIP
technologies. Furthermore, it has meant that VoIP applications have
been unable to take advantage of the many technology improvements that
have come to networking and protocol design since the publication of
RFC 3261 in 2002.

In addition, SIP trunking has suffered from complex provisioning
operations, oftentimes requiring the exchange of static IPs and
ports. These operations are almost never self-service and
consequently, SIP trunk turn ups can take weeks.

Finally, perhaps the biggest challenge with SIP trunking has been its
abuse for injecting robocalls, and in general weak deployment of
security. 

In summary - there are four core problems which this specification is
addressing in the traditional usage of SIP peering between entities:

1. The difficulty of deploying real-time communications servers into
web-centric cloud platforms, which can enable modern solutions for
load balancing, infinite scale, autoscaling, hitless software upgrade,
and so on. 

2. Lack of built-in protocol mechanisms for call preservation,
scaling, software upgrade, and so on.

3. Lack of standardized and automated techniques for provisioning and
configuration of SIP trunks

4. Lack of secure caller ID


## Core Concept

The core concept of RIPP is simple - to make voice and video peering
yet another application that sits on top of HTTP.

Though SIP was inspired by HTTP, it is not HTTP itself. SIP and HTTP
are peers - application protocols running ontop of the Internet. In the
intervening years, HTTP evolved to become a general purpose substrate
for delivering Internet applications. It is fair to say that today,
almost all applications users consume over the Internet run over
HTTP (with obvious exception of inter-server email - much client to
server email is also now run over HTTP).

This resulted - in essence - a rift between telecommunications
technologies and web technologies. Both had their own protocol stacks,
their own sets of products and services, and so on.

RIPP is an attempt to seal this rift by reunifying web and
telecommunications technologies, with web as the "winner".

The idea of re-converging HTTP and SIP is certainly not new, and indeed
has been discussed in the hallways of IETF for many years. However,
several significant limitations made this previously infeasible:

1. HTTP utilized TCP, which meant that it created head-of-line
blocking which would delay lost packets rather than just discard
them. This will often provide intolerable latency for VoIP.

2. HTTP was request response, allowing the client to send requests and
receive a response. There as no way for a server to asynchronously
send information to the client in an easy fashion.


HTTP2 [@RFC7540] addressed the second of these with the introduction of pushes
and long running requests. However, its usage of TCP was still a
problem. This has finally been addressed with the arrival of QUIC
[@I-D.ietf-quic-transport] and
HTTP/3. QUIC is based on UDP, and it introduces the concept of a stream
that can be set up with zero RTT. These streams are carried over UDP,
and though are still reliable, there is no head of line blocking
across streams. This change has made it possible for HTTP to support
real-time applications.

This specification makes an assumption that
[@I-D.ietf-quic-transport] will be widely implemented and deployed as
a mainstream part of web-based software systems, but any extensions
unique to the needs of VoIP will struggle to see widespread deployment.
As a result, RIPP uses HTTP/3 [@I-D.ietf-quic-http], but is not an
extension to it. This means that RIPP inherits the benefits of
classic HTTP deployments - easy load balancing, easy expansion and
contraction of clusters (including auto-scaling), standard techniques
for encryption, authentication, and denial-of-service prevention, and
so on.

# Structure of this Document

The document is broadly split into two parts - explanatory and
normative materials. The explanatory text is non-normative, and
contains no [@RFC2119] language. Much of this text is meant to help
readers familiar with SIP, understand how SIP concepts translate (or
don't) into RIPP. These sections include Requirements (#req), Design
Approaches (#design), Terminology (#terminology), Reference
Architecture (#refarch), Deployment Examples (#deployments). The
remainder of the document specifies normative procedures.



# Solution Requirements {#req}

The protocol defined here is based on the following requirements: 

REQ1: The solution shall not require extensions or modifications to
HTTP/3.

REQ2: The solution shall work with both L4 and L7 HTTP load balancers

REQ3: The solution shall work in ways that are compatible with best
practices for load balancers and proxies supporting HTTP/3, and not
require any special changes to these load balancers in order to
function.

REQ4: The solution should hide the number of servers behind the load
balancer, allow the addition or removal of servers from the cluster at
will, and not expose any of this information to the peer

REQ5: The solution shall enable the usage of autoscaling technologies
used in cloud platforms, without any special consideration for RIPP -
its just a web app

REQ6: The solution shall provide call preservation in the face of
failures of the server or client. It is acceptable for a brief blip of
media due to transient packet loss, but thats it

REQ7: The solution shall support built-in migration, allowing a server
to quickly shed load in order to be restarted or upgraded, without any
impact to calls in progress

REQ8: The solution will be easy to interoperate with SIP

REQ9: The solution shall be incrementally deployable - specifically it
must be designed for easy implementation by SBCs and easy deployment
by PSTN termination and origination providers who do not utilize cloud
platforms

REQ10: The solution shall require authentication and encryption, with
no opportunity to disable them. Furthermore, it will require secure
callerID, with no provision for insecure callerID

REQ11: The solution shall provide low latency for media

REQ12: The solution shall support audio and video

REQ13: The solution must support secure caller ID out of the gate and
not inherit any of the insecure techniques used with SIP

REQ14: The solution shall include mandatory-to-implement provisioning
operations for cases where there is a customer-provider relationship

REQ15: The solution shall make it possible to perform rolling upgrades
through a cluster many times a day, without call drops 


# Design Approaches {#design}

To meet the requirements stated above, RIPP makes several fundamental
changes compared to SIP. These changes, and their motivations, are
described in the sections below.

## Client-Server, not Multi-Element

SIP was designed as a complete system architecture. As such, it explicitly
incorporates features which presume the existence of a network of
elements - proxies and registrars in particular. SIP provides many
features to facilitate this - Via headers, record-routing, and so on.

HTTP on the other hand - is strictly a client-to-server technology. Though
it does support the notion of proxies (ala the CONNECT method for
reverse proxies), the protocol is fundamentally designed to be between
a client and an authoritative server. What happens beyond that
authoritative server is beyond the scope of HTTP, and can (and often
does) include additional HTTP transactions.

Consequently, in order to reside within HTTP, RIPP follows the same
pattern and only concerns itself with client-server behaviours. Like
HTTP, a RIPP server can of course act as a RIPP client and further
connect calls to downstream elements. However, such behavior requires
no additional specification and is therefore not discussed by RIPP.

## Client-Server, not Agent-to-Agent

SIP is based fundamentally on the User Agent, and describes the
communications between a pair of user agents. Either user agent can
initiate requests towards the other. SIP defines the traditional role
of client and server as bound to a specific transaction.

HTTP does not operate this way. In HTTP, one entity is a client, and
the other is a server. There is no way for the server to send messages
asynchronously towards the client. HTTP/3 does enable two distinct
techniques that facilitate server messaging towards the client. But to
use them, RIPP must abide by HTTP/3 rules, and that means distinct
roles for clients and servers. Clients must always initiate
connections and send requests, not servers.

To handle this, RIPP specifies that the domain associated with the
caller implements the RIPP client, and the domain receiving the calls
is the RIPP server. For any particular call, the roles of client and
server do not change. To facilitate calls in either direction, a
domain can implement both RIPP client and RIPP server roles. However,
there is no relationship between the two directions. 

## Signaling and Media Together

One of the most fundamental design properties of SIP was the
separation of signalling and media. This was fundamental to the success
of SIP, since it enabled high quality, low latency media between
endpoints inside of an enterprise or consumer domain.

This design technique is quite hard to translate to HTTP, especially
when considering load balancing and scaling techniques. HTTP load
balancing is effective because it treats each request/response pair as
an independent action which can route to any number of backends. In
essence, the request/response transaction is atomic, and
consequentially RIPP needs to operate this way as well. 

Though SIP envisioned that signalling and media separation would also
apply to inter-domain calls, in practice this has not
happened. Inter-domain interconnect - including interconnection with
the PSTN - is done traditionally with SBCs which terminate and
re-originate media. Since this specification is targeted at
inter-domain peering cases, RIPP fundamentally combines signalling and
media together on the same connection. To ensure low latency, it uses
multiple independent request/response transactions - each running in
parallel over unique HTTP transactions (and thus unique QUIC streams)
- to transmit media.


## URIs not IPs

SIP is full of IP addresses and ports. They are contained in Via
headers, in Route and Record-Route headers. In SDP. In Contact
headers. The usage of IPs is one of the main reasons why SIP is so
difficult to deploy into cloud platforms. These platforms are based on
the behavior of HTTP which has been based on TCP connections and
therefore done most of its routing at the connection layer, and not
the IP layer.

Furthermore, modern cloud platforms are full of NATs and private IP
space, making them inhospitable to SIP based applications which still
struggle with NAT traversal.

HTTP of course does not suffer from this. In general, "addressing", to
the degree it exists at all, is done with HTTP URIs. RIPP follows this
pattern. RIPP - as a web application that uses HTTP/3 - does not use or
convey any IP addresses or ports. Furthermore, the client never
provides addressing to the server - all traffic is sent in the reverse
direction over the connection. 

## OAuth not MTLS or private IP

When used in peering arrangements today, authentication for the SIP
connections is typically done using mutual TLS. It is also often the
case that security is done at the IP layer, and sometimes even via
dedicated MPLS connections which require
pre-provisioning. Unfortunately, these techniques are quite
incompatible with how modern cloud platforms work.

HTTP - due to its client-server nature, uses asymmetric techniques
for authentication. Most notably, certificate based authentication is
done by the client to verify that it is speaking to the server it
thinks it should be speaking to. For the server to identify the
client, modern platforms make use of OAuth2.0. Though OAuth is not
actually an authentication protocol, the use of OAuth has allowed
authentication to be done out of band via separate identity servers which
produce OAuth tokens which can then be used for authentication of the
client.

Consequently, RIPP follows this same approach. The client initiates
calls towards the server. The server uses TLS to provide its identity
to the client, and the client provides a token to the server to
identify itself, with a login technique occuring elsewhere. To
facilitate bidirectional calls, an entity would just implement both
the server and client roles. For any one call, the entity placing the
call acts as the client, and the one receiving it, as the server. To
handle the common case where there is an asymmetric business
relationship (one entity being a customer of the other), RIPP
facilitates a simple provisioning process by which the customer can
use an OAuth token to provision credentials for usage in the reverse
direction. 

This specification also envisions a simple extension which would allow
single-device clients to receive inbound calls from the server - however, such
an extension is outside the scope of this document.

## TLS not SRTP or SIPS

SIP has provided encryption of both signalling and media, through the
usage of SIP over TLS and SIPS, and SRTP, respectively. Unfortunately,
these have not been widely deployed. The E2E nature of SRTP has made
keying an ongoing challenge, with multiple technologies developed over
the years. SIP itself has seen greater uptake of TLS transport, but
this remains uncommon largely due to the commonality of private IP
peering as an alternative.

Because of the HBH nature of RIPP, security is done fundamentally at
the connection level - identically to HTTP. Since media is also
carrier over the HTTP connection, both signalling and media are covered
by the connection security provided by HTTP/3.

Because of the mandatory usage of TLS1.3 with HTTP/3, and the expected
widespread deployment of HTTP/3, running VoIP on top of HTTP/3 will bring
built-in encryption of media and signalling between peering domains,
which is a notable improvement over the current deployment
situation. It is also necessary in order to utilize HTTP/3.

For reasons of interoperability, and to enable e2e media encryption in several
inter-domain use cases, RIPP assumes each media chunk may be
encrypted, and if so, it contains a key ID which dereferences the
encryption keys, ciphers and other information needed to decrypt the
packet. The exchange of these keys and ciphers is done entirely out of
band of RIPP. 

However, RIPP does not support SRTP. If a client receives a
SIP call with SRTP, it must terminate the SRTP and decrypt media
before sending it over RIPP. This matches existing practice in many
cases. 

## Authenticated CallerID

Robocalling is seeing a dramatic rise in volume, and efforts to combat
it continue. One of the causes of this problem is the ease of which
SIP enables one domain to initiate calls to another domain without
authenticated caller ID.

With RIPP, we remedy this by requiring the client and servers to
implement STIR. RIPP clients must either insert a signed passport, or
pass one through. Similarly, RIPP servers must act as
verifying parties and reject any calls that omit a passport. In cases
where the RIPP client is an end device, it still inserts a passport -
but uses a self-signed certificate. 

[TODO: Need to check we have all the things needed in an Passport.]

## Calls Separate from Connections

In SIP, there is a fuzzy relationship between calls and
connections. In some cases, connection failures cause call
terminations, and vice a versa.

HTTP, on the other hand, very clearly separates the state of the
resource being manipulated, with the state of the HTTP connection used
to manipulate it. This design principle is inherited by
RIPP. Consequently, call state on both client and server exist
independently from the connections which manipulate them. This allows
for greater availability my enabling connections for the same call to
move between machines in the case of failures.

## Path Validation, not ICE

HTTP/3 is designed to work through NAT as a client-server protocol. It
has built in techniques for dealing with NAT re-bindings, IP address
changes due to a client moving between networks (e.g., wifi to
cellular data). It has built in path validation that ensures that HTTP
cannot be used for amplification attacks.

SIP has, over the years, solved these problems to some degree, but not
efficiently nor completely. To work with HTTP, RIPP must utilize the
HTTP approaches for these problems. Consequently, RIPP does not
utilize ICE and has no specific considerations for NAT traversal, as
these are handled by HTTP/3 itself.

# Terminology {#terminology}

This specification follows the terminology of HTTP/3, but adds the
following concepts:

Terminal Group (TG): A container for calls between a client and
server. A TG is identified by a URI, hosted on the server. A TG acts
as a unit of policy and capabilities, including rules such as rate
limits, allowed phone numbers, and so on. The acronym is a nod to its
circuit switched predecessor, the Trunk Group.

Call: A real-time voice and/or video session. A call is always
associated with a TG, and is identified by a URI hosted on the
server.

Customer: An end user or administrative entity that utilizes
communications services from a provider in order to make and receive
calls. The relationship between the customer and provider is static
and does not vary from call to call, and does not vary in call
direction either. (e.g., Verizon would be the provider to an
enterprise customer, and the enterprise would be the customer of
Verizon). For the purposes of this specification, this matters in that
a customer, if it wishes to implement the server role, will need to
configure its provider with credentials and URI needed to enable the
provider, acting as a client, to connect to its server. Consequently,
RIPP provides a facility for this.

Provider: The administrative entity that provides communications
services to the customer. 

Byway: A bidirectional byte stream between a client and server. A
byway passes its data through HTTP, using a set of techniques which
depend on the capabilities of both sides and the use cases for which
they are needed. This specification considers two types - a signaling
byway and a media byway.

Handler: A handler is a software or hardware entity, acting as a
client, which sends and receives media associated with a call. The
handler can change during a call (as in the case of a client failing
and its calls being picked up by a backup). A handler has a
description, which is relatively static, that describes its audio and
video capabilities, device name, image, and so on.

Directive: The directive is an instruction from the server, which
tells a handler where it should send media to for this call. 


# Reference Architecture {#refarch}


RIPP is also designed such that all communications between the RIPP
client - which is just an HTTP client - and the RIPP server - which is
just an HTTP server - can easily sit behind a typical HTTP load
balancer, as shown below:


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
| RIPP       |     |  HTTP   |/            |  RIPP      | 
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

The customer and provider role is asymmetric. Typically the customer
has purchased services from the provider. From a protocol perspective,
RIPP assumes that the customer has an account with the provider, and
it is possible for the customer to obtain an OAuth token which can be
used to authenticate. However, there is no login technqiue which
enables the provider to obtain a token to place calls towards the
customer.

Since calls always originate from client to server, in order to
receive inbound calls, a customer can also run a RIPP server. RIPP
supports a simple registration mecahnism by which the customer -
acting as a client - can use RIPP to register its
TG URI with the provider.  This registration also includes a bearer
token for authorization.

It is anticipated that an entity implementing the server role will use
a load balancer to receive incoming requests to place calls. This is
not required, of course. However, this specification provides no
facility for a customer implementing only the client role to receive
inbound calls. It is worth restating that this load balancer is NOT
specific to RIPP - it is any off-the-shelf HTTP load balancer which
supports HTTP/3. No specific support for RIPP is required. RIPP is
just an application ontop of HTTP.

Because RIPP clients and servers are nothing more than HTTP/3
applications, the behavior or RIPP is specified entirely by describing
how various RIPP procedures map to the core HTTP/3 primitives available
to applications - opening connections, closing connections, sending
requests and responses, receiving requests and responses, and setting
header fields and bodies. That's it.

# Domain Model

The domain model for RIPP is based on the interplay between three
key resources held by the server. These are the TG, the handler, and
the call.

The TG is a representation of the service offered by the server to the
client. It indicates the allowed directions for calls (in this
specification, outbound only), the allowed identities that can be used
for caller ID, the allowed numbers which can be called, and a basic
set of limits on call volumes. The purpose of the TG is to provide the
client all of the information it needs to know, in advance, whether
the placement of a call is within the allowed policy scope of the
server.

For example, a telco might offer an enterprise customer a service in
which it can place calls to any number in the world, but it must use
one of the 100 numbers that have been assigned to it as the caller
ID. The TG object - literally a JSON document returned by the server -
also called he representation of the TG - would provide this
information to the client.

In the case of a trunking use case where an enterprise customer is
implementing the server and client roles, the enterprise, acting as
client, can inform the provider of its own TGs through a simple TG
registration. Consequently, the RIPP protocol allows a server to
accept TG registrations from a client. Typically, when an enterprise
acts as a client and registers its own TGs to the provider's server,
those TGs do not accept registrations. In other words, the provider
(e.g., Verizon) would not register TGs with the enterprise, even
though the enterprise supports the RIPP server role.

A handler is a representation of a physical hardware device, such as
an SBC or IP PBX, or software, which acts as a client and can handle
calls. Its primary role is to model the capabilities of the device -
such as supported media types and codecs. The server needs this
information in order to decide how media is to be handled for the
call. For any particular call, there is a single handler. This handler
is determined when the call is placed, and can change during the
lifecycle of the call. For example, if a software SBC instance 
supporting G729 (which is a single handler) places a call, this SBC
crashes, and a different SBC which only supports G.711 (which is a
different handler) needs to step in and take over the call, the
handler would change.

Of course, a single physical device might be represented logically by
one or more handlers; the mapping of a piece of software or hardware
to a set of handlers is a matter of local implementation.

A handler is always associated to a TG. As part of startup procedures,
the client will register its handler with the TG.

The final resource is a call, which is exactly what it sounds
like. Calls are always associated with one and only TG. When a client
creates a call, it does so in the context of the TG (i.e., call
creation is a POST operation on a resource within the TG). Similarly,
calls are associated with a single handler. When a client creates a
call, it tells the server which handler is being used. This allows the
server to compare the capabilities of the client with its own, and
make a decision about what media the client should send with. The
server communications this directive back to the client. 


# Deployment Examples {#deployments}

RIPP enables communications between a pair of administrative
domains. This enables its usage in many use cases where there are
bilateral relationships requiring real-time communications. This
section contains several use cases which are target use cases for
deployment of RIPP.

## Enterprise Voice Trunking

In this use case, the provider is a telco that enables connectivity to
the PSTN. The customer is an enterprise, utilizing an enterprise
PBX. Or, it might be a contact center provider. This is the use case
for which SIP trunking is widely deployed today.

To support this case, both the provider and the customer implement
both the client and the server roles, as shown below:

~~~ ascii-art
   Customer A                Provider B

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

In this use case, a key goal is to facilitate automated configuration
of SIP trunks - a process which is, today, complex and error
prone. This section discusses how RIPP can make such configuration as
easy as a web app login.

Consider a simple use case of a small business hosting a single IP PBX
server, on a single machine, which is being used to make and receive
calls. To set up the IP PBX for peering, the administrator would go to
the configuration web application on the IP PBX.

The  web application would have a page for selecting their trunking
provider, with a list of supported providers. The user clicks on
"Comcast". This begins a standard OAuth flow. The end user would be
directed to the login page for Comcast, provide their credentials, and
then be asked to authorize the IP PBX to access their Comcast account
on their behalf. It would also display the permissions being requested
(which Comcast would define and the IP PBX would request). In this
case, probably the ability to make and recieve calls on their
behalf. The user would click on "approve". The standard OAuth flow
would then have deposited an OAuth access token on the IP PBX.

The IP PBX would use the API defined below to obtain the list of TG
URIs which are available for that user (which will often just be
one), and present the user with the list of such trunks. The user
would select one, if needed. At this point, the IP PBX now has the
user's OAuth token and the provider TG URI, which are the only two
pre-requisites for placing calls. 

No further configuration or setup is required. Using RIPP, the IP PBX
will read an advertisement associated with the TG URI to learn its
capabilities and features, create and
upload its own TG URI and bearer token, and now be able to make and
receive calls. 

## BYO Voice for CCaaS

In a related case, an enterprise has purchased voice services from
Comcast as in the case above. However, rather than deploying an IP
PBX, they wish to utilize the services of a Contact Center as a
Service (CCaaS), such as Five9. In this example, Five9 supports a
"BYO" model where the enterprise customer can purchase their voice
services from another provider - such as Comcast, and then authorize a
third party - in this case Five9 - to access them on their behalf.

The flow works almost identically to the above case. The end user
would visit five9.com, log in using their Five9 account, and click on
the button to enable Comcast as their BYO provider. The user would be
directed to log into their Comcast account, and then authorize Five9
to access their Comcast account for making and receiving calls. The
user would approve, and then setup is complete.

In essence, a side effect of using OAuth for authentication and
authorization is that it enables a wide range of access models for
telecommunications services. Access can be granted to servers (as in
the IP PBX case above), or to other cloud services (as in this case),
with a common mechanism. 

## Inter-Carrier Voice Peering

In this case, a pair of telcos exchange voice traffic
bidirectionally. Today this is done using SIP NNI interfaces as well
as traditional SS7. This is accomplished in RIPP by having both telcos
implement the provider role with a server only, as well as the
customer role with a client only. When initiating outbound calls, the
carrier would act as a customer, and when receiving them, as a
provider. This enables a fully symmetric interconnect.

The authentication and authorization flow differs in this use case
from the ones above. Since it symmetric, each side will need to have
an account set up for the other. Administrators for both sides will
then need to subsequently log into the other side and perform the
OAuth flow to obtain an OAuth token for the other.

## Video Endpoint to Meetings Provider

In this use case, there is a video conferencing device. The end user
wishes to join a meeting hosted on a meeting provider. The meeting
would be modeled as a call to number@domain, where the number is the meeting
number used for the meeting. Using the domain, the video endpoint
would construct the RIPP root URI and then query to discover the
available provider TGs. This request will not be authenticated,
because the video endpoint has no relationship with the meeting
provider. Consequently, the meeting provider returns a provider TG URI
which corresponds to an "unauthenticated meeting join" TG.

Of course, if the video endpoint were a user of the meeting provider,
it could have such a token and use it for the call.

Finally, the video endpoint would place a call to the meeting
address. 

The video endpoint does not need to register a customer TG URI
with the meetings provider, because it will never receive incoming
calls. 


# Overview of Operation

The basic operation of RIPP is broken into several steps - bootstrap,
login, provider TG discovery, customer TG registration, handler
registration, call establishment, and media exchange.

## Bootstrap

Bootstrap is the process by which a client starts with just the
domain name of the server - such as five9.com or comcast.net or
cisco.com - and uses that to discover the two URI which may be needed
to do everything else.

One of these URI is a URI which can be used to kickoff a web-based
OAuth flow for generating an OAuth token. The other is the RIPP root
URI. Both of these are well-known URI as defined by
[@I-D.nottingham-rfc5785bis]. Consequently, they are constructed
using the syntax defined in [@I-D.nottingham-rfc5785bis].

Their IANA registrations can be found in (#iana).

For example, for comcast.net, the RIPP OAuth URI is
https://comcast.net/.well-known/ripp-oauth, and the RIPP root URI is
https://comcast.net/.well-known/ripp. 

## Login

Login is the process by which an OAuth token is delivered to the
client. This step is performed only when the client role is being
played by the customer. If the client role is being player by the
provider, this step is skipped.

When login is done, it is always done through some technique outside
of the scope of RIPP. If the use case is to be done where the user is
in front of a browser, the application can direct the user to visit
the OAuth page learned from the discovery process above.

## TG Discovery

The client needs to figure out the set of TG which are available to
it. There may be cases where the server is offering the
client more than one. For example, a telco might offer an enterprise
an international TG which is used to place calls to non-US numbers,
and a domestic TG which is used for domestic calls. 

To obtain the list, the client queries the /providertgs resource on
the well-known RIPP root URI:

https://example.com/.well-known/ripp/providertgs

this URI will return the list of TG available to the client. This
list has, for each, the TG URI and a name and description in prose,
meant for a user to select. When the user selects, the client can
fetch the TG to learn its details, by performing a GET against the TG URI.

An example TG supporting outbound dialing from a 2-line IP PBX to
domestic numbers with a
peek concurrent call rate of 10 calls (essentially a two line key
system, using old terminology) might look like this:

~~~ ascii-art
{
  "outbound": {
    "origins" : ["+14085551000", "+14085551002"],
    "destinations" : "+1*",
    "max-concurrent-calls" : {
      "grouped-by": "tg",
      "maximum": 10
    }
  }
}  
~~~

An enterprise trunk allowing outbound calls to any number worldwide,
using one of the 1000 numbers assigned to that enterprise, might look
like this:

~~~ ascii-art
{
  "outbound": {
    "origins" : "+14085551*",
    "destinations" : "*"
  }
}  
~~~


In most cases, the server will require the client to authenticate in
order to retrieve this document. Typically, a server would have many
TGs provisioned, and each TG is associated with a specific customer
which will connect to it. The customer ID would be associated with the
TGs it is permmitted to access, and that same customer ID would
normally be placed into the OAuth token that the client obtains during
login. This allows the origin server to determine who the customer is,
and what TG(s) they are allowed to connect to. This is standard
procedure for most web APIs when a query is performed - the set of
resources returned depend on who is asking.


## Customer TG Registration

If the client role is being played by a customer who wishes to receive
incoming calls, it will need to implement the server role of RIPP. Its
customer TG needs to be registered with the server. To do this, it
performs a POST to the /customertgs resource on the RIPP root URI, and
sets two parameters - its own URI, and a bearer token used for
authorization of inbound requests.

The customer TG URI has to be reachable by the server in order for the
it to receive calls, and for security purposes it must also support
TLS and present a valid certificate using the same trust chains
configured into browsers. This specification envisions an extension
which allows a client to receive calls without requiring it to run an
HTTP server, thus allowing for it to run behind a NAT and not have a
certificate.

An example of a customer TG registration might be this:

~~~ ascii-art
POST https://comcast.net/.well-known/ripp/customertgs
{
  "outbound": {
    "origins" : "*",
    "destinations" : "+14085551*"
  }
}  
~~~

Notice how the directionality is "outbound" - this is because a TG
only supports outbound calls, and from the perspective of the provider
towards the customer, these are outbound. Similarly, note how the
"destinations" parameter indicates the range of numbers reachable via
this TG. The provider would validate that these are authorized based
on prior business relationship, and reject them otherwise. For
example, if the customer indicated it wanted to receive calls for
numbers which were not obtained from that provider, the provider's
terms of service may not allow that, and it would reject the request.

A success esponse to this would be a 201 Created, with the TG which
was created: 

~~~ ascii-art
{

  "uri" : "https://comcast.net/.well-known/ripp/customertgs/12345",

  "outbound": {
    "origins" : "*",
    "destinations" : "*"
  }
}  
~~~

The client can use the /consumertgs to modify this later (with a PUT
to the URI in the "uri" parameter), DELETE it, or create another.

Once created the consumer TG will persist indefinitely. 


## Handler Registration

The handler is a representation of a set of capabilities that
can be used when placing a call. The handler description is a
semi-static declaration which declares features, codecs, and other
properties of the handler. Handler descriptions are semi-static in that they
do not change on a call by call basis. They change only when some kind
of significant configuration change happens. For example, if an SBC
receives an upgrrade to support a new codec, its handler description
would change. Consequently, handler descriptions are expected to change
perhaps a few times a year.

A handler registration is created by having the client perform an HTTP
POST operation to the /handlers resource on the TG URI. This operation
creates a new handler instance on the server and returns its URI to
the client. The client is expected to store this URI in order to make
modifications at a later date (via PUT), or DELETE it. The handler can
be destroyed at any time by the server. The client can discover this
by subscribing to handler events, as described below.

The handler description has a list of media sources and sinks that the
endpoint has, and an ID for each which monotonically increases from
0. There are four types - mics, cameras, screens and speakers. An
endpoint can have more than one of each. The case of PSTN gateways or
traditional voice-only phones is simple - they have a single mic and a
single speaker, mapping to sending and receiving audio. This is true
for a PSTN gateway regardless of its capacity. In other words, if a
PSTN gateway has a circuit switched line card with 100 ports, its
handler description still has just one mic and one speaker.

A three-screen telepresence system might have three screens,
three mics, three cameras, and three speakers, and represents the
opposite end of the spectrum in terms of complexity.

For each source or sink, there are one or more parameter sets that can
be specified. Each parameter in the parameter set has a name and a
value. The value is always an integer from 0 to 2**31 - 1. Parameters are
typically standardized and registered with IANA. The registration
indicates the meaning of the values - their units and allowed
values. Most importantly, the parameter is always expressed in a way
where the value represents a maximum of some sort. This enables
booleans (where the maximum is 1), integral ranges (where the maximum
is a large-ish integer), or ordered enums (where the enum values
correspond to integers in order). When a parameter is not specified,
it takes on a default. Similarly, if the handler description document is not
present, the default can be assumed for all parameters.

Codec support is signaled using boolean parameters, with names that
match the media subtypes defined in the IANA protocol registry for
media types [@RFC4855].

The handler also contains meta-data which aids in handler
selection and identification. These include device nicknames, image
URLs, vendor names, and so on.

An IP phone with a single microphone and speaker that support G.711 and
opus might create its handler thusly: 

~~~ ascii-art
POST https://comcast.net/.well-known/ripp/providertgs/123/handlers
{

  "nickname": "Home Phone",
  "img" : "https://www.exampe.com/images/phones/7960.jpg",
  "vendor" : "Cisco Systems Inc.",
  "device-id": "982akca99283",

  "mic": {
    "id" : 0,
    "param-sets" : {
      "opus" : 1,
      "PCMU" : 1,
      "PCMA" : 1
    }
  },
  
  "spk" : {
    "id" : 1,
    "param-sets" : {
      "opus" : 1,
      "PCMU" : 1,
      "PCMA" : 1
    }
  }
}
~~~

and the reply would be:

~~~ ascii-art
201 Created

{

  "nickname": "Home Phone",
  "img" : "https://www.exampe.com/images/phones/7960.jpg",
  "vendor" : "Cisco Systems Inc.",
  "device-id": "982akca99283",


  "uri":"https://comcast.net/.well-known/ripp/providertgs/123/handlers/abc",
  "id": "abc",

  "mic": {
    "id" : 0,
    "param-sets" : {
      "opus" : 1,
      "PCMU" : 1,
      "PCMA" : 1
    }
  }
  "spk" : {
    "id" : 1,
    "param-sets" : {
      "opus" : 1,
      "PCMU" : 1,
      "PCMA" : 1
    }
  }
}
~~~

Notice how the server as added the "id" and "uri" parameters. The "id"
parameter is a globally unique ID for this handler.

A device with a camera that could support H.264 at 4K and av1 at 1080p
might have a handler description that looked like, in part (focusing
just on the capability components):

~~~ ascii-art
"cam": {
   "id" : "1",
   "param-sets": [
        {
	 "H264" : 1,
	 "max-width" : 3840
	 "max-height" : 2160	 
        },
        {
	 "AV1" : 1,
	 "max-width" : 1920
	 "max-height" : 1080
        }
   ]
}   
~~~

A video phone that could support opus and H.264 at 720p @ 30 fps might look
like:

~~~ ascii-art
{

 "mic": {
    "id" : 0,
    "param-sets" : {
      "opus" : 1,
      "PCMU" : 1,
     }
  }
  "spk" : {
    "id" : 1,
    "param-sets" : {
      "opus" : 1,
     }
  }
  "cam":  {
    "id" : 2,
    "param-sets" : {
      "H264" : 1,
      "max-width" : 1280,
      "max-height" : 720
      "max-fps" : 30
    }
  }
  "screen":  {
    "id" : 3,
    "param-sets" : {
      "H264" : 1,
      "max-width" : 3840,
      "max-height" : 2160,
      "max-height" : 60
    }
  }
  
}
~~~

As with any kind of capabilities techology, the one defined here
cannot describe arbitrary constraints. It cannot express dependencies
that may arise between audio and video, or between encoding and
decoding. It, in essence, represents each as an OR-of-ANDS construct,
and while all boolean expressions can be reduced to this form, it will
produce extremely unwieldy results with complex expressions. It cannot
represent ranges of values.

We believe this represents the minimum technique which can be used to
describe modern AV systems.


## Call Establishment {#directive}

The client can initiate calls by POSTing
to /calls on the TG URI.  The request contains:

1. the target phone number or email address,
2. A passport [@RFC8225] identifying the calling identity,
3. The handler ID from which the call is being placed,

in the body.

For example, to place a call to a phone number from the handler above:

~~~ ascii-art
POST "https://comcast.net/.well-known/ripp/providertgs/123/calls
{
  "handler": "https://comcast.net/.well-known/ripp/prov
     idertgs/123/handlers/abc",
  "destination": "+14089529999",
  "passport": "{passport encoding}"
}
~~~

The server takes the handler description associated with the handler
URI, takes its own handler description (which it has never
exchanged, but merely knows), and figures out what it will
send, and what the client must send. It takes the latter - the
definition of what the client must send - and constructs a
directive out of it. The directive has the same syntax as the
handler description. However, it only includes media sources (since by
definition the directive tells the remote peer what to send), there is
one parameter set per source, and for each parameter, the value
indicates what the client should send. The directive is always specified
in a way that makes the value of each parameter less than the maximum
value for both the client and server. 

The server places the call, and returns the call
description back to the client. The call description includes the
directive along with core meta-data about the call - directionality,
caller, callee and a URI for the call:

~~~ ascii-art
201 Created

{

  "uri" :
  "https://comcast.net/.well-known/ripp/providertgs/123/calls/987",

  "handler": "https://comcast.net/.well-known/ripp/prov
     idertgs/123/handlers/abc",
  "destination": "+14089529999",
  "passport": "{passport encoding}"

  "direction": "outbound",

 "mic": {
    "id" : 0,
    "param-sets" : {
      "opus" : 1,
      "PCMU" : 0
     }
  }
  "cam":  {
    "id" : 2,
    "param-sets" : {
      "H264" : 1,
      "max-width" : 1280,
      "max-height" : 720
      "max-fps" : 30
    }
  }
}
~~~

Note how the audio directive has selected Opus. 

Another important consequence of this design is that media packets
must be self-describing, without any kind of reference to a specific
call. This is because the directive is constructed from the
handler descriptions only, and the handler descriptions are semi-static. This
means RIPP does not use dynamic payload types to identify codecs.

Typically
the response will also include a session cookie, bound to the call, to
facilitate sticky session routing in HTTP proxies. This allows all
further signalling and media to reach the same RIPP server that
handled the initial request, while facilitating failover should that
server go down. 

Once a call has been created, a pair of long-lived HTTP transactions
is initiated from the client to the server for purposes of
signalling. One is a GET to the /events resource on the call URI,
retrieving call events from the server. The other is a PUT to the same
/events URI, used by the cient to send call events to its peer. The
combination of these two is called the signalling byway. HTTP/3
ensures zero RTT for setup of these transactions.

Signaling commands are encoded into the signalling byway using
streaming JSON in both directions. Each JSON object encodes an event
and its parameters. A set of events common to all deployments of RIPP
are defined for proceeding, alerting, answered, declined, ended,
migrate, moved, and hello. An additional set are defined targeted at
server to server cases, such as SIP trunking and inter-server
peering. These include transfer-and-takeback.

## Media Exchange

Media exchange makes use of webtransport over HTTP3
[@I-D.vvv-webtransport-http3] when it is available, falling back to
media byways when it is not.

Once the call signaling is complete, the client attempts to open a
webtransport session within the current HTTP3 connection. If this
succeeds, the client and server can both send media chunks as
webtransport datagrams.

If the connection does not support webtransport, the client takes
responsibility for opening media byways, which carry media chunks in
both directions. Even though data can flow in both directions, a media
byway is unidirectional in terms of media transmission. A forward
media byway carries media from the client to the server, and a reverse
byway carries media from the server to the client. These map directly
to HTTP PUT and GET respectively, as they do for signaling byways.

Unlike signaling byways where sequenced, in-order and reliable
delivery is desired, these are undesirable for media.

To eliminate them for media in the forward direction, for each and
every media chunk to send, the client will create a 
new PUT transaction, send the media chunk, and immediately close the
transaction. When run over HTTP3, this process takes place with
zero-RTT. When the server receives the request and associated media
chunk, it immediately sends a 200 OK response, includes a payload
containing an acknowledgement media chunk, thus completing the
transaction. Since HTTP3 will use a different QUIC stream for each
HTTP transaction, each of these transactions occurs on a different
stream, and therefore there is no HOL blocking between media packets. 

Receiving media is more complex, since the server cannot initiate
HTTP requests in the reverse direction. To solve this, the client
initiates 20 GET requests to the server to retrieve media chunks. These GET
requests contain no body. The server, when it wishes to send a media
chunk, chooses an existing GET transaction and sends the chunk as a
response body. The client, upon receiving this, immediately opens a
new GET transaction to replace the one it just received a response
on. Consequently, a client always maintains 20 open GET
transactions. [TODO: need to tune this and justify its value]. In
addition, the client will include an acknowledgement media chunk along
with its next media chunk in a PUT request. 

The use of acknowledgements provides the ability for clients and
servers to elect to retransmit media as well as to generate detailed
statistics on packet loss and delay on a packet-by-packet basis. 
Consequently, the equivalent of RTCP sender and receiver
reports are not needed.

## Graceful Migration

RIPP provides a simple technique for allowing a call to
gracefully migrate from one client instance to another on a different
host, or from one server instance to another on a different host. The
client always performs the migration action. It can be instructed by
the server to do so via a migrate event. Or, it can decide to do so
on its own. 

The migration process is meant to support two key use cases - one is
when a traditional HTTP load balancer is used, and the other is when
there is none. 

In the first case, there is a traditional HTTP load balancer fronting a
farm of HTTP origin servers. The migration operation is meant to move
the call from one origin server to another. A server can request this
in order to shed load. Or, it can request this because it has been
instructed to shut down and restart, perhaps to perform a software
upgrade, or to migrate its docker container to another node. It is
assumed that some kind of shared database is used to store any state
that needs to be passed between origin servers. RIPP is designed such
that the only state which needs to be stored is call state, and not
media state.

In this use case, if the origin server handling the call does not
desire to receive new calls (including the one it is about to
migrate), it would be removed from the pool of available servers in
the load balancer. The means for this is outside the scope of this
specification. Then, the origin server sends a migration event to the
client. 

This event can contain an IP to which the transaction should be
directed. When an HTTP load balancer is used, this is not needed. This
will cause the client to end its current signaling and media
transactions. It then re-opens them, reusing the existing connection it has
to the HTTP load balancer. Crucially, these new requests do NOT
contain any session cookies. This means that the HTTP load balancer
will send the new request to one of the available origin servers,
which will no longer include the one which is being brought down for
maintenance. The responses will contain session cookies in order to
enable sticky session routing for subsequent requests for this call.

Whether client or server initiated, when a migration occurs, both
sides buffer their media packets and signaling events until the byways
are ready to carry them. This enables the migrations to occur with
literally no gap in media. The migration takes only a single RTT
between client and server, and thus will often occur within the
boundaries of jitter buffer depths. 

Note that the call state persists independently of the state of the HTTP
connection or the byways embedded in HTTP transactions, so that a
reconnect can continue where things left off. This is why, when a call
migrates, the client does NOT initiate a new call, it opens signaling
and media byways to the existing call URI it already has.

## Non-Graceful Migration

RIPP is also designed to handle failures of clients, servers and
network connectivity issues, and to reconnect calls with a minimum of
disruption. It does this by providing implementors with tools to
enable such resiliency, without being overly prescriptive on exactly
how it is implemented. 

The asymmetric nature of RIPP means that it is always the
responsibility of the client to recover from
network failures and failures of a downstream server or load
balancer. 

The first failure case is that of a closure of the actual HTTP
connection, either gracefully or non-gracefully. In this case, the
client retries the connection with an exponential backoff, the backoff
timer being another parameter which can be specified in the TG. Once
the connection is re-established, it initiates the signaling and media
byways, and will reuse any session cookies it had previously received.

RIPP also requires clients to send keepalive signaling events
periodically for each call, and the server responds to these
events. If the client ceases to receive the server keepalives for a certain
duration (a value again that has a default but which can be tuned in
the TG handler description), it treats this identically to a request for a
migration. This will cause it to end its signaling and media byway
transactions, and re-initiate them without session cookies.

Finally, the media byways are used for rapid failure detection. If the
client fails to receive acknowledgements for the media it has sent for
period of time (this timer not being subject to standardization as it
is entirely a matter of local configuration), the client can
re-establish the signaling and media byways as if it were a
migration. 

The above cases handle failures in the network and of the origin
servers and intermediate load balancers. If there was a failure of the
origin server and it was not able to recover sufficient call state for
re-establishment, it rejects the re-establishment of the media and
signaling byways. This causes a call termination from the perspective
of the client, which it would typically pass upstream if needed, as an
event. And indeed for the origin server to recover, it will need to
stash state. Specifically, it will need to stash the callID and the
downstream entity to which the call was set when it was
established. If the downstream entity is a RIPP server, the TG URI,
call URI, selected IP address (from either DNS or using the IP in the
advertiseent), and session cookie are stored. These facilitate
reconnection to the same downstream instance.

In inter-domain peering arrangements, such as enterprise voice
trunking or inter-carrier NNI voice peering, both sides will typically
have a cluster of software agents (VMs, docker containers, bare-metal
servers, dedicated hardware products, or whatever) acting as both clients and
servers. Consequently, we need to consider what happens to the client
transactions when these fail.

In such a case, failure recovery is always delegated to the upstream
client. In this case, let us assume that the client had this cluster
of agents at its perimeter. It would be receiving calls from some
further upstream elements. If those elements were using RIPP, it would
mean that the roles were reversed - a particular agent was acting as a
server to receive a call, and then as a client to send it
downstream. If that agent fails, the upstream client would detect
this, and migrate to a different agent. This new agent - which has no
in-memory state for the call - would look up the
state of the call in some shared database, see where it was routed (in
this case, to the TG), and retrieve the session cookie which
had also been stored after the call was established. This new agent
then re-establishes the media and signaling byways, perhaps even
opening a fresh HTTP connection to do so. The use of the session
cookie enables the byways to be re-established to the server's origin
server that has been, and is still - handling the call.

This allows a chain of RIPP clients and servers in back-to-back
configuration to recover from failures of any intermediate element
without dropping calls. Furthermore, failure detection and recovery
are rapid, especially when using load balancers. When an origin server
fails, the client can still reuse its connection to the load balancer,
such that connection establishment is not needed. Indeed, the time to
recover from failure is only 1/2 RTT between client and server,
once the client has detected the downstream failure.

Of course, the downstream element may be SIP-based and not RIPP. In
such a case, INVITE with Replaces is a good solution, and vendors of
highly reliable SIP gear are encouraged to support it. 

# Normative Protocol Specification

This section contains the normative specification of RIPP.

## Bootstrapping

A RIPP client that wishes to obtain an OAuth token to a specified
authority through a web interface MUST construct a well known RIPP
Oauth URI using [@I-D.nottingham-rfc5785bis] with ripp-oauth as the
well-known service, and use this to trigger the Oauth process.

Similarly, a RIPP client wishing to access the resources defined in
this specification, against an authority (such as example.com) MUST
use [@I-D.nottingham-rfc5785bis] with ripp as the well-known
service. The result is the
RIPP root URI for that authority.

## TG Discovery

All clients MUST perform a GET query to the /providertgs on RIPP root
API for an authority they wish to connect to. Origin servers MUST
provide a resource at this URI. It MUST be constructed using the JSON
syntax described in (#syntax), and MUST have one or more TG URI
in the list. It is RECOMMENDED that the origin server specify that
this document can be cached.

If the client receives a document and there is only one TG
URI, it uses this for subsequent outound calls to the server. If
there is more than one, the client SHOULD request user input if it has
such a facility. If not, it SHOULD select the first.

At the end of this process, the client will have a TG URI. It MUST
retrieve the value of this URI, and use it to process calls. 

## TG Construction

When a server (either for the consumer or the provider) retrieves a
GET aginst the a valid TG URI, it MUST return a document with a set of
parameters. 

The document MUST contain an "outbound" element. The "origins" field
specifies the permitted caller ID values which can be present in the
passport used in a call setup towards this TG. If the server will
reject a call due to policy around caller ID, it MUST include a value
for this parameter. The default is "*" meaning the server will accept
any calls. Similarly, the "destinations" field specifies the allowed
targets for calls. The server MUST include this element if it will
reject a call based on policy for a specific destination. The default
is "*" meaning the TG will accept any calls.

TODO: add details for max-concurrent-calls.

In addition, the TG URI contains a set of configuration values. If
absent, these take their default. The following are defined:


* retry-backoff: In the event of a closure of the HTTP connection,
  this parameter specifies the initial time value to use before
  retrying the connection. If a retry fails again, the client will try
  again but this time wait twice the value of this timer, then four
  times, eight times, etc. The value of this parameter is an integer,
  in units of milliseconds. Its default is 2000.

* media-timeout: If a client fails to receive media ack packets after
  the timeout specified in this parameter, it considers the call dead
  and initiates migration. The value of this parameter is an integer,
  in units of milliseconds. Its default is 5000.


OPEN ISSUE: Do we want to support cases where RIPP is implemented by
SBCs which are not fronted by a web load balancer? In such a case,
we'll want something similar to RFC3263, wherein the handler description
contains the set of IP addresses for the cluster and we define load
balancing behavior. 

## Consumer TG Registration

If an entity needs to receive inbound calls from its provider, it MUST
register a consumer TG. To do that, it MUST initiate an HTTPS PUT
request towards /consumertgs on the TG URI. This request MUST be
authenticated by the origin server. The request MUST include a TG
description object in the body. This object is specified in Section
(#syntax).

The TG description object MUST contain a consumer TG URI and
a bearer token. The client TG URI MUST be unique for each distinct
provider TG URI to which it is registered. This URI MUST support
HTTP/3, and MUST implement the /handlers, /calls, and /events 
resources and their associated behaviors. This URI MUST be
reachable by the provider. The URI MUST utilize HTTPS, and MUST
utilize a domain name for the authority component. 

In addition, the client MUST mint a bearer token to be used by the
provider when performing operations against the consumer TG.  The
bearer token MAY be constructed in any way desired by the client. The
token and URI SHOULD remain valid for at least one day, however, a
security problem MAY cause them to be invalidated.  The client MUST
refresh the registration at least one hour in advance of the
expiration, in order to ensure no calls are delayed. The token MUST be
unique for each unique provider TG.

The destinations and origins elements in the consumer TG description MAY be
included. If they are included, the destinations MUST be a subet of
the addresses present in the origins element in the provider TG
description. Similarly, the origins element MUST be a subset of the
addresses present in the destinations element in the provider TG
decription. If absent, the default is that the origins and
destinations values are identical to the destinations and origins
values in the provider TG, respectively. The default value for the
destinations and origins is *. Consequently, if absent in the provider
TG description, it means any destination address from any caller ID is
permitted. 


## Handler Registration and Lifecycle Management.

Prior to placing a call towards a TG, a client MUST have an active
handler registered to the server. To register one, it performs a POST
on the /handlers resource on the TG URI. This request MUST contain a
handler desription conformant to the syntax in (#syntax) and following
the rules defined in the next section. 

If the request is valid and authorized, the origin server MUST
return a 201 Createed response, with the URI for the new handler in
the Location header field. It MUST echo back the handler desription,
and MUST add or replace the "uri" parameter in that description to
contain this URI. 

The server MAY time out or otherwise destroy the handler resource at
any time. The client can discover this by performing a GET against the
URI and seeing a 404, however it is RECOMMENDED that the client
instead perform a long lived GET to the /events resource on the TG
URI. This returns a long running stream json containing events. The
"handler" event MUST be sent by the server when the handler
is destroyed. This event indicates what happened to the handler
("created", "modified" or "destroyed" along with the URI for the
handler. 


## Handler Description Format

An handler description is a set of parameters, each of which is a name-value
pair. This specification defines several well-known names and
establishes an IANA registry for future extensions. Every capability
has a default, so that if no document is posted, or it is posted but a
specific capability is not included, the capability for the peer is
understood.

Four parameters are defined for media capabilites - mic, spk, cam,
screen, corresponding to the ability to generate audio, receive audio,
generate video, and receive video. There MUST be one instance of these
parameters for each corresponding source and sink which can
simultaneously send or receive its media in a single call. Each
instance MUST have a unique id within the handler description. Each instance
MUST include one or more param-sets. Each param-set is a set of
parameters. Each parameter MUST specify the
maximum that the sink can receive, or source can send, for that
parameter. The server MUST include a parameter and its value when it
differs from the default, and SHOULD NOT include it when it matches
the default. 

This specification defines the following parameters for mic and spk:

* sr: The maximum sample rate for audio. This is specified in Hz. The
  default is 48000.

* ss: The maximum sample size for audio. This is specified
  in bits. It MUST be greater than or equal to 8. The default is 16. 

* cbr: If present, indicates whether the entity requires constant
  bitrate (CBR) media only. It has value of 1 (indicating CBR only) or
  zero (no constraint on rate). Zero is default. 

* ch: Indicates whether the entity supports  multiple
  audio channels.  The default is 1 for support.

* ptime: max duration of media encoded in single packet in ms. Default is 30. 

This specification defines the following parameters for cam and screen:

* fps: The maximum frame rate for video. This is specified in frames per
  second. The default is 30.

* max-res: the max width in pixels. Default is TBD.

* pr: the max pixel rate ( pixels / second ). Default is 2^64-1. 

* depth: the max pixel depth in bits. Default is 8.

This specification defines the following capability set for scalable video
codecs:

* tlay: max number of temporal layers. Each sub layer runs at twice the
rate of the later it depends on. Default is 1.

* slay: max numer of spacial layers. Each sub layer has 2 times the number
  of pixel of layer it depended on. Default
  is 1. [[ Open issue 2 times or 4 times ]] 

This specification defines the following capability set for both audio
and video codecs.

* br: The maximum bitrate in kilo bits per second for receiving audio or
  video. This is specified in bits per second. This is the rate of
  encoded media from the codec and not the rate transmitted over the
  network. Default is 2^64-1.

* codec names - The codec names are defined in the IANA registry
"Media Types" at
https://www.iana.org/assignments/media-types/media-types.xhtml. For
each one, the value of the parameter is either 1 or 0, 1 indicating
support, and 0 indicating no support.

All RIPP implementations MUST support G.711 and Opus audio codecs. All
implementations MUST support [@RFC2833] for DTMF, and MUST support
[@RFC3389] for comfort noise, for both sending and receiving.

In general, an entity MUST declare a capability for any characteristic
of a call which may result in a proposal being unacceptable to the
client. This requirement facilitates prevention of call failures.

It is RECOMMENDED that the handler description include a nickname, img,
vendor and device-id elements. The device-id element, when present,
MUST be globally unique in space and time. 

## Call Establishment

To place a call, the client performs a POST request to /calls resource
on the TG URI URI. This request MUST include a body, formatted
according to the syntax of (#syntax). The body MUST contain the
"handler", "destination" and "passport" values.

The handler value MUST be a valid HTTPS URI and MUST point to a hander
registered and active against the same authority in the POST's request
URI. If there is no matching handler currently registered, the server
MUST return a 500. 

The destination MUST be either an E.164 value or an email address. If
an E164 address, it SHOULD be a subset of the addresses defined in the
"destinations" parameter of the TG description. A server MUST reject a
request whose target does not so match.  RIPP also supports private
trunks, in which case the destination MUST take the form
<number>@<domain>, where the number is a non-E164 number scoped to be
valid within the domain. This form MUST NOT be used for E.164 numbers.

The passport URI parameter MUST be a valid passport as defined by
[@RFC8224]. It identifies the calling party and includes signature
information which can be used to verify it. If the client has no
official certificate proving ownership of the identity in the
passport, it MUST generate a self-signed certificate and use that. The
caller ID and called party values in the passport MUST be within the
allowed values defined in the "origins" and "destinations" parameters
of the TG, respectively.

The server MAY authorize creation of the call using any criteria it so
desires. If it decides to create the call, the server MUST return a
201 Created response, and MUST include a Location header field
containing an HTTPS URI which identifies the call that has been
created. The call URI MUST be globally unique in time and space, with
randomness properties identical to a type 4 UUID. 

The server MUST construct a directive, which tells the client what
media to send. This directive MUST include zero or more mic parameters,
and zero or more cam parameters, corresponding to the sources and
that the server wishes the client to send. These MUST be a subset of
those present in the handler description. The server MUST
specify the values for any codec which are not the default. The value
for each parameter MUST be less than the value specified in the
handler description from the client, and also MUST be less than its own
maximum value from its own handler description. If a selected value differs
from the default, it MUST be included in the directive. The directive
MUST include the "id" attribute for the source. This is crucial to
inform the peer which of its sources to send.

Similarly, the server chooses which of its sources will send, and to
which sinks on its peer it will send. It MUST NOT send media for which
there is not a corresponding sink on its peer which is a match for the
media type. It MUST send utilizing media parameters which are less
than the values specified in the handler description in the peer for that
sink.

The server MUST include the directive in the body of the 201 response,
MUST include the URI for the handler that was used, MUST include the
call direction, and MUST include the from and to participants. 

The server MAY include HTTP session cookies in the 201 response. The
client MUST support receipt of cookies [@RFC6265]. It MUST be prepared
to receive up to 10 cookies per call. The client MUST destroy all
cookies associated with a call, when the call has ended. Cookies MUST
NOT be larger the 5K. 

If the
request is otherwise valid, but the target of the call cannot be
reached through the TG URI, it MUST generate a 404 response. If the
request is valid and the target can be reached, but the client is not
allowed to do so for policy reasons it MUST generate a 403 response.

## Signaling and Media Byway Establishment

If the server returns a 201 Created to the client, the client MUST
establish the forward and reverse signaling byways by sending a PUT request and
GET request, respectively, to the /events resource on the call URI
obtained from the Location header field in the 201 response. The GET
request MUST NOT contain a body. The PUT request and GET response MUST
contain an infinitely long JSON document. The client MUST hold both
transactions open until the call has ended. 

The body begins with an open square bracket to indicate the start of an
JSON array, and after that is a
series of JSON objects, each starting with a curly bracket, and ending
with a curly bracket. Consequently, each side MUST immediately send
their respective open square brackets after the HTTP header fields. We
utilize streaming JSON in order to facilitate usage of tools like CURL
for signalling operations.

The server MUST immediately send the current state of the call as far
as it is concerned, by generating an event in the response which
indicates this state. For a brand new call, this MUST be the
proceeding event. For any call, a server MUST support multiple
signaling byways, in which case it MUST send all call events on all
open reverse signaling byways, and MUST accept commands from any
forward one. A server MUST NOT terminate the call if there are no
signaling byways established; rather it utilizes timeouts as described
below.

Each event is a JSON object embedded in the signalling stream, which
conveys the event as perceived by the client or server.  The event
MUST contain a direction field, which indicates whether the event was
sent from client to server, or server to client. It also MUST contains
a timestamp field, representing universal time, which indicates the
time of the event as perceived by the sender. The event MUST contain a
call field, which contains the URI of the call in question. The event
MUST contain an event type field, which conveys the type of
event. This is followed by additional fields which are specific to the
event type.

Events are also defined so that the resulting state is uniquely
defined by the event itself. This ensures that knowing the most recent
event is sufficient to determine the state of the call. 

In addition, the client MUST immediately establish 20 reverse media
byways by initiating 20 GET requests to the /media resource on the call
URI. These requests MUST NOT contain a body. The media byways are
required before call answer to support early media. For any call, a
server MUST support up to 30 reverse media byways open. 

## Basic Call State Management

The server always maintains definitive state for the call. The basic
state of the call is manipulated through events passed from one side
to another. 

This specification defines the following events which MUST be
implemented by all RIPP client and servers: These events are
asymmetric, in that the direction of call establishment impacts who
can send which events, and when. 

proceeding: Passed from server to client, indicating that call setup
is in progress but has not reached the recipient. 

alerting: Passed from server to client, indicating that the recipient
is alerting.

answered: Passed from server to client, indicating that the call was
accepted by the recipient. At this point, the call is considered
established. 

declined: Passed from server to client, indicating that the call was
rejected by the user.

failed: Passed from server to client, indicating that the call was
rejected by server or downstream servers, not by the user, but due to
some kind of error condition. 

noanswer: Passed from server to client, indicating that the call was
delivered to the receiving user but was not answered, and the server
or a downstream server timed out the call.

end: initiated by either client or server, it indicates that the call
is to be terminated. Note that this does NOT delete the HTTP resource,
it merely changes its state to call end. Furthermore, a call cannot be
ended with a DELETE against the call URI; DELETE is not permitted and
MUST be rejected by the server. 

migrate: sent from server to client, it instructs the client to
terminate the media and signaling byways, and re-establish them. The
event MAY contain an IP address to which the media and signaling
byways will be established.

hello: This event is always initiated by the client. When received
by a server, the server MUST generate a keepalive response. The
keepalive MAY contain a nonce, and if so, the server MUST echo it in
the response. 

The client can obtain the current state of the call at any time by
querying the call URI. The server MUST return a call description which
includes the directive, call direction, calling and called parties,
and the handler which is being used. This aspect of RIPP is essential
for allowing clients to fail, recover, and re-obtain the state of the
call. 

## Sending and Receiving Media

Media is always associated with a call. Within a call, media has a
direction (c2s or s2c). Within a
direction, media belongs to a stream, where a stream is transmitted
between a source and a sink. As such there can be many streams in each
direction. A stream is an ordered sequence of media
chunks. There is a sequence number space and timestamp space
associated with each stream. A stream is uniquely identified by the
call URI, the direction, the source ID and sink ID. 

The forward and reverse byways each contain an unordered sequence of
media chunks and control chunks. The only control chunk defined by
this specification is the acknowledgement chunk. Any media or control
chunk, for any stream, MAY be sent in any forward or reverse byway for
c2s and s2c streams respectively. 


### The Media Chunk Format


Each ripp media chunk has an outer envelope that is not encrypted,
except by the transport the chunk is sent over, and an inner package
that is encrypted. Inside both the envelope and package are a set of
tag length values (TLV) tuples.

Each media chunk has the following properties in the envelope part:

* Media or Control: a boolean which indicates whether this is a media
  or control packet. The remaining parameters apply when it is media.

* The truncated sequence number, which provides the absolute ordering
  of the packets for the codec. (tag = 1). The sequence number is
  actually 64 bits long, but the encoding is of variable length. This
  allows for any number of bits to be sent on the wire. If N bits are
  sent, where N is less than 64, the value is treated as the truncated
  version of the actual sequence number, and the recipient computes it
  from prior packets. Clients MUST send full values until such time
  as they receive an acknowledgement of the media packet containing a
  full value, and after that, SHOULD send truncated values. For video,
  if the media is an intra-frame, the full value MUST be present.

* The truncated timestamp, which provides the wall clock time in ms of
   when the first sample of media in the chunk was recorded. Like
   sequence number, this value is represented with 64 bits, but
   truncated values can be sent. The client MUST send full values
   until the first packet containing a full value has been
   acknowleded, and after that, SHOULD send truncated values. For
   video, if the media is an intra-frame, the full value MUST be
   present. (tag = 2)

* The truncated payload type, which is a 32 bit integer specifying the
   codec in use. The integral values are maintained an in IANA
   registry and directly map to the media type names. It is encoded as
   a variable length field, enabling a small number of bits for
   frequent codecs. (tag = 3)

* The media source, which is an 8 bit integer specifying the ID of the
  media source for this chunk. 

* The media sink, which is an 8 bit integer specifying the ID of the
  media sync for this chunk. 

* Optional Reference frame flag. Indicates other chunks are encoded
  based on this frame. Typically used with video codecs and only set
  true on chunks that are part of an I Frame. Default value is false.

* Optional Spacial Layer scale: TBD - indicates which spacial layer this
  packet is part of when using a scalable codec 

* Optional Temporal Layer scale: TBD - indicates which temporal layer this
packet is part of when using a scalable codec

* Active  Level: Provides indication of audio energy in media
  chunk and can be used by conferring bridges to do speaker
  selection. 

* Optional extension parameters in the envelope

Each media chunk has the following properties in the package part:

* Media. Then output from the codec (tag=4)

* optional extension parameters in the package

The chunk is encoded by passing the envelope as authenticated data,
and the package to an AEAD cipher. The chunk is created by taking the
truncated auth tags of the cipher followed by output of the AEAD
cipher.  The keys for the cipher to use, the keys for the cipher, and
the authentication tag truncation are set by mechanisms outside this
section. It not specified, they default to the NULL cipher with no
keys. 

### The Control Chunk

The control chunk also has an envelope and payload, and is structured
identically to media chunks. Its envelope has the following
parameters:

* Media or Control: a boolean which indicates whether this is a media
  or control packet. The remaining parameters apply when it is
  control.


* Control Type: a 16 bit integer which indicates the type. Only one
  type is defined by this specification - acknowledgement.


The payload then depends on the control type. For an acknowledgement, the
payload contains the direction, media sourceID and media sink ID of
the chunk being acknowledged. The final component needed to identify a
chunk - the callID - is inferred from that of the
media byway in which the acknowledgement is sent. 


### Client Media handling

If the HTTP connection supports webtransport, media chunks MUST be sent
(and received) as datagrams over the webtrasport session.

If not, to send media, the client MUST create a new HTTP PUT request
to the /media resource on call URI for each media chunk to send. The
body of the request MUST include the media chunk. If the client has
received any chunks from the peer for this call since the last time it
has sent a media packet for this call, it MUST include an
acknowledgement control packet in the body as well, one for each
unacknowledged media chunk. Once the one media chunk and zero or more
acknowledgement packets have been sent, the client MUST end the
transaction.

To receive media, the client will have a large number of reverse media byways
open (as GET requests to the /media resource for the call). If a
response is received, the client extracts the contents, which will
always be one media chunk and zero or more control chunks.

The media sent by the client MUST match the directive received from the
server. 

### Server Media Handling

If the HTTP connection supports webtransport, media chunks MUST be sent
(and received) as datagrams over the webtrasport session.

If not, to send media, the server MUST select an open GET request to
/media. It is RECOMMENDED that the server select the oldest one. The
server MUST place its media chunk in the body of the response. If the server has
received any media chunks from the peer for this call since the last time it
has sent a media packet for this call, it MUST include an
acknowledgement control packet in the body as well, one for each
unacknowledged media chunk. Once the one media chunk and zero or more
acknowledgement packets have been sent, the server MUST end the
transaction. If the server is unable to send media for the call
because there are no open requests, it MUST generate the "media-panic"
event on the event stream towards the client, which indicates this
problem. The server MUST drop the media chunk. The call will
eventually trigger migration as the client will timeout on
acknowledgements. 

The server will receive one media and zero or more control chunks as
the body of the PUT requests. 

## Connection and Byway Lifecycle Management

The state of the connection, the QUIC streams, and byways, is separate
from the state of the call. The client MAY terminate an HTTP
connection or byway at any time, and re-establish it. Similarly, the
server or client may end the a byway at any time, neither affects call
state directly. 

If a byway ends or the connection breaks or is migrated, the client
MUST re-initiate the byways immediately, or risk loss of media
and signalling events. However, to deal with the fact that
re-establishment takes time, both client and server MUST buffer their
signalling and media streams for at least 5 seconds, and then once the
connections and byways are re-established, it sends all buffered data
immediately.

A server MUST maintain a timer, with a value equal to 30 seconds, for
which it will hold the call in its current state without any active
signalling byway. If the server does not receive a signalling
byway before the expiration of this timer, it MUST consider the
call as ended. Once the call has ended, the call resource SHOULD be destroyed. 

If the server receives a signalling or media byway for a call that
is TERMINATED, it MUST reject the transaction with an 404
response code, since the resource no longer exists.

Note that it is the sole responsibility of the client to make sure
byways are re-established if they fail unexpectedly.


## Retrieving Call List

A client MAY initiate a GET request against the /calls resource in the
TG. The server MUST return a body with the list of all calls which
currently exist on the server. This is just a list of call URI. This
is useful for a client which restarts and wishes to rebuild its view
of call state.

## Graceful Call Migration

A server MAY initiate a call migration at any time for a specific
call. To do so, it MUST send a migration event to the client over the
signaling byway. The client MUST honor this request for migration. The
client MAY choose to migrate the call to a different server at any
time.

To perform the migration, the client MUST end all outstanding HTTP
transactions for the call (signaling and media byways). It MUST
initiate a new signaling byway for the call, 
targeting the IP if it has been specified by the server. This may
require the client to open a new HTTP connection, if it does not
already have one open to the target. The client MUST NOT include a
session cookie in the POST to /events. This is essential to cause the
request to route to a different instance behind the load balancer,
which will typically be configured with sticky routing. The server MAY
respond to this request with a new session cookie. The client MUST NOT
initiate forward or reverse media byways  until the client receives
response headers to the signaling byway creation. This is to enable
session cookies to be included in these requests for sticky routing. 

The client SHOULD cache all media that the client wishes
to transmit, but was unable to do so during the migration. The media
MUST then be sent in a burst once the media byways are
re-established. This ensures there is no packet loss (though there
will be jitter) during the migration period.

## Ungraceful Call Migration

If the origin server or HTTP load balancer fails unexpectedly, this is
handled by the client. If the client (1) receives a reset on the
signaling byway, or (2) receives no media packets for 5s, or (3)
receives no acknowledgements for media packets it has sent for 1s, or
(4) receives a ungraceful closure of the HTTP connection, it MUST
initiate a migration as defined in the prior section.


# SIP Gateway 

RIPP is designed to be easy to gateway from SIP. The expectation is
that RIPP will be implemented in SBCs and softswitches. A SIP to RIPP
gateway has to be call-stateful, acting as a B2BUA, in order to
gateway to RIPP. Furthermore, a SIP to RIPP gateway has to act as a
media termination point in SIP. It has to perform any SRTP decryption
and encryption, and it must de-packetize RTP packets to extract their
timestamps, sequence numbers, and codec types.

SIP to RIPP gateways are not transparent. SIP header fields which are
unknown or do not map to RIPP functionality as described here, gets
discarded.

Any configuration and provisioning for RIPP happens ahead of receipt
or transmission of SIP calls. Consequently, the logic described here
applies at the point that a gateway receives a SIP INVITE on the SIP
side, or receives a POST to the RIPP trunk URI on the RIPP side.

This specification does define some normative procedures for the
gateway function in order to maximize interoperability. 


## RIPP to SIP

## SIP to RIPP


# RAML API {#syntax}

<{{ripp-api.raml}}


# IANA Considerations {#iana}

## Registration of Well-Known Web Services

This specification defines two new well-known web services as defined
in [@I-D.nottingham-rfc5785bis] - ripp and ripp-oauth.

## RIPP

URI suffix: ripp

Change controller:  IETF

Specification document(s): This specification.

Status:  Permanent.

## RIPP-Oauth

URI suffix: ripp-oauth

Change controller:  IETF

Specification document(s): This specification.

Status:  Permanent.


# Security Considerations

# Acknowledgements

Thanks you for review and edits to: Giacomo Vacca. Thank you to Mo
Zanaty for greatly simplifying the advertisement  proposal for video. 

{backmatter}

