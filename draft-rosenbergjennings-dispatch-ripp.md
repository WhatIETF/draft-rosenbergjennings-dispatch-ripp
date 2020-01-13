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
for this use case, and is designed as a web application using
HTTP/3. Using HTTP/3 allows trunking consumers to more easily build
their applications on top of cloud platforms, such as AWS, Azure and
Google Cloud, all of which are heavily focused on HTTP based
services. RIPP also addresses many of the challenges of traditional
SIP-based peering. It supports modern techniques for load balancing,
autoscaling, and failover, adds mid-call failovers and graceful call
migrations, is secure by default, requires STIR-based caller ID, and
has built-in techniques for provisioning and capabilities - all of
which have been challenges with traditional SIP peering and
voice trunking. Since it runs over HTTP/3, it works through NATs and
firewalls with the same ease as HTTP does

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
cloud platforms which require interconnection with the public switched
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

2. Lack of built-in protocol mechanisms for call preservation

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
Architecture (#reference), Deployment Examples (#deployments)

The normative content is split into four components - creating a
reverse tg, tg, call, and media, each of which represents a web
service. These are sections TODO.


# Solution Requirements (#req)

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


# Design Approaches (#design)

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
pattern and only concerns itself with HBH behaviours. Like HTTP, a RIPP
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

Though SIP envisioned that signalling and media separation would also apply to
inter-domain calls, in practice this has not happened. Inter-domain
interconnect - including interconnection with the PSTN - is
done traditionally with SBCs which terminate and re-originate
media. Since this specification is targeted at inter-domain peering
cases, RIPP fundamentally combines signalling and media together on
the same connection. To ensure low latency, it uses multiple
independent request/response transactions - each running in parallel
over unique QUIC streams - to transmit media. 


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
pass it to the provider, along with the URI for receipt of inbound
calls. 


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

# Terminology (#terminology)

This specification follows the terminology of HTTP/3 - specifically:

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

This specification defines the following additional terms:

RIPP Terminal Group (TG): A container for calls between a trunking
provider and trunking consumer. A RIPP TG is identified by a pair of
URI - the Provider TG (hosted by the provider) and the Consumer TG
(hosted by the consumer). A TG acts as a unit of policy and
capabilities, including rules such as rate limits, allowed phone
numbers, and so on. The acronym is a nod to its circuit switched
predecessor, the Trunk Group. 

Call: A real-time voice and/or video session established by a RIPP
client. A call is always associated with a TG.

Consumer: An administrative entity that utilizes communications
services from the provider in order to make and receive calls. The
relationship between the consumer and provider is
static and does not vary from call to call. (e.g., Verizon would be
the provider to an enterprise consumer, and the enterprise
would be the consumer of Verizon. A consumer
implements a RIPP client to initiate calls to the provider,
and a RIPP server to receive them.

Provider: The administrative entity that provides communications
services to the consumer. The provider implements a RIPP server to receive
calls from the consumer, and a RIPP client to send calls to
the consumer

Provider TG: An HTTP resource and URI hosted by the provider, which
represents the RIPP TG from its perspective.

Consumer TG: An HTTP resource and URI hosted by the consumer, which
represents the RIPP TG from its perspective. Since RIPP is meant to be
used in environments where there is an asymetric relationship between
provider and consumer, the consumer TG URI can be registered
provider during configuration time. 

Byway: A bidirectional byte stream between a RIPP provider and
consumer. A Byway passes its data through a long-running HTTP request
and a long-running HTTP response. Byways are used for signalling and
media.


# Reference Architecture (#refarch)

The RIPP reference architecture is shown in Figure 1.

~~~ ascii-art
   Consumer A                Provider B

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

RIPP is used between a RIPP provider and a RIPP 
consumer. Both entities implement the RIPP client and RIPP server
roles; the latter to receive calls, and the former to send them.

RIPP is also designed such that all communications between the RIPP
client and the RIPP server can easily sit behind a typical HTTP load
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

The consumer and provider role is asymmetric. Typically the consumer
is quite literally a customer of the provider, purchasing
services. From a protocol perspective, RIPP assumes that the consumer
has an account with the provider, and it is possible for the consumer
to obtain an OAuth token which can be used to authenticate. 

In order to receive inbound calls, the consumer can use RIPP to
register its consumer TG URI with the provider. In cases where the
client is behind a NAT, it can utilize protocols like STUN or TURN to
obtain a URL reachable by the provider. This registration also
includes a bearer token for authentication.

Since both the provider and consumer implement the client and server
roles, both entities will typically have a load balancer - perhaps a
server component, or a cloud-based service, used to receive incoming
calls. This is not required, of course. It is worth restating that
this load balancer is NOT specific to RIPP - it is any off-the-shelf
HTTP load balancer which supports HTTP/3. No specific support for RIPP
is required. RIPP is just a usage of HTTP.

Because RIPP clients and servers are nothing more than HTTP/3
applications, the behavior or RIPP is specified entirely by describing
how various RIPP procedures map to the core HTTP/3 primitives available
to applications - opening connections, closing connections, sending
requests and responses, receiving requests and responses, and setting
header fields and bodies. That's it.

# Deployment Examples (#deployments)

RIPP enables communications between a pair of administrative
domains. This enables its usage in many use cases where there are
bilateral relationships requiring real-time communications. This
section contains several use cases which are target use cases for
deployment of RIPP.

## Enterprise Voice Trunking

In this use case, the provider is a telco that enables connectivity to
the PSTN. The consumer is an enterprise, utilizing an enterprise
PBX. Or, it might be a contact center provider. This is the use case
for which SIP trunking is widely deployed today.

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
consumer role with a client only. When initiating outbound calls, the
carrier would act as a consumer, and when receiving them, as a
provider. This enables a fully symmetric interconnect.

The authentication and authorization flow differs in this use case
from the ones above. Since it symmetric, each side will need to have
an account set up for the other. Administrators for both sides will
then need to subsequently log into the other side and perform the
OAuth flow to obtain an OAuth token for the other.


## IP Phone to UCaaS Provider (#ipphone)

In this case, an enterprise has purchased telephony services from a
UCaaS provider. The enterprise has deployed both hard and soft phones
to consume this service. Some of those devices reside on campus, some
outside of campus - perhaps a user's home, or running on an user's PC
in an Internet cafe.

In this model, the UCaaS provider (say, provider.com) is the
provider. It will have a TG URI for each end user, since the TG URI is
bound to the phone numbers and other policies and permissions. The IP
phone starts with just the domain name of the provider and an OAuth
token. Using [@draft-nottingham-rfc5785bis] it will learn the RIPP
root URI. From there, the IP phone queries the list of provider TGs it
can access, and finds only one. With the provider TG URI in hand, it
can use it to register its own consumer TG (and a bearer token for
authentication), and can then place and receive calls.

In the case of a softphone, the OAuth token can be easily obtained by
login. The end user would only enter the provider name (e.g.,
provider.com). Once again using [@draft-nottingham-rfc5785bis] it will
construct the RIPP root URI and a URI for triggering an OAuth flow for
RIPP. The URI for the OAuth flow will allow the user to log in and
grant permission to the IP phone, thus giving it the needed OAuth
token. As with the hardphone, the RIPP root URI is used to learn the
one and only provider TG URI which is needed.

In most cases the IP phone will not have a publically reachable
IP. Its consumer TG URI needs to be reachable from the provider for
RIPP to work. It can obtain one through any number of techniques,
which are discussed in more detail below. 

Note that, in this use case, media will always flow from the IP phone
to the UCaaS provider. If a user on one phone called a user on another
phone, the media would flow from phone one, the UCaaS provider, to
phone 2, even if the two phones sat on the same LAN.

## Video Endpoint to Meetings Provider

In this use case, there is a video conferencing device. The end user
wishes to join a meeting hosted on a meeting provider. The meeting
would be modeled as number@domain, where the number is the meeting
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

The video endpoint does not need to register a consumer TG URI
with the meetings provider, because it will never receive incoming
calls. 

## Consumer Voice with E2E Encryption

In this use case, there is a provider that offers an e2e encrypted
voice communications service to end users. These users access the
service via the web browser.

In this case, let us assume that RIPP is implemented in the browser
itself, in essence a next-generation version of webRTC. The use would
visit the website of the provider, and log in. The Javascript API
would expose a small number of APIs - one to connect (which takes the
provider TG URI and then pushes the consumer TG URI to the server, as
described in (#ipphone)),
one to place a call, and a callback for receiving calls. There would
also be configuration which specifies the desire for e2e encryption of
the media.

Using out-of-band techniques, such as those described in
[@draft-ietf-mls-protocol], the Javascript app would obtain the
necessary encryption keys and ciphersuite, and tell the browser to
utilize them when sending media to the server via the call API, which
initates a RIPP call.

In this case, the media will be e2e encrypted, but will still flow
through the provider. 

## Browser to Browser Video

In this use case, a provider is offering video services, but desires
the video to flow directly between the two browsers in the call.

For this use case, RIPP is not used between the browser and the
provider. This is because the media always follows the signaling. To
enable this use case, the browser would utilize webRTC along with some
web APIs for rendezvous and exchange of offers and answers that are
strictly for a data channel. This is NOT RIPP!

Once the offer/answer exchange is completed, the browser can open to
open a data channel to the other browser, and tunnel RIPP over it. The
RIPP exchange would be used to start and stop the call, along with the
exchange of advertisements, setup of calls and then exchange of media.


# Overview of Operation

The basic operation of RIPP is broken into several steps - discovery,
login, TG retrieval, consumer TG pushing, advertisement exchange, call
establishment, and media exchange.

## Discovery

Discovery is the process by which a consumer starts with just the
domain name of the provider - such as five9.com or comcast.net or
cisco.com - and uses that to discover the two URI which may be needed
to bootstrap everything else.

One of these URI is a URI which can be used to kickoff a web-based
OAuth flow for generating an OAuth token. The other is the RIPP root
URI. Both of these are well-known URI as defined by
[@draft-nottingham-rfc5785bis]. Consequently, they are constructed
using the syntax defined in [@draft-nottingham-rfc5785bis].

Their IANA registrations can be found in (#iana).

For example, for comcast.net, the RIPP OAuth URI is
https://comcast.net/.well-known/ripp-oauth, and the RIPP root URI is
https://comcast.net/.well-known/ripp. 

## Login

Login is the process by which an OAuth token is delivered to the
consumer. This is always done through some technique outside of the
scope of RIPP. If the use case is to be done where the user is in
front of a browser, the application can direct the user to visit the
OAuth page learned from the discovery process above.

## TG Retrieval

The consumer needs to figure out which of the provider's TG it wishes
to connect to. There may be cases where the provider is offering this
consumer more than one.

To obtain the list, the consumer queries the well-known RIPP root URI

https://example.com/.well-known/ripp

this URI will return the list of TG available to the consumer. This
list has, for each, the TG URI and a name and description in prose,
meant for a user to select. Selection should only be needed in
enterprise and service provider use cases.

In most cases, the server will require the client to authenticate in
order to retrieve this document. Typically, a provider would have many
TGs provisioned, and each TG is associated with a specific customer
which will connect to it. The customer ID would be associated with the
trunk group, and that same customer ID would normally be placed into
the OAuth token that the consumer obtains during login. This allows
the origin server to determine who the customer is, and what TG(s)
they are allowed to connect to. This is standard procedure for most
web APIs when a query is performed - the set of resources returned
depend on who is asking. 

## Consumer TG Registration

If the consumer wishes to receive incoming calls, it will need to
implement the server role of RIPP. Its consumer TG URI needs to be
registered with the provider. To do this, it performs a POST to the
provider TG URI, and sets two parameters - its own URI, and a bearer
token used for authentication of inbound requests.

The consumer TG URI has to be reachable by the provider in order for
the consumer to receive calls. If the consumer is behind a NAT, it can
obtain a publically reachable URL through any number of techniques
outside of the scope of this specification.

One technique would be to 
utilize TURN [@RFC5766]. As another example, the consumer could
utilize STUN against a STUN server run by the provider. If the client
finds its behind a server reflexive NAT, it can use the STUN server to
generate a server reflexive address, and then generate its consumer TG
URI from there. Note that both STUN and TURN work best with UDP. This
is a great match for HTTP/3 which ultimately runs over UDP as well. 

## Advertisement Exchange

An advertisement is a semi-static declaration which declares features,
codecs, and other properties of the TG. Advertisements are semi-static
in that they do not change on a call by call basis. They change only
when some kind of significant configuration change happens. For
example, if a RIPP server receives an upgrrade to support a new codec,
its advertisement would change. Consequently, advertisements are
expected to change perhaps a few times a year.

When an advertisement does change, an endpoint can tell its peer using
HTTP push. 

Both sides obtain the others capability declaration for the RIPP trunk
by performing a GET to /advertisement of its peers TG URI. The
advertisement declaration is a simple document, whose syntax is
described in Section (#syntax).

The advertisement has a list of media sources and sinks that the
endpoint has, and an ID for each which monotonically increases from
0. There are four types - mics, cameras, screens and speakers. An
endpoint can have more than one of each. The case of PSTN gateways or
traditional voice-only phones is simple - they have a single mic and a
single speaker, mapping to sending and receiving audio. This is true
for a PSTN gateway regardless of its capacity. In other words, if a
PSTN gateway has a circuit switched line card with 100 ports, its
advertisement still has just one mic and one speaker.

A three-screen telepresence system might have three screens,
three mics, three cameras, and three speakers, and represents the
opposite end of the spectrum in terms of complexity.

For each source or sink, there are one or more parameter sets that can
be specified. Each parameter in the parameter set has a name and a
value. The value is always an integer from 0 to 65535. Parameters are
typically standardized and registered with IANA. The registration
indicates the meaning of the values - their units and allowed
values. Most importantly, the parameter is always expressed in a way
where the value represents a maximum of some sort. This enables
booleans (where the maximum is 1), integral ranges (where the maximum
is a large-ish integer), or ordered enums (where the enum values
correspond to integers in order). When a parameter is not specified,
it takes on a default. Similarly, if the advertisement document is not
present, the default can be assumed for all parameters.

Codec support is signaled using boolean parameters, with names that
match the media subtypes defined in the IANA protocol registry for
media types [@RFC4855]. 

When a call is to be placed, the client takes the advertisement from
its peer, takes its own advertisement, and figures out what it will
send, and what the other side must send. It takes the latter - the
definition of what the other side must send - and constructs a
directive out of it. This directive is sent to the callee during call
setup - see below. The directive has the same syntax as an
advertisement. However, it only includes media sources (since by
definition the directive tells the remote peer what to send), there is
one parameter set per source, and for each parameter, the value
indicates what the peer should send. The directive is always specified
in a way that makes the value of each parameter less than the maximum
value for both the sender and receiver. 

Another important consequence of this design is that media packets
must be self-describing, without any kind of reference to a specific
call. This is because the directive is constructed from the
advertisements only, and the advertisements are semi-static. This
means RIPP does not use dynamic payload types to identify codecs.

A device with a single microphone and speaker that support G.711 and
opus might have an advertisement that looked like:

~~~ ascii-art
{
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

A device with a camera that could support H.264 at 4K and av1 at 1080p
might have a advertisement that looked like, in part:

~~~ ascii-art
"cam": {
   "id" : "1",
   "param-sets": [
        {
	 "H264" : 1,
	 "max-res" : 3840
        },
        {
	 "AV1" : 1,
	 "max-res" : 1920
        }
   ]
}   
~~~


An video phone that could support opus and H.264 at 720p @ 30 fps might look
like:

~~~ ascii-art
{

 "mic": {
    "id" : 0,
    "param-sets" : {
      "opus" : 1,
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
      "max-res" : 1280,
      "max-fps" : 30
    }
  }
  "screen":  {
    "id" : 3,
    "param-sets" : {
      "H264" : 1,
      "max-res" : 3920,
      "max-fps" : 60
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

In addition to classic media-related capabilities, the advertisement
can contin other properties of the TG. These include features (such as
support for takeback-and-transfer or hold). They can also include a
list of the IPs of all of the origin servers associated with the
authority in the URI and the fraction of load each is supposed to
receive. This enables a broad set of load balancing techniques that
facilitate adoption of RIPP into classic telco networks which utilize
farms of SBCs - identified by IP - as the outermost network ingress
point. 

## Call Establishment

Either the consumer or provider can initiate calls by posting
to /calls on TG URI of its peer.  The request contains the target
phone number and Passport [@RFC8225] as URI parameters. The body
contains a proposal, which follows the format for an advertisement and
specifies what media the callee must send. (#proposal) describes the
normative procedures for its construction. 

This request returns a globally unique call URI in the
Location header field of a 201 response sent by the server. Typically
the response will also include a session cookie, bound to the call, to
facilitate sticky session routing in HTTP proxies. This allows all
further signalling and media to reach the same RIPP server that
handled the initial request, while facilitating failover should that
server go down.

Once a call has been created, a pair of long-lived HTTP transactions
is initiated from the client to the server for purposes of
signalling. One is a GET, retrieving call events from its peer. THe
other is a PUT, sending call events to its peer. Each of these
produces a unidirectional data stream, one in the forwards direction,
one in the reverse. These are called signaling byways. HTTP/3
ensures zero RTT for setup of these byways.

Signaling commands are encoded into the signalling byway using
streaming JSON in both directions. Each JSON object encodes an event
and its parameters. A set of events common to all deployments of RIPP
are defined for alerting, connected, ended, migrate, and keepalive, An
additional set are defined targeted at server to server cases, such as
SIP trunking and inter-provider peering. These include
transfer-and-takeback. There is a separate set meant for signaling
from phones to servers - hold, transfer, park, pickup, mute, unmute,
retrieve.

## Media Exchange

Media exchange makes use of webtransport over HTTP3
[@draft-vvv-webtransport-http3] when it is available, falling back to
media byways when it is not.

Once the call signaling is complete, the caller attempts to open a
webtransport session within the current HTTP3 connection. If this
succeeds, the caller and callee can both send media chunks as
webtransport datagrams.

If the connection does not support webtransport, the caller takes
responsibility for opening media byways, which carry media chunks in
both directions. Even though data can flow in both directions, a media
byway is unidirectional in terms of media transmission. A forward
media byway carries media from the client to the server, and a reverse
byway carries media from the server to the client. These map directly
to HTTP PUT and GET respectively, as they do for signaling byways.

Unlike signaling byways where sequenced, in-order and reliable
delivery is desired, these are undesirable for media.

To eliminate them for media in the forward direction, for each and
every media chunk to send, the client will open a media byway with a
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
with its next media chunk that is sent in a forward byway.

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
the server to do so via a migration event. Or, it can decide to do so
on its own. This technique is also called call preservation. 

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
byways. It then re-opens them, reusing the existing connection it has
to the HTTP load balancer. Crucially, these new requests do NOT
contain any session cookies. This means that the HTTP load balancer
will send the new request to one of the available origin servers,
which will no longer include the one which is being brought down for
maintenance. The responses will contain session cookies in order to
enable sticky session routing for subsequent requests for this call.

In the second case, there is no traditional HTTP load
balancer. Rather, the provider is using a farm of RIPP-capable
SBCs, each of which can act as an origin server. The advertisement in
the TG can include a configuration of the IPs of the SBCs, with
information on the relative load that each SBC should receive. In
essence, it provides similar information to that present in an
[@RFC3263] SIP DNS SRV record. When the client is told to migrate, it
will re-initiate the signaling and media byways, and it will send the
call to one of the other SBCs besides the one it had originally
selected for the call. Similarly, the migrate event can contain a
reference to the specific SBC instance to which the call should be
moved, by IP address. This allows providers fined grained controls on the
balancing of calls between servers.

In additon, since RIPP utilizes HTTP PUSH to tell the client to
refresh the TG advertisement, a provider can inform the consumer about
updates to the IP addresses immediately. This allows providers to
expand or contract their cluster sizes, and communicate this to all
clients which are currently connected. The update propagates without
dependency on DNS propagation times. The ability to update without
dependency on DNS propagation is key to enabling load balancing, since
this is one of the reasons why DNS-based load balancing as envisioned
in [@RFC3263] does not work in elastic deployments. 

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
responsibility of the caller (i.e., the client) to recover from
network failures and failures of a downstream server or load
balancer. 

The first failure case is that of a closure of the actual HTTP
connection, either gracefully or non-gracefully. In this case, the
client retries the connection with an exponential backoff, the backoff
timer being another parameter which can be specified in the provider
advertisement. Once the connection is re-established, it initiates the
signaling and media byways, and will reuse any session cookies it had
previously received. 

RIPP also requires clients to send keepalive signaling events
periodically for each call, and the server responds to these
events. If the client ceases to receive the server keepalives for a certain
duration (a value again that has a default but which can be tuned in
the TG advertisement), it treats this identically to a request for a
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
client. In this case, let us assume that the consumer had this cluster
of agents at its perimeter. It would be receiving calls from some
further upstream elements. If those elements were using RIPP, it would
mean that the roles were reversed - a particular agent was acting as a
server to receive a call, and then as a client to send it
downstream. If that agent fails, the upstream client would detect
this, and migrate to a different agent. This new agent - which has no
in-memory state for the call - would look up the
state of the call in some shared database, see where it was routed (in
this case, to the provider TG), and retrieve the session cookie which
had also been stored after the call was established. This new agent
then re-establishes the media and signaling byways, perhaps even
opening a fresh HTTP connection to do so. The use of the session
cookie (or the stored IP of where the original call was routed),
enables the byways to be re-established to the provider's origin
server that has been, and is still - handling the call.

This allows a chain of RIPP clients and servers in back-to-back
configuration to recover from failures of any intermediate element
without dropping calls. Furthermore, failure detection and recovery
are rapid, especially when using load balancers. When an origin server
fails, the client can still reuse its connection to the load balancer,
such that connection establishment is not needed. Indeed, the time to
recover from failure is only 1/2 RTT between consumer and provider,
once the consumer has detected the downstream failure.

Of course, the downstream element may be SIP-based and not RIPP. In
such a case, INVITE with Replaces is a good solution, and vendors of
highly reliable SIP gear are encouraged to support it. 

# Example

This section describes a typical example where one company, Acme, is
using a cloud calling service -  Webex - and gets PSTN trunking from the
provider Comcast.

The sequence diagram for the outbound call flow is here:

<{{seq-diagram-out.txt}}

The first stage is for Webex to set up their service to be able to
work as an OAuth Client, working with Comcast as the Authorization
Server, and to obtain the baseURI that Comcast uses for RIPP
authorization. Assume that this is
"https\://comcast.net/.well-known/ripp-oauth". The next stage is the
admin from ACME logs on to their Webex account and selects Comcast as
the RIPP provider.  This will cause the OAUTH dance and the admin will
end up having approved Webex to use Acme's account at Comcast for
RIPP. Webex will have received an OAuth access and refresh token from
Comcast and be passed the new Provider Trunk URI. At this point,
provisioning is complete and calls can start. Webex will query the
well-known RIPP root URI - "GET
https\://comcast.net/.well-known/ripp" which returns the list of valid
TGs. In this case, there is only one - trunk URI returned is
"https\://ripp.comcast.com/trunks/123". 

Webex will start by setting up for incoming calls at
"https\://ripp.webex/trunks/abc" with an opaque security token of
"secret1234". This is done by making a HTTP PUT to
https\://ripp.comcast.com/trunks/123/consumerTG with a JSON
body of:

~~~
{
"consumerTG":"https://ripp.webex/trunks/abc" ,
"consumerToken":"secret1234"
}
~~~

The Comcast server will then find out the advertised capability of the
Webex trunk by doing a 
GET to https\://ripp.webex/trunks/abc/advertisement and using the
secret1234 as an authorization token. Webex supports the default values
but also support G.729 as an additional codec. It returns a JSON body of:

~~~ ascii-art
{
  "mic": {
    "id" : 0,
    "param-sets" : {
      "PCMU" : 1,
      "PCMA" : 1,
      "G729" : 1
    }
  }
  "spk" : {
    "id" : 1,
    "param-sets" : {
      "PCMU" : 1,
      "PCMA" : 1,
      "G729" : 1      
    }
  }
}
~~~

Similarly, the Webex server will find out the advertised capability of
the trunk by doing a GET to
https\://ripp.comcast.com/trunks/123/advertisement, using its OAuth
token. In this case, the response is empty, indicating that the
advertisement are all defaults.

At this point we are ready for inbound or outbound calls.

## Inbound Call

A PSTN calls arrives at Comcast that is routed to the this trunk via a
Comcast SBC that will convert it from SIP to RIPP. The SBC knows which
codecs the trunk supports (G.729 and G.711) and can immediately
send the SIP answer in a 183. It can then can make an HTTP post to the
consumer TG URI to set up the incoming call. This is done by doing
a POST to
"https\://ripp.webex/trunks/abc/calls?target=14085551212@e164.arpa &passport=PASSPORT_DATA"
using the authorization token "secret1234". This will return a new
call URI for this call of "https\://ripp.webex/call/xyz".

At this point the SBC can make a long poll GET and PUT to
"https\://ripp.webex/call/xyz/events" to receive and send signaling
events for
this call. The SBC will also open a number of media byways by
performing PUT and GET
requests to "https\://ripp.webex/call/xyz/media". 

The data from the "https\://ripp.webex/call/xyz/events" request will be
an infinite JSON array of Events. When the Webex server answers the
call, the event returned would look like:

~~~
{ "name":"accepted" }
~~~

## Outbound Call

For Webex to make it outbound call, it is the same as the inbound call
other than the provider trunk URI is used. The Webex server would act
as a client and do a HTTP POST to
"https\://ripp.comcast.com/trunks/123/calls?target=14085551212@e164.arpa
& passport=PASSPORT_DATA"
to create a call URI of "https\://ripp.comcast.com/call/c789". From
that point the flow is roughly the same as inbound with the client and
server roles reversed.

## End of call 

If the call is ended on the server side, server sends a terminated event
with the ended flag set to true then waits a small time for client to
close the connection then closes the connection.

If the call is ended on the client side, the client sends a terminated
event with the ended flag set to true and then closes the connection. In
either case the event looks like:

~~~
{ "name":"terminated", "ended": true }
~~~


# Normative Protocol Specification

This section contains the normative specification of RIPP.

## Discovery

A RIPP client that wishes to obtain an OAuth token to a specified
authority through a web interface MUST construct a well known RIPP
Oauth URI using [@draft-nottingham-rfc5785bis] with ripp-oauth as the
well-known service, and use this to trigger the Oauth process.

Similarly, a RIPP client wishing to access the resources defined in
this specification, against an authority (such as example.com) MUST
use [@draft-nottingham-rfc5785bis] with ripp as the well-known
service, and use this to trigger the Oauth process. The result is the
RIPP root URI for that authority.

## TG Retrieval

All clients MUST perform a GET query to the RIPP root API for an
authority they wish to connect to. Origin servers MUST provide a
resource at this URI. It MUST be constructed using the
JSON syntax described in (#syntax), and MUST have one or more provider
TG URI in the list. It is RECOMMENDED that the origin server specify
that this document can be cached. 

If the client receives a document and there is only one provider TG
URI, it uses this for subsequent outound calls to the provider. If
there is more than one, the client SHOULD request user input if it has
such a facility. If not, it SHOULD select the first.

At the end of this process, the client will have a provider TG URI.

## Consumer TG Registration

If a consumer also needs to receive inbound calls, it MUST register a
consumer TG. To do that, it MUST initiate an HTTPS PUT request towards
/consumertg on the provider TG URI. This request MUST be authenticated
by the origin server. The request MUST include a RIPP provisioning
object in the body. This object is specified in Section (#syntax).

The RIPP provisioning object MUST contain a consumer TG URI and
a bearer token. The consumer TG URI MUST be unique for each distinct
provider TG URI to which it is registered. This URI MUST support
HTTP/3, and MUST implement the /advertisements, /calls, /events and
/media resources and their associated behaviors. This URI MUST be
reachable by the provider. The URI MUST utilize HTTPS, and SHOULD
utilize a domain name for the authority component. It MAY utilize an
IP address, in which case the TLS certificate presented MUST be
self-signed. 

In addition, the RIPP consumer MUST mint a bearer token to be used by
the RIPP provider when performing operations against the RIPP Trunk
Client URI. The bearer token MAY be constructed in any way desired by
the RIPP consumer. The token and URI SHOULD remain valid for at least
one day, however, a security problem MAY cause them to be invalidated.
The RIPP consumer MUST refresh the provisioning against the
RIPP trunk at least one hour in advance of the expiration, in order to
ensure no calls are delayed. The token MUST be unique for each unique
provider TG. 

At this point, the RIPP trunk is provisioned. Both the RIPP provider
and RIPP consumer have a RIPP trunk URI and an Authorization token to
be used for placing calls in each direction.

## Advertisement Exchange

Prior to placing a call towards a TG, a client MUST have a
valid advertisement for it. If it has none, it MUST perform a GET on the
/advertisement resource on the provider TG URI. The origin server MUST
return a RIPP advertisement object as defined in Section (#syntax).

It is RECOMMENDED that the advertisement utilize HTTP caching. It is
RECOMMENDED that it be valid for one month. 

Once established, either side MAY update the advertisement by sending
an HTTP push to trigger its peer to fetch a fresh capability
document. Due to race conditions, it is possible that the client
may receive calls compliant to the old advertisement document for a
brief interval. It MUST be prepared for this.

Advertisements are bound to the TG, and are destroyed when the
TG is destroyed. 

In general, an entity MUST declare a capability for any characteristic
of a call which may result in the call being rejected. This
requirement facilitates prevention of call failures, along with clear
indications of why calls have failed when they do. For example, if a
provider provisions a TG without support for G.729, but
the consumer configures theirs to utilize this codec, this will be
known as a misconfiguration immediately. This enables validation of
TG misconfigurations in an automated fashion, without placing test
calls or calling customer support.

## Advertisement Format

An advertisement is a set of parameters, each of which is a name-value
pair. This specification defines several well-known names and
establishes an IANA registry for future extensions. Every capability
has a default, so that if no document is posted, or it is posted but a
specific capability is not included, the capability for the peer is
understood.

The following parameters are general purpose configuration:


* retry-backoff: In the event of a closure of the HTTP connection,
  this parameter specifies the initial time value to use before
  retrying the connection. If a retry fails again, the client will try
  again but this time wait twice the value of this timer, then four
  times, eight times, etc. The value of this parameter is an integer,
  in units of milliseconds. Its default is 2000.

* media-timeout: If a client fails to receive media ack packets after
  the timeout specified in this parameter, it considers the call dead
  and initiates migration. The value of this parameter is an integer,
  in units of milliseconds. Its default is 1000.

* server-ip: When present, this parameter indicates that the client
  should not utilize DNS to resolve the authority component of the
  associated TG URI, and rather, utilize the IP addresses which are
  the value of this parameter. The value is a JSON array with one or
  more elements. Each element contains an IP address and an load
  value. The load value MUST be between 0 and 100. The sum of the load
  values across all of the elements in the array MUST be 100. This
  parameter is optional. When omitted, the client MUST utilize normal
  DNS resolution for HTTP.

These parameters specify support for telephony features:

* hold: When present, indicates that the server supports clients
  performing a hold operation on calls. Its value is a boolean, with a
  default of FALSE. 

* transfer: When present, indicates that the server supports clients
  performing transfer operations on calls. Its value is a boolean, with a
  default of FALSE.

* park: When present, indicates that the server supports clients
  performing park and retrieve operation on calls. Its value is a
  boolean, with a default of FALSE.

* mute: When present, indicates that the server supports clients
  performing park and retrieve operation on calls. Its value is a
  boolean, with a default of FALSE.

Four parameters are defined for media capabilites - mic, spk, cam,
screen, corresponding to the ability to generate audio, receive audio,
generate video, and receive video. There MUST be one instance of these
parameters for each corresponding source and sink which can
simultaneously send or receive its media in a single call. Each
instance MUST have a unique id within the advertisement. Each instance
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


## Call Establishment

To initiate a call, a client MUST have a valid advertisement for the
TG against which it will place the call, and MUST know its own
advertisement for the TG which will initiate the call. The proposal
MUST be a valid advertisement JSON document, as specified in
(#syntax). 

The client MUST construct a proposal, which tells the server what
media to send. This proposal MUST include zero or more mic parameters,
and zero or more cam parameters, corresponding to the sources and
that the client wishes the server to send. These MUST be a subset of
those present in the advertisement from the peer. The client MUST
specify the values for any codec which are not the default. The value
for each parameter MUST be less than the value specified in the
advertisement from the peer, and also MUST be less than its own
maximum value from its own advertisement. If a selected value differs
from the default, it MUST be included in the proposal. The proposal
MUST include the "id" attribute for the source. This is crucial to
inform the peer which of its sources to send.

Similarly, the client chooses which of its sources will send, and to
which sinks on its peer it will send. It MUST NOT send media for which
there is not a corresponding sink on its peer which is a match for the
media type. It MUST send utilizing media parameters which are less
than the values specified in the advertisement in the peer for that
sink.

To place a call, the client performs a POST request to the peer TG
URI, using the /calls resource. This request MUST include the target
and passport URI parameters. The target parameter
MUST be of the form user@domain. If the target is a phone number on
the PSTN, this must take the form <e164>@e164.arpa, where <e164> is a
valid E.164 number. RIPP also supports private trunks, in which case
the it MUST take the form <number>@<domain>, where the number is a
non-E164 number scoped to be valid within the domain. This form MUST
NOT be used for E.164 numbers. Finally, RIPP can be used to place call
to application services - such as a recorder - in which case the
parameter would take the form of an RFC822 email address.

The passport URI parameter MUST be a valid passport as defined by
[@RFC8224]. It identifies the calling party and includes signature
information which can be used to verify it. If the client has no
official certificate proving ownership of the identity in the
passport, it MUST generate a self-signed certificate and use that. 

The server MAY authorize creation of the call using any criteria it so
desires. If it decides to create the call, the server MUST return a
201 Created response, and MUST include a Location header field
containing an HTTPS URI which identifies the call that has been
created. The call URI MUST be globally unique in time and space, with
randomness properties identical to a type 4 UUID. 

The server MAY include HTTP session cookies in the 201 response. The
client MUST support receipt of cookies [@RFC6265]. It MUST be prepared
to receive up to 10 cookies per call. The client MUST destroy all
cookies associated with a call, when the call has ended. Cookies MUST
NOT be larger the 5K. The 201 response MUST NOT contain a body. 

If the server cannot setup the call because the proposal is invalid or
the passport is invalid, it MUST generate a 400 response. If the
request is otherwise valid, but the target of the call cannot be
reached through the TG URI, it MUST generate a 404 response. If the
request is valid and the target can be reached, but the client is not
allowed to do so for policy reasons it MUST generate a 403 response.

## Signaling and Media Byway Establishment

If the server returns a 200 OK to the client, the client MUST
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
reverse signaling byways, in which case it MUST send all call events
on all open reverse signaling byways. A server MUST NOT
terminate the call if there are no signaling byways established;
rather it utilizes timeouts as described below.

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

accepted: Passed from server to client, indicating that the call was
accepted by the recipient. At this point, the call is considered
established. 

rejected: Passed from server to client, indicating that the call was
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

keepalive: This event is always initiated by the client. When received
by a server, the server MUST generate a keepalive response. The
keepalive MAY contain a nonce, and if so, the server MUST echo it in
the response. 

## Telephony Features

The following events are optional. They can be sent by either side of
a call, an generally apply only once a call is established. Each
feature has one side that invokes the feature, and another side which
handles it. The specification does not define how the handler handles
the feature, it only specifies behavior on the interface between
them. 

An originator MUST NOT invoke a feature unless the corresponding
feature support has been indicated in the advertisement on the TG.

### Blind Transfer

Performs a blind transfer of the call. The event contains a string
which MUST be a valid value for the target URI parameter used when
setting up a new call. Once the transfer has initiated, the server
MUST generate a transfer-reject event if it is unwilling to perform
the transfer. If it attempts the transfer, it MUST send a
transfer-pending event indicating that the transfer is in
progress. If the transfer target answers the call, the server MUST
generate a transfer-success event, followed by an end event,
indicating the call is over for this user. If the transfer fails, the
server MUST generate a transfer-failed event, in which case the call
continues. Once the transfer target answers, it MUST be sent a
transferred-from event, containing the URI of the call from which the
transfer happened.

### Warm Transfer

transfer-warm: performs a warm transfer. For this to work, the
endpoint sending the event must be in two calls. It sends this event
on the one to be transferred to the other. The event has a single
parameter which specifies the URI of the call to which the transfer is
taking place. This two calls MUST have the same authority component of
their call URI. Once the peer receives this event, it MUST perform the
transfer. The transfer will either complete almost immediately else
fail. If it succeeds, the peer MUST respond with a transfer-success
event; if it fails, respond with a transfer-failed event, in which
case the call continues. Furthermore, if the transfer succeeds, the
transfer target MUST be sent a transferred-from event, containing the
URI of the call from which the transfer happened.

### Hold and Resume

hold: performs a call hold on the call. Either side can initiate this,
but only if its peer indicates support. Similarly, to inform its peer
that it has been placed on hold, either side may send an on-hold event
to its peer, but only if hold has been indicated as a capability. When
an endpoint has been told it is on-hold, it MUST send silence for
audio and black screen for video. The peer MAY generate music-on-hold
or any other suitable content to render while the endpoint is on hold.

### Mute Indication

mute: informs the peer that it has muted. This is informative for UI
purposes, useful in conference calls for example. When an endpoint
mutes, in addition to sending the mute event, it MUST send silence for
audio and black screen for video. Similarly, if an endpoint wishes to
inform its peer that it is muting its media, it sends a mute event.

### Park and Retrieve

TBD

## Sending and Receiving Media

Media is always associated with a call. Within a call, media has a
direction (c2s or s2c) relative to call establishment. Within a
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

A server MUST maintain a timer, with a value equal to one second, for
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

If, and only if, the server has included the "server-ip" parameter in
its advertisement - meaning it is not utilzing an HTTP load balancer,
it MAY request the client to migrate the call to a named instance. The
named instance is specified by IP address as an optional parameter in
the migrate event. The client MUST verify that this IP is one of the
ones present list of server-ip.

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
in [@draft-nottingham-rfc5785bis] - ripp and ripp-oauth.

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
Zanaty for greatly simplifying the advertisement proposal for video. 

{backmatter}

