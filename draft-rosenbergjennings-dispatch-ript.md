%%%

#
# RIPT - real time internet peering for Telephony
#
# Generation tool chain:
#   mmark (https://github.com/miekg/mmark)
#   xml2rfc (http://xml2rfc.ietf.org/)
#


Title = "RealTime Internet Peering for Telephony"
abbrev = "RIPT"
category = "std"
docName = "draft-rosenbergjennings-dispatch-ript-00"
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


This document specifies the Realtime Internet Peering for Telephony
(RIPT) protocol. RIPT is used to provide peering of voice and video
communications between entities. These include a
traditional voice trunking provider (such as a telco), and a trunking
consumer (such as an enterprise PBX or contact center), or between a
video conferencing endpoint deployed in an enterprise, and a video
conferencing SaaS service. RIPT is an alternative to SIP, SDP and RTP
for these use cases, and is designed as a web application using
HTTP/3. Using HTTP/3 allows implementors to build their applications
on top of cloud platforms, such as AWS, Azure and Google Cloud, all of
which are heavily focused on HTTP based services. RIPT also addresses
many of the challenges of traditional SIP-based peering. It supports
modern techniques for load balancing, autoscaling, call-preserving
failover, graceful call migrations, security by default, STIR-based
caller ID, provisioning, and capabilities - all of which have been
challenges with traditional SIP peering and voice trunking. Since it
runs over HTTP/3, it works through NATs and firewalls with the same
ease as HTTP does.


{mainmatter}

# Introduction 

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in [@!RFC2119].

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

None of these capabilities can be used by real-time applications based
on the Session Initiation Protocol (SIP) [@?RFC3261], since SIP is not
an HTTP-based protocol. The newest HTTP specification - HTTP/3
[@!I-D.ietf-quic-http] - utilizes QUIC [@?I-D.ietf-quic-transport],
which runs on top of UDP. This means that it is now possible to
utilize HTTP for real-time media and call control together.

This document proposes a new protocol for performing basic call
control and media processing as an HTTP application. 

# Structure of this Document

The document is broadly split into two parts - explanatory and
normative materials. The explanatory text is non-normative, and
contains no [@!RFC2119] language. Much of this text is meant to help
readers familiar with SIP, understand how SIP concepts translate (or
don't) into RIPT. These sections include Requirements (#req),
Terminology (#terminology), Reference 
Architecture (#refarch), and Deployment Examples (#deployments). The
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
used in cloud platforms, without any special consideration for RIPT -
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



# Terminology {#terminology}

This specification follows the terminology of HTTP/3, but adds the
following concepts:

Client: An entity which implements the rules of the client defined in
this specification. A RIPP client always acts as an HTTP client.

Server: An entity which implements the rules of a server as defined in
this specification. A RIPP server always acts as an HTTP server.

Terminal Group (TG): A container for calls between a client and
server. A TG is identified by a URI, hosted on the server. A TG acts
as a unit of policy and capabilities, including alowed phone numbers.
The acronym is a nod to its circuit switched predecessor,
the Trunk Group. It exists to facilitate automated configuration of
call routing and avoid call failures due to mismatched capabilities.

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
RIPT provides a facility for this.

Provider: The administrative entity that provides communications
services to the customer. 

Byway: A bidirectional byte stream between a client and server. A
byway passes its data through HTTP, using a set of techniques which
depend on the capabilities of both sides and the use cases for which
they are needed. This specification considers two types - a signaling
byway and a media byway.

Handler: A handler is a "device" - an SBC, a phone, an IP PBX - and
can be a software or hardware entity which sends and receives media
associated with a call. A handler has a description, which includes
its advertisement, which defines its media capabilities.  The handler
can change during a call (as in the case of a client failing and its
calls being picked up by a backup).

Advertisement: A document which describes a set of semi-static
capabilities for sending and receiving audio and video with different
codecs, along with constraints such as maximum resolution or frame
rates. An advertisement is semi-static in that it does not change from
call to call, and is rather a property of the software or hardware
system, which changes normally only upon upgrade or configuration
change. 

Directive: The directive is an instruction on how media should be
sent. It is communicated from the server, which tells a handler where
it should send media to for this call.


# Reference Architecture {#refarch}


RIPT is also designed such that all communications between the RIPT
client - which is just an HTTP client - and the RIPT server - which is
just an HTTP server - can easily sit behind a typical HTTP load
balancer, as shown below:


~~~ ascii-art
                                           +------------+ 
                                           |            | 
                                           |  RIPT      | 
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
| RIPT       |     |  HTTP   |/            |  RIPT      | 
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
                                        \  |  RIPT      |    
                                         > |  Server    |    
                                           |            |    
                                           |            |    
                                           +------------+

~~~

The customer and provider role is asymmetric. Typically the customer
has purchased services from the provider. From a protocol perspective,
RIPT assumes that the customer has an account with the provider, and
it is possible for the customer to obtain an OAuth token which can be
used to authenticate. However, there is no login technqiue which
enables the provider to obtain a token to place calls towards the
customer.

Since calls always originate from client to server, in order to
receive inbound calls, a customer can also run a RIPT server. RIPT
supports a simple registration mecahnism by which the customer -
acting as a client - can use RIPT to register its
TG URI with the provider.  This registration also includes a bearer
token for authorization.

It is anticipated that an entity implementing the server role will use
a load balancer to receive incoming requests to place calls. This is
not required, of course. However, this specification provides no
facility for a customer implementing only the client role to receive
inbound calls. It is worth restating that this load balancer is NOT
specific to RIPT - it is any off-the-shelf HTTP load balancer which
supports HTTP/3. No specific support for RIPT is required. RIPT is
just an application ontop of HTTP.

Because RIPT clients and servers are nothing more than HTTP/3
applications, the behavior or RIPT is specified entirely by describing
how various RIPT procedures map to the core HTTP/3 primitives available
to applications - opening connections, closing connections, sending
requests and responses, receiving requests and responses, and setting
header fields and bodies. That's it.

# Web Resource Model

The web resource model for RIPT is based on the interplay between three
key resources held by the server. These are the TG, the handler, and
the call.

The TG is a representation of the service offered by the server to the
client. It indicates the allowed directions for calls (in this
specification, outbound only), the allowed identities that can be used
for caller ID, the allowed numbers which can be called, and the set of
advertised media capabilities for the service. The purpose of the TG
is to provide the client all of the information it needs to know, in
advance, whether the placement of a call is within the allowed policy
scope of the server. It is also meant to automate configuration,
providing information which is manually entered today. It also
facilitates call routing, enabling a client to know where to route
calls, and minimizes call failures by providing information up front
about whether a call may be rejected.

To ensure authenticated caller ID everywhere, the TG specifies the set
of allowed caller IDs through an [@!RFC8226] certificate. This not
only informs the client about what numbers it can originate with, it
also proves to the client that it is capable of vouching for those
numbers. 

For example, a telco might offer an enterprise customer a service in
which it can place calls to any number in the world, but it must use
one of the 100 numbers that have been assigned to it as the caller
ID. The TG object - literally a JSON document returned by the server -
also called he representation of the TG - would provide this
information to the client.

In the case of a trunking use case where an enterprise customer is
implementing the server and client roles, the enterprise, acting as
client, can inform the provider of its own TGs through a simple TG
registration. Consequently, the RIPT protocol allows a server to
accept TG registrations from a client. Typically, when an enterprise
acts as a client and registers its own TGs to the provider's server,
those TGs do not accept registrations. In other words, the provider
(e.g., Verizon) would not register TGs with the enterprise, even
though the enterprise supports the RIPT server role.

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
handler would change. A handler has an advertisement, which is a
description of its media capabilities (media types and codecs). 

Of course, a single physical device might be represented logically by
one or more handlers; the mapping of a piece of software or hardware
to a set of handlers is a matter of local implementation.

The client registers its handler with the TG. If a client receives
services from multiple TGs, it would register that handler to multiple
TG. 

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

RIPT enables communications between a pair of entities, which could be
in different companies or providers. This enables its usage in many
use cases where there are bilateral relationships requiring real-time
communications. This section contains several use cases which are
target use cases for deployment of RIPT.

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
prone. This section discusses how RIPT can make such configuration as
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

No further configuration or setup is required. Using RIPT, the IP PBX
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
as traditional SS7. This is accomplished in RIPT by having both telcos
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
would be modeled as a call to number at domain, where the number is the meeting
number used for the meeting. Using the domain, the video endpoint
would construct the RIPT root URI and then query to discover the
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

The basic operation of RIPT is broken into several steps - bootstrap,
login, provider TG discovery, customer TG registration, handler
registration, call establishment, and media exchange.

## Bootstrap

Bootstrap is the process by which a client starts with just the
domain name of the server - such as five9.com or comcast.net or
cisco.com - and uses that to discover the two URI which may be needed
to do everything else.

One of these URI is a URI which can be used to kickoff a web-based
OAuth flow for generating an OAuth token. The other is the RIPT root
URI. Both of these are well-known URI as defined by
[@!I-D.nottingham-rfc5785bis]. Consequently, they are constructed
using the syntax defined in [@!I-D.nottingham-rfc5785bis].

Their IANA registrations can be found in (#iana).

For example, for comcast.net, the RIPT OAuth URI is
https://comcast.net/.well-known/ript-oauth, and the RIPT root URI is
https://comcast.net/.well-known/ript. 

## Login

Login is the process by which an OAuth token is delivered to the
client. This step is performed only when the client role is being
played by the customer. If the client role is being player by the
provider, this step is skipped.

When login is done, it is always done through some technique outside
of the scope of RIPT. If the use case is to be done where the user is
in front of a browser, the application can direct the user to visit
the OAuth page learned from the discovery process above.

## TG Discovery

The client needs to figure out the set of TG which are available to
it. There may be cases where the server is offering the
client more than one. For example, a telco might offer an enterprise
an international TG which is used to place calls to non-US numbers,
and a domestic TG which is used for domestic calls. 

To obtain the list, the client queries the /providertgs resource on
the well-known RIPT root URI:

https://example.com/.well-known/ript/v1/providertgs

this URI will return the list of TG available to the client. This
list has, for each, the TG URI and a name and description in prose,
meant for a troubleshooting. The client would normally select a TG
automatically on a call by call basis based on local policy. For
example, if the server provides three TGs, one for receiving calls to
international numbers and one for domestic numbers, the client would
choose the TG based on whether a call it wishes to make is towards an
international or domestic number.

An example TG supporting outbound dialing from a 2-line IP PBX to
domestic numbers might look like this:

~~~ ascii-art
{
  "outbound": {
    "origins" : (RFC 8226 cert with "+14085551000" and "+14085551002"),
    "destinations" : "+1*",
  }
}  
~~~

An enterprise trunk allowing outbound calls to any number worldwide,
using one of the 1000 numbers assigned to that enterprise, might look
like this:

~~~ ascii-art
{
  "outbound": {
    "origins" : (RFC 8226 cert with "+14085551*"),
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
incoming calls, it will need to implement the server role of RIPT. Its
customer TG needs to be registered with the server. To do this, it
performs a POST to the /customertgs resource on the RIPT root URI, and
sets two parameters - its own URI, and a bearer token used for
authorization of inbound requests.

The customer TG URI has to be reachable by the server in order for the
it to receive calls, and for security purposes it must also support
TLS and present a valid domain certificate using the same trust chains
configured into browsers. This specification envisions an extension
which allows a client to receive calls without requiring it to run an
HTTP server, thus allowing for it to run behind a NAT and not have a
certificate.

An example of a customer TG registration might be this:

~~~ ascii-art
POST https://comcast.net/.well-known/ript/v1/customertgs
{
  "outbound": {
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
terms of service may not allow that, and it would reject the
request. Also note how the origins field is absent - this is because
the enterprise will accept inbound calls with any callerID. 

A success esponse to this would be a 201 Created, with the TG which
was created: 

~~~ ascii-art
{

  "uri" : "https://comcast.net/.well-known/ript/v1/customertgs/12345",

  "outbound": {
    "destinations" : "+14085551*"
  }
}  
~~~

The client can use the /consumertgs to modify this later (with a PUT
to the URI in the "uri" parameter), DELETE it, or create another.

The server holds onto the consumer TG URI, until such time as the
consumer is no longer receiving service from the provider.  


## Handler Registration

The handler is a representation of a device. Each device has a set of
capabilities that can be used when placing a call, which are contained
in its advertisement. The handler description is a
semi-static declaration which contains the advertisement along with other
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
modifications at a later date (via PUT), or DELETE it. The handler
registration is not soft state, there is no need for the client to
refresh it. The server would typically delete this registration when
the customer ends its service with the provider. 

The advertisement has a list of media sources and sinks that the
endpoint has, and an ID for each which monotonically increases from
0. Furthermore, each source and sink is of a particular type - audio
or video. An advertisement can contain more than one of each. The case
of PSTN gateways or traditional voice-only phones is simple - they
have a single source for audio and a single sink for audio, This is
true for a PSTN gateway regardless of its capacity. In other words, if
a PSTN gateway has a circuit switched line card with 100 ports, its
advertisement still has just one source and one sink.

A three-screen telepresence system might have three sinks for video,
three sources for audio, three sources for video, and three sinks for
audio, and represents the opposite end of the spectrum in terms of
complexity.

For each source or sink, there are one or more parameter sets that can
be specified. Each parameter in the parameter set has a name and a
value. The value is always an integer from - 2**63 +1 to 2**63 -
1. Parameters are typically standardized and registered with IANA. The
registration indicates the meaning of the values - their units and
allowed values. Most importantly, the parameter is always expressed in
a way where the value represents a maximum of some sort. This enables
booleans (where the maximum is 1), integral ranges (where the maximum
is a large-ish integer), or ordered enums (where the enum values
correspond to integers in order). When a parameter is not specified,
it takes on a default. Similarly, if the advertisement
is not present, the default can be assumed for all parameters.

Codec support is signaled using boolean parameters, with names that
match the media subtypes defined in the IANA protocol registry for
media types [@!RFC4855].

An IP phone with a single microphone and speaker that support G.711 and
opus might create its handler thusly: 

~~~ ascii-art
POST https://comcast.net/.well-known/ript/v1/providertgs/123/handlers
{

  "handler-id": "982akca99283",
  "advertisement" : {
    "source": {
      "id" : 0,
      "media" : "audio",
      "param-sets" : {
        "opus" : 1,
        "PCMU" : 1,
        "PCMA" : 1
      }
    },
  
    "sink" : {
      "id" : 1,
      "media" : "audio",
      "param-sets" : {
        "opus" : 1,
        "PCMU" : 1,
        "PCMA" : 1
      }
    }
 }
}
~~~

and the reply would be:

~~~ ascii-art
201 Created

{


  "uri":"https://comcast.net/.well-known/ript/v1/providertgs/123/handlers/abc",

  "handler-id": "982akca99283",
  "advertisement" : {
    "source": {
      "id" : 0,
      "media" : "audio",
      "param-sets" : {
        "opus" : 1,
        "PCMU" : 1,
        "PCMA" : 1
      }
    },
  
    "sink" : {
      "id" : 1,
      "media" : "audio",
      "param-sets" : {
        "opus" : 1,
        "PCMU" : 1,
        "PCMA" : 1
      }
    }
 }

}
~~~

Notice how the server as added the "uri" parameter. The "handler-id"
is client-specified and allows for correlation across different TGs
for the same handler. 

A device with a camera that could support H.264 at 4K and av1 at 1080p
might have an advertisement that looked like: 

~~~ ascii-art
"source": {
   "media": "video",
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

A video phone that could support opus and H.264 at 720p @ 30 fps might 
have an advertisement which looks like:

~~~ ascii-art
{

 "source": {
    "media": "audio",
    "id" : 0,
    "param-sets" : {
      "opus" : 1,
      "PCMU" : 1,
     }
  }
  "sink" : {
    "media":"audio",
    "id" : 1,
    "param-sets" : {
      "opus" : 1,
     }
  }
  "source":  {
    "media": "video",
    "id" : 2,
    "param-sets" : {
      "H264" : 1,
      "max-width" : 1280,
      "max-height" : 720
      "max-fps" : 30
    }
  }
  "sink":  {
    "media": "video",
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

## Obtaining Certificates

In order to place an outbound call, a client must have a certificate
which is valid and attests to the number that is to be used. In order
to enable that, RIPT requires that a client obtain a passport for each
number it wishes to place a call from.

To do that, the server provides a "/cert" resource on the TG. The
client can perform a POST to this resource, and the request would
contain a CSR. The CSR describes an [@!RFC8226] certificate which is
valid for a single phone number - the one the client wishes to use for
a call. This request is, as with all others, authorized with the
OAuth token. If the holder of the token is permitted to utilize that
number in phone calls, the server generates a certificate and returns
the certificate in the POST response. These certificates can last as
long as the server desires. This means that acquisition of such
certificates can be done in advance of the call, and regardless of
when they are acquired, can be cached for subsequent use.

In the case of a mobile phone as the RIPP client (for example), it
would learn its own mobile number from the TG, construct a CSR for
that number, and request the server to create a certificate that it
would cache until it expires.

An important benefit of this approach is that the server can use the
passport itself as the technqiue to authenticate the client as defined
in [@?RFC8224], and merely pass on the passport provided by the client
rather than generating one. This avoids the computational cost of
creating a signature, and also means that secure caller ID is provided
by default, without requiring active action on behalf of the
server. If the server does nothing, the call still has a valid
passport.


## Call Establishment {#directive}

The client can initiate calls by POSTing
to /calls on the TG URI.  The request contains:

1. the target phone number or email address (TODO: need to define
normalization procedures),
2. A passport [@!RFC8225] identifying the calling identity,
3. The handler URI from which the call is being placed,

in the body.

For example, to place a call to a phone number from the handler above:

~~~ ascii-art
POST "https://comcast.net/.well-known/ript/v1/providertgs/123/calls
{
  "handler": "https://comcast.net/.well-known/ript/v1/prov
     idertgs/123/handlers/abc",
  "destination": "+14089529999",
  "passport": "{passport encoding}"
}
~~~

The server takes the advertisement from the client's handler, takes
its own advertisement (which it has never exchanged, but merely
knows), and figures out what it will send, and what the client must
send. It then constructs a two directives - the client directive
indicating what the client must send, and the server directive which
describes what it will send. The directives have the similar syntax as
the handler descriptions. They contain a set of streams, each with a
source and a sink. For the client directive, the source specifies one
of the sources in the client handler, and the sink specifies a sink on
the server. It is the inverse for the server directive. For For each
stream, there is one parameter set, and for each parameter, the value
indicates what must be sent. Each directive is always specified in a
way that makes the value of each parameter less than the maximum value
between the advertisements from the client and server.

The server places the call, and returns the call description back to
the client. The call description includes the directives along with
core meta-data about the call - directionality, handler, caller,
callee and a URI for the call. The server directive does not need to
be known by the client, and it is not processed in any way. It is
included only for diagnostic and troubleshooting purposes:

~~~ ascii-art
201 Created

{

  "uri" :
  "https://comcast.net/.well-known/ript/v1/providertgs/123/calls/987",
  "destination": "+14089529999",
  "passport": "{passport encoding}"
  "direction": "outbound",
  "handler": "https://comcast.net/.well-known/ript/v1/prov
           idertgs/123/handlers/abc",

  "directives": {
 
   "client": 
    {
     "stream": {
       "source": {
          "id": 0
       },
       "sink" : {
         "id": 1
      }
      "param-sets" : {
        "opus" : 1,
        "PCMU" : 0
       }
     }
    "stream": {
      "source": {
          "id": 2
      },
      "sink": {
         "id": 2
      }
     "param-sets" : {
       "H264" : 1,
       "max-width" : 1280,
       "max-height" : 720
       "max-fps" : 30
     }
   }
  },
  "server": 
    {
     "stream": {
       "source": {
          "id": 0
       },
       "sink" : {
         "id": 1
      }

      "param-sets" : {
        "opus" : 1,
        "PCMU" : 0
       }
     }
 }
}
~~~

Note how the client and server directives are both for Opus. Also note
how the server directive has a single stream for audio only. This lets
the client know that no video is coming. However, clients are always
prepared to receive media for any sink they've specified in their
advertisement. 

In the (unlikely) case that this directive cannot be followed (due,
perhaps to a unexpected change in capabilities as a result of a GPU or
CPU spike), the client updates its handler with updated
capabilities. To tell the server to create a new proposal for the
call, it performs a POST against the existing call URI, this time
without parameters, and the server will respond with an updated call
description, including the new directive. 

Another important consequence of this design is that media packets
must be self-describing, without any kind of reference to a specific
call. This is because the directive is constructed from the
handler descriptions only, and the handler descriptions are semi-static. This
means RIPT does not use dynamic payload types to identify codecs.

Once a call has been created, a pair of long-lived HTTP transactions
is initiated from the client to the server for purposes of signalling
(this only happens if the call was created successfully and the
directive could be followed). One is a GET to the /events resource on
the call URI, retrieving call events from the server. The other is a
PUT to the same /events URI, used by the cient to send call events to
its peer. The combination of these two is called the signalling
byway. HTTP/3 ensures zero RTT for setup of these transactions.

Signaling commands are encoded into the signalling byway using
streaming JSON in both directions. Each JSON object encodes an event
and its parameters. A set of events common to all deployments of RIPT
are defined for proceeding, alerting, answered, declined, ended,
migrate, moved, ping, and pong. An additional set are defined targeted at
server to server cases, such as SIP trunking and inter-server
peering. These include transfer-and-takeback.

## Media Exchange

Media exchange makes use of webtransport over HTTP3
[@!I-D.vvv-webtransport-http3] when it is available, falling back to
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
transactions. TODO: need to tune this and justify its value. In
addition, the client will include an acknowledgement media chunk along
with its next media chunk in a PUT request. 

The use of acknowledgements provides the ability for clients and
servers to elect to retransmit media as well as to generate detailed
statistics on packet loss and delay on a packet-by-packet basis. 
Consequently, the equivalent of RTCP sender and receiver
reports are not needed.

## Graceful Migration

RIPT provides a simple technique for allowing a call to
gracefully migrate from one client instance to another on a different
host, or from one server instance to another on a different host. The
client always performs the migration action. It can be instructed by
the server to do so via a migrate event. Or, it can decide to do so
on its own. 

In the first case, there is a traditional HTTP load balancer fronting
a farm of HTTP origin servers, and the goal is to move the call to any
one of the available instances behind the load balancer. A server can
request this in order to shed load. Or, it can request this because it
has been instructed to shut down and restart, perhaps to perform a
software upgrade, or to migrate its docker container to another
node. It is assumed that some kind of shared database is used to store
any state that needs to be passed between origin servers. RIPT is
designed such that the only state which needs to be stored is call
state, and not media state.

In this use case, if the origin server handling the call does not
desire to receive new calls (including the one it is about to
migrate), it would be removed from the pool of available servers in
the load balancer. The means for this is outside the scope of this
specification. Then, the origin server sends a migration event to the
client. No additional attributes are provided in the event. 

Alternatively, the server may wish to migrate the call to a specific
instance amongst those in the cluster. One exampe of that is to move
calls from specific users or domains to specific hosts for reason of
isolation. There are many other reasons. In this case, the event from
the server will contain a URI which replaces the existing call URI,
since it has a different authority component. 

Either way, the receipt of this event will cause the client to end its
current signaling and media transactions. It then initiates new
transactions for signaling (the GET and PUT to /events), and media
(the GET and PUTs to /media), targeting the URI for the call or the
replacement URI for the call if the server provided one in the migrate
event. Crucially, these new requests do NOT contain any session
cookies. This means that the HTTP load balancer will send the new
request to one of the available origin servers, which will no longer
include the one which is being brought down for maintenance. The
responses will contain session cookies in order to enable sticky
session routing for subsequent requests for this call.

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
and media byways to the existing call URI it already has, or the new
one that replaces it.

## Non-Graceful Migration

RIPT is also designed to handle failures of clients, servers and
network connectivity issues, and to reconnect calls with a minimum of
disruption. It does this by providing implementors with tools to
enable such resiliency, without being overly prescriptive on exactly
how it is implemented. 

The asymmetric nature of RIPT means that it is always the
responsibility of the client to recover from
network failures and failures of a downstream server or load
balancer. 

The first failure case is that of a closure of the actual HTTP
connection, either gracefully or non-gracefully. In this case, the
client retries the connection with an exponential backoff, the backoff
timer being another parameter which can be specified in the TG. Once
the connection is re-established, it initiates the signaling and media
byways, and will reuse any session cookies it had previously received.

RIPT also requires clients to send keepalive signaling events
periodically for each call, and the server responds to these
events. If the client ceases to receive the server keepalives for a certain
duration (a value again that has a default but which can be tuned in
the TG description), it treats this identically to a request for a
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
established. If the downstream entity is a RIPT server, the TG URI,
call URI, selected IP address (from either DNS or using the IP in the
advertiseent), and session cookie are stored. These facilitate
reconnection to the same downstream instance.

In inter-company peering arrangements, such as enterprise voice
trunking or inter-carrier NNI voice peering, both sides will typically
have a cluster of software agents (VMs, docker containers, bare-metal
servers, dedicated hardware products, or whatever) acting as both clients and
servers. Consequently, we need to consider what happens to the client
transactions when these fail.

In such a case, failure recovery is always delegated to the upstream
client. In this case, let us assume that the client had this cluster
of agents at its perimeter. It would be receiving calls from some
further upstream elements. If those elements were using RIPT, it would
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

This allows a chain of RIPT clients and servers in back-to-back
configuration to recover from failures of any intermediate element
without dropping calls. Furthermore, failure detection and recovery
are rapid, especially when using load balancers. When an origin server
fails, the client can still reuse its connection to the load balancer,
such that connection establishment is not needed. Indeed, the time to
recover from failure is only 1/2 RTT between client and server,
once the client has detected the downstream failure.

Of course, the downstream element may be SIP-based and not RIPT. In
such a case, INVITE with Replaces is a good solution, and vendors of
highly reliable SIP gear are encouraged to support it. 

# Normative Protocol Specification

This section contains the normative specification of RIPT.

## Bootstrapping

A RIPT client that wishes to obtain an OAuth token to a specified
authority through a web interface MUST construct a well known RIPT
Oauth URI using [@!I-D.nottingham-rfc5785bis] with ript-oauth as the
well-known service, and use this to trigger the Oauth process.

Similarly, a RIPT client wishing to access the resources defined in
this specification, against an authority (such as example.com) MUST
use [@!I-D.nottingham-rfc5785bis} with ript as the well-known
service. The result is the RIPT root URI for that authority.

## TG Discovery

All clients MUST perform a GET query to the /providertgs on RIPT root
API for an authority they wish to connect to. Origin servers MUST
provide a resource at this URI. It MUST be constructed using the JSON
syntax described in (#syntax), and MUST have one or more TG URI
in the list. It is RECOMMENDED that the origin server specify that
this document can be cached.

If the client receives a document and there is only one TG
URI, it uses this for subsequent outound calls to the server. If there
is more than one, the client can use any algorithm and policy it
desires to choose the target TG for any call. 

At the end of this process, the client will have a TG URI. It MUST
retrieve the value of this URI, and use it to process calls. 

## TG Construction

When a server (either for the consumer or the provider) retrieves a
GET aginst the a valid TG URI, it MUST return a document with a set of
parameters. 

The document MUST contain an "outbound" element. The "origins" field
specifies the permitted caller ID values which can be present in the
passport used in a call setup towards this TG. If the server will act
as an authentication service as defined in [@?RFC8224], it MUST
include a value for this parameter. When present, it MUST be an
[@!RFC8226] certificate, whose TelephoneNumberRange indicates the
numbers which the server can vouch for. In cases where the server is
not acting as the authentication service, the "origins" field MUST be
absent. This would be the case in inter-carrier peering links, or in a
consumer TG registered to the provider.

The "destinations" field
specifies the allowed targets for calls. The server MUST include this
element if it will reject a call based on policy for a specific
destination. The default is "*" meaning the TG will accept any calls.

In addition, the TG URI contains a set of configuration values. If
absent, these take their default. The following are defined:


* retry-backoff: In the event of a closure of the HTTP connection,
  this parameter specifies the initial time value to use before
  retrying the connection. If a retry fails again, the client will try
  again but this time wait twice the value of this timer, then four
  times, eight times, etc. The value of this parameter is an integer,
  in units of milliseconds. Its default is 2000, and the client MUST
  NOT honor values less than 2000, rounding up to 2000 instead.

* media-timeout: If a client fails to receive media ack packets after
  the timeout specified in this parameter, it considers the call dead
  and initiates migration. The value of this parameter is an integer,
  in units of milliseconds. Its default is 5000.


OPEN ISSUE: Need to consider realistic ways to incrementally introduce
this into carrier networks without requiring massive forklifts of new
load balancers, anycast and so on.

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

The destinations parameter in the consumer TG description MAY be
included. If it is included, the destinations MUST be a subet of the
addresses present in the certificate found in the origins element in
the provider TG description. Since a consumer does not act as an
authentication service as specified in [@?RFC8224], the origins
parameter MUST be omitted.


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


## Handler Description Format

An handler description has a "handler-id", which is a unique
identifier for the handler on the client, and then an
advertisement. 

The advertisement is a set of parameters, each of which is a
name-value pair. This specification defines several well-known names
and establishes an IANA registry for future extensions. Every
capability has a default, so that if it is not included in the
advertisement, the capability for the peer is understood.

Two parameters are defined for media capabilites - "source" and
"sink", which specify the ability to send an receive media
respectively, along with a "media" parameter which indicates the type
- "audio" or "video". There MUST be one "source" and "sink" instance
for each corresponding source and sink which can simultaneously send
or receive its media in a single call. Each instance MUST have a
unique id within the advertisement. Each instance MUST include
one or more param-sets. Each param-set is a set of parameters. Each
parameter MUST specify the maximum that the sink can receive, or
source can send, for that parameter. A client or server MUST include a
parameter and its value when it differs from the default, and SHOULD
NOT include it when it matches the default.

This specification defines the following parameters for audio:

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

This specification defines the following parameters for video:

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
  is 1. (Open issue 2 times or 4 times)

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

All RIPT implementations MUST support G.711 and Opus audio codecs. All
implementations MUST support [@!RFC2833] for DTMF, and MUST support
[@!RFC3389] for comfort noise, for both sending and receiving.

In general, an entity MUST declare a capability for any characteristic
of a call which may result in a proposal being unacceptable to the
client. This requirement facilitates prevention of call failures.


## Certificate Enrollment

Prior to placing a call, a client MUST have a valid [@!RFC8226]
certificate which has a subject field that contains the phone number
or email address from which the call  is to be placed. 

A server acting as an authenticator as defined in [@?RFC8224] MUST
implement the "/certs" sub-resource of its TG. A client wishing to
obtain a certificate can perform a POST operation to this
resource. The body MUST contain a valid CSR. The server MUST validate
the CSR is valid, and MUST validate that the phone number or email
address that is requested, is amongst ones that the server is willing
to vouch for. It MUST generate a certificate and return it in the 200
OK response to the request. 

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
request whose target does not so match.  RIPT also supports private
trunks, in which case the destination MUST take the form
`<number>@<domain>`, where the number is a non-E164 number scoped to be
valid within the domain. This form MUST NOT be used for E.164 numbers.

The passport URI parameter MUST be a valid passport as defined by
[@!RFC8224]. It identifies the calling party and includes signature
information which can be used to verify it. The caller ID and called
party values in the passport MUST be within the allowed values defined
in the "origins" and "destinations" parameters of the TG,
respectively.

The server MAY authorize creation of the call using any criteria it so
desires. If it decides to create the call, the server MUST return a
201 Created response, and MUST include a Location header field
containing an HTTPS URI which identifies the call that has been
created. The call URI MUST contain a UUID. 

The server MUST construct a client directive, which tells the client what
media to send. This directive MUST include zero or more stream
elements, each of which MUST specify a source on the handler specified
by the client, and a sink on the server.  The server MUST
specify the values for any codec which are not the default. The value
for each parameter MUST be less than the value specified in the
handler description from the client, and also MUST be less than its own
maximum value from its own handler description. If a selected value differs
from the default, it MUST be included in the directive. 

Similarly, the server chooses which of its sources will send, and to
which sinks on its peer it will send. It MUST NOT send media for which
there is not a corresponding sink on its peer which is a match for the
media type. It MUST send utilizing media parameters which are less
than the values specified in the handler description in the peer for that
sink. It MUST codify this into a server directive describing what it
will actually send. 

The server MUST include the client directive in the body of the 201 response,
MUST include the URI for the handler that was used, MUST include the
call direction, MUST include the from and to participants, and
MUST include its own server directive.

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
URI. The media byways are
required before call answer to support early media. For any call, a
server MUST support up to 30 reverse media byways open. 

## Basic Call State Management

The server always maintains definitive state for the call. The basic
state of the call is manipulated through events passed from one side
to another. 

This specification defines the following events which MUST be
implemented by all RIPT client and servers: These events are
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
event MAY contain an URI which replaces the current call URI, thus
indicating the destination to which the media and signaling
byways will be established.

ping: This event is always initiated by the client. When received
by a server, the server MUST generate a pong response. The
ping MAY contain a nonce, and if so, the server MUST echo it in
the pong

The client can obtain the current state of the call at any time by
querying the call URI. The server MUST return a call description which
includes the client and server directives, call direction, calling and
called parties, and the handler which is being used. This aspect of
RIPT is essential for allowing clients to fail, recover, and re-obtain
the state of the call.

When a server has a signaling event to send, and there are multiple
GET requests open for /events, the server MUST send the event on all
such open requests. This enables seamless migration. Similarly, the
server MUST be prepared to receive events on multiple distinct PUT
transactions, and process them in the order in which they are received
by the server. 

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


Each ript media chunk has an outer envelope that is not encrypted,
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

The media sent by the client MUST match the client directive received from the
server. 

### Server Media Handling

If the HTTP connection supports webtransport, media chunks MUST be sent
(and received) as datagrams over the webtrasport session.

If not, to send media, the server MUST select an open GET request to
/media. The server MUST select the most recent, in order to enable
migration of media streams from one client to another. The
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
the body of the PUT requests. Note that these may actually originate
from different clients during migration events; this is irrelevant to
server processing of media. 

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


## Graceful Call Migration

A server MAY initiate a call migration at any time for a specific
call. To do so, it MUST send a migration event to the client over the
signaling byway. The client MUST honor this request for migration. The
client MAY choose to migrate the call to a different server at any
time.

To perform the migration, the client MUST end all outstanding HTTP
transactions for the call (signaling and media byways). If the server
provided a URI in the migrate event, the client MUST treat this as a
new URI for the call, replacing the prior one. Then, It MUST
initiate a new signaling byway towards the call URI. This may
require the client to open a new HTTP connection, if it does not
already have one open to the target. The client MUST NOT include a
session cookie in the PUT to /events. This is essential to cause the
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
(move to SIP document)

RIPT is designed to be easy to gateway from SIP. The expectation is
that RIPT will be implemented in SBCs and softswitches. A SIP to RIPT
gateway has to be call-stateful, acting as a B2BUA, in order to
gateway to RIPT. Furthermore, a SIP to RIPT gateway has to act as a
media termination point in SIP. It has to perform any SRTP decryption
and encryption, and it must de-packetize RTP packets to extract their
timestamps, sequence numbers, and codec types.

SIP to RIPT gateways are not transparent. SIP header fields which are
unknown or do not map to RIPT functionality as described here, gets
discarded.

Any configuration and provisioning for RIPT happens ahead of receipt
or transmission of SIP calls. Consequently, the logic described here
applies at the point that a gateway receives a SIP INVITE on the SIP
side, or receives a POST to the RIPT trunk URI on the RIPT side.

This specification does define some normative procedures for the
gateway function in order to maximize interoperability. 


## RIPT to SIP

## SIP to RIPT


# RAML API {#syntax}

TODO - add in RAML

# IANA Considerations {#iana}

## Registration of Well-Known Web Services

This specification defines two new well-known web services as defined
in [@!I-D.nottingham-rfc5785bis] - ript and ript-oauth.

## RIPT

URI suffix: ript

Change controller:  IETF

Specification document(s): This specification.

Status:  Permanent.

## RIPT-Oauth

URI suffix: ript-oauth

Change controller:  IETF

Specification document(s): This specification.

Status:  Permanent.


# IANA Considerations


# Security Considerations


# Acknowledgements

Thanks you for review and edits to: Giacomo Vacca. Thank you to Mo
Zanaty for greatly simplifying the advertisement  proposal for video. 


{backmatter}





