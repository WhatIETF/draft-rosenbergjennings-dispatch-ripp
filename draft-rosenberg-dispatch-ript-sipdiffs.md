%%%

Title = "Real Time Internet Peering for Telephony (RIPT) Comparison with the Session Initiaton Protocol (SIP)"
abbrev = "RIPT vs. SIP"
docName = "draft-rosenberg-dispatch-ript-sipdiffs-00"
category = "std"
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

%%%

.# Abstract

The Real-Time Internet Peering for Telephony (RIPT) protocol and its
extension for inbound calls to single user devices provide an
alternative to the Session Initiation Protocol (SIP) for several use
cases. This leads to many questions - how is RIPT different from SIP
and why? How much of SIP do those two specifications
replace? This document discusses the differences and their
motivations, and presents an analysis across the set of SIP
specifications, and analyzes whether the two RIPT documents replace
each with similar capability, whether they eliminate the need for that
specification, or whether some or all of that specification are not
addressed by RIPT.

{mainmatter}

# Introduction


The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119, BCP 14
[@RFC2119] and indicate requirement levels for compliant CoAP
implementations.

The Real-Time Internet Peering for Telephony (RIPT) protocol
[TODO ref I-D.rosenbergjennings-dispatch-ript] and its extension for inbound
calls to single user devices [TODO ref draft-rosenberg-dispatch-ript-inbound]
provide an alternative to the Session Initiation Protocol (SIP)
[@?RFC3261] for several use cases.

This leads to two important questions - how is RIPT different and why?
And,  how much of SIP do those two specifications replace? This
document answers the first question, and then presents an
analysis across the set of SIP specifications, and categorizes each
specification as one of three types:

1. the two RIPT documents replace the document in whole with similar
 capability (replaced)
2. the two RIPT documents eliminate the need for that specification
 without providing a similar capability (not-needed)
3. the two RIPT documents do not eliminate the need for the
 capabilities of that specification, in whole or in part. In such a
 case, a RIPT extension would be needed if this specification was
 desired as part of RIPT. (not-replaced)

# How is RIPT Different from SIPT?

This section covers the many design differences and why.

## Ontop of HTTP, not Alongside of HTTP

Perhaps the most important difference is that RIPT rides on top of
HTTP, instead of being similar to (but not the same as) HTTP. 

Though SIP was inspired by HTTP, it is not HTTP itself. SIP and HTTP
are peers - application protocols running ontop of the Internet. In the
intervening years, HTTP evolved to become a general purpose substrate
for delivering Internet applications. It is fair to say that today,
almost all applications users consume over the Internet run over
HTTP (with obvious exception of inter-server email - much client to
server email is also now run over HTTP).

This resulted - in essence - a rift between telecommunications
technologies and web technologies. Both had their own protocol stacks,
their own sets of products and services, and so on. HTTP has its own
set of load balancers, and SIP has different products which provide
load balancing for it. SIP applications have their techniques for HA,
and HTTP applications have theirs.

This rift has created two significant problems. First, it has become
increasingly difficult for SIP-based applications to be deployed into
modern cloud platforms, which are focused on web-based applications,
not SIP-based. SIP-based applications are often deployed to VM or bare
metal servers. It is difficult to implement HA, scale, security, and
so on in these environments. The second (and related) problem is that
SIP has not been able to take advantage of the significant innovations
that have taken place for building modern, large scale, reliable web
applications. SIP application providers must build their own load
balancing, HA, failover, clustering, security, and scaling
technologies, rather than using the capabilities of these cloud
platforms. SIP apps are nearly impossible to run on Kubernetes; they
cannot be built ontop of lambdas; they cannot sit behind global HTTP
load balancers; they dont use OAuth for authorization - and so on.

RIPT is an attempt to seal this rift by reunifying web and
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


HTTP2 [@?RFC7540] addressed the second of these with the introduction of pushes
and long running requests. However, its usage of TCP was still a
problem. This has finally been addressed with the arrival of QUIC
[@?I-D.ietf-quic-transport] and
HTTP/3. QUIC is based on UDP, and it introduces the concept of a stream
that can be set up with zero RTT. These streams are carried over UDP,
and though are still reliable, there is no head of line blocking
across streams. This change has made it possible for HTTP to support
real-time applications.

## State Lives in Servers, not on Clients

SIP was designed with the concept that call and media state would live
in clients at the edge, not on servers in the data center. When call
state lives on the edge, SIP systems were highly scalable and
extremely reliable. Failure of any server component did not drop calls
or even prevent future signaling operations from taking place.

However, this vision of SIP networks never came to pass. In practice,
SIP networks are full of state that resides in server intermediaries
(softswitches, IP PBXs, SBCs, and so on), and has seen media transmitted
through these intermediaries. Unfortunately, the SIP protocol did not
provide built-in mechanisms to achieve highly available calling in
this model. Failure of any server component would cause call drops. To
remedy this, many of these servers rely on layer 3
solutions (such as shared VIPs with proprietary state replication),
which are expensive, hard to deploy, and of limited scale. In other
cases, they are absent, in which case a server failure will cause all
calls to be dropped, requiring the end user themselves to re-initiate
the call.

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

Consequently, RIPT is designed from ground up with the notion that the
state lives on the server, not the client. It then includes the
capabilities needed to provide highly available calling, so that
failure of a server component does not drop the call or even cause
loss of media packets. 

## Configuration is Automatic, not Manual

The core SIP specification said nothing of configuration. Though
specifications were added later to cover some of it, they were not
widely implemented, and more important, not designed with automation
in mind.

This has manifested most painfully in enterprise to carrier SIP
trunking solutions, which have suffered from complex provisioning
operations, oftentimes requiring the exchange of static IPs and ports
and phone number ranges. This was followed by manual configuration of
call routing logic, selecting amongst trunk groups based on manually
configured rules which needed to change every time some property of
any trunk group changed. These operations are almost never
self-service and consequently, SIP trunk turn ups can take weeks on a
provider and additional weeks for configuration and testing on the
enterprise side.

RIPT includes - as a core part of the protocol - the protocol
exchanges needed to bootstrap a client (whether it be an IP phone or
enterprise SBC) from nothing but the domain name of its provider, to
fully functional interconnection, in a completely automated way. It
exchanges all of the information needed for automated routing logic,
capabilities discovery, and policy validation.

## Secure CallerID Only, not Insecure

Perhaps the biggest design mistake in SIP - which all of us who worked
on SIP surely feel badly about - has been its abuse for the injection
of robocalls. The core problem is the lack of authenticated (aka
secure) caller ID in SIP. SIP began with completely unverified
callerID in the form of the From header field, and specified nothing
about how servers should handle this field. Multiple specifications
over the years which followed attempted to remedy this
problem. Finally, the most recent work on STIR [@?RFC8224] brings hope
to solve the problem. However, SIP itself does not mandate STIR, and
SIP doesn't provide the automated configuration needed to ensure that
STIR can always be used for every call.

RIPT remedies this in several ways. First and foremost, the protoocl
provides one and only one way to identify the caller - a
passport. There is no separate unauthenticated identity which needs to
sometimes be ignored or replaced. A RIPT call always contains an
authenticated caller ID, on any hop, and there is no other way to
signal it.

Furthermore, RIPT provides a simple certificate exchange
which allows endpoints - such as an IP phone or browser client - which
authenticates using normal web techniques ala OAuth - to obtain a
certificate from its provider for the number that it has been
allocated. This means that RIPT does not depend on a server to act as
verifier for the callerID on a call by call basis and then take active
action to insert a passport. Instead, it requires the client to obtain
a certificate and insert a verified caller ID in the first place. This
reduces the computational burden from the servers, but far more
importantly, it means that RIPT does not depend on any kind of
processing of the call in order to ensure that the caller ID is
authentic. The caller ID is authentic and verified when the call is
made from the originating client all the way to the terminating one.

RIPT also provides the configuration needed in trunking scenarios for
authenticated caller ID. Entperprises receive configuration which
tells them exactly what numbers they are allowed to utilize to inject
calls. This means there are no surprises about whether a call from an
enterprise to a carrier will be accepted or rejected due to
verification processes. 

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


## HTTP Load Balancing, not DNS or SIP Proxies

Load balancing in SIP has been problematic from the start. It was
originally envisioned that clients would utilize DNS SRV records
[@?RFC3263] for load balancing. In practice, this suffered from two
major problems. Firstly, it made it difficult for service providers to
dynamically adjust the set of servers. This is due to highly
unpredictable and slow DNS propagation. Even using zero TTLs in DNS
records did not guarantee that the addition or removal of a server
would be immediately known to clients.

The second problem is that DNS records couldn't easily account rapid
detection of up/down state of the individual servers.

This became remedied later on with the addition of SIP proxies for
load balancing. DNS A records would point to the proxies, and the
proxies would use OPTIONS pigs to determine the up/down state of the
servers.

While this works OK in practice, it makess the SIP proxies a single
point of failure. It is difficult to scale them - they cannot utilize
anycast, since this is incompatible with SIP behavior. Meanwhile, HTTP
load balancing technology has evolved significantly, providing highly
scalable load balancing based on geographic proximity, anycast
routing, a variety of application layer health checks, and so on. None
of this load balancing technology can be used by SIP.

For this reason, there is no notion of load balancing in RIPT itself,
it is handled entirely by HTTP. 

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

Consequently, in order to reside within HTTP, RIPT follows the same
pattern and only concerns itself with client-server behaviours. Like
HTTP, a RIPT server can of course act as a RIPT client and further
connect calls to downstream elements. However, such behavior requires
no additional specification and is therefore not discussed by RIPT.

## Client-Server, not Agent-to-Agent

SIP is based fundamentally on the User Agent, and describes the
communications between a pair of user agents. Either user agent can
initiate requests towards the other. SIP defines the traditional role
of client and server as bound to a specific transaction.

HTTP does not operate this way. In HTTP, one entity is a client, and
the other is a server. There is no way for the server to send messages
asynchronously towards the client. HTTP/3 does enable two distinct
techniques that facilitate server messaging towards the client. But to
use them, RIPT must abide by HTTP/3 rules, and that means distinct
roles for clients and servers. Clients must always initiate
connections and send requests, not servers.

To handle this, RIPT specifies that the caller implements the RIPT
client, and the side receiving the calls is the RIPT server. For any
particular call, the roles of client and server do not change. To
facilitate calls in either direction, an entity can implement both RIPT
client and RIPT server roles. However, there is no relationship
between the two directions.

## Signaling and Media Together

One of the most fundamental design properties of SIP was the
separation of signalling and media. This was fundamental to the success
of SIP, since it enabled high quality, low latency media between
endpoints within of an enterprise or consumer VoIP service.

This design technique is quite hard to translate to HTTP, especially
when considering load balancing and scaling techniques. HTTP load
balancing is effective because it treats each request/response pair as
an independent action which can route to any number of backends. In
essence, the request/response transaction is atomic, and
consequentially RIPT needs to operate this way as well. 

Though SIP envisioned that signalling and media separation would also
apply to inter-domain calls, in practice this has not
happened. Inter-domain interconnect - including interconnection with
the PSTN - is done traditionally with SBCs which terminate and
re-originate media. Since this specification is targeted at
inter-domain peering cases, RIPT fundamentally combines signalling and
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
the degree it exists at all, is done with HTTP URIs. RIPT follows this
pattern. RIPT - as a web application that uses HTTP/3 - does not use or
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

Consequently, RIPT follows this same approach. The client initiates
calls towards the server. The server uses TLS to provide its identity
to the client, and the client provides a token to the server to
identify itself, with a login technique occuring elsewhere. To
facilitate bidirectional calls, an entity would just implement both
the server and client roles. For any one call, the entity placing the
call acts as the client, and the one receiving it, as the server. To
handle the common case where there is an asymmetric business
relationship (one entity being a customer of the other), RIPT
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

Because of the HBH nature of RIPT, security is done fundamentally at
the connection level - identically to HTTP. Since media is also
carrier over the HTTP connection, both signalling and media are covered
by the connection security provided by HTTP/3.

Because of the mandatory usage of TLS1.3 with HTTP/3, and the expected
widespread deployment of HTTP/3, running VoIP on top of HTTP/3 will bring
built-in encryption of media and signalling everywhere,
which is a notable improvement over the current deployment
situation. It is also necessary in order to utilize HTTP/3.

For reasons of interoperability, and to enable e2e media encryption in
several cross-company or inter-provider use cases, RIPT assumes each
media chunk may be encrypted, and if so, it contains a key ID which
dereferences the encryption keys, ciphers and other information needed
to decrypt the packet. The exchange of these keys and ciphers is done
entirely out of band of RIPT.

However, RIPT does not support SRTP. If a client receives a
SIP call with SRTP, it must terminate the SRTP and decrypt media
before sending it over RIPT. This matches existing practice in many
cases. 

## Calls Separate from Connections

In SIP, there is a fuzzy relationship between calls and
connections. In some cases, connection failures cause call
terminations, and vice a versa.

HTTP, on the other hand, very clearly separates the state of the
resource being manipulated, with the state of the HTTP connection used
to manipulate it. This design principle is inherited by
RIPT. Consequently, call state on both client and server exist
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
efficiently nor completely. To work with HTTP, RIPT must utilize the
HTTP approaches for these problems. Consequently, RIPT does not
utilize ICE and has no specific considerations for NAT traversal, as
these are handled by HTTP/3 itself.

## Load Balancer Stickiness, not Contact header field and RTP IPs

In SIP-based systems, it is desirable for an initial INVITE to be load
balanced across a farm of servers, but for subsequent SIP messages and
the media to go to the server which was selected by the load
balancer. In SIP, this is handled by usage of the Contact header field
for SIP and the RTP IP and ports for media. This technique is utterly
incompatible with HTTP load balancers, in addition to requiring a
large number of public IPs - one for each server. In HTTP systems, the
origin servers utilize private IPs only, and a small number (often
just one) public IP address is used.

This means that SIP systems cannot use HTTP load balancers, expose
public IPs of each server to the Internet (which is a no-no for modern
security), and consume public IP address space in order to
scale. Worse yet, failure of a server means that the client can no
longer reach the server and the call drops. 

RIPT utilizes HTTP, and therefore relies on HTTP based techniques -
most notably, stickiness. Most load balancers use a combination of
session cookies and hashes of the five-tuple in order to route
subsequent requests from the same client to the same server. But, if
that server has failed, requests can be routed to a different
server. Similarly, if the farm of servers expands elastically, new
requests get routed to the new servers but ones from existing clients
"stick". This provides a far better solution, and means that RIPT can
handle server failures gracefully. Clients just re-initiate their
requests and they get connected to a new server.

That said, media processing is far better when there is locality of
media. As a result, RIPT provides an additional primitive that allows
a server to explicitly move a call off of itself, or to a new
URI. This enables a variety of capabilities for optimization. 

# Can RIPP Really Replace SIP?

A great question! 

## Core Specifications

We first consider the core specifications - RFCs [@?RFC3261],
[@?RFC3262], [@?RFC3263], [@?RFC3264] and [@?RFC3265]. 


### The Main SIP Spec - RFC3261

There is a lot of content in this specification. The best way to
analyze it compared to RIPT is to examine each of the methods and
header fields, and consider the functionality provided by them.

The INVITE method is of course replaced by RIPT, as is the BYE
(through the ended event). Re-INVITE, though not a different method,
is also supported in RIPT, though only ever initiated by the server
with a new directive. Clients can move calls around by specifying the
usage of a different handler. CANCEL is replaced in  [TODO ref draft-rosenberg-dispatch-ript-inbound]
by broadcasting an event to all listeners informing them that the call
has been answered. The usage of CANCEL to end an unanswered call is
replaced by the ended event in RIPT. REGISTER is replaced by the
handler construct. ACK is not needed since RIPT is reliable.

OPTIONS - which never worked that well - is replace by the more robust
and complete TG construct, allowing the client the ability to discover
everything needed to interact with the services of a server. 

Considering header fields, interestingly, a large number of them are
focused on SIP routing features. These include Via, Route,
Record-Route, Contact. These are not needed in RIPT, since RIPT
focuses on a client to server construct. A server can, in turn,
re-initiate a request. However, in SIP parlance, it would be a B2BUA
and statefully know how to route return messages and forward requests
later for the same call. In such an architecture, it is not necessary
to stash routing state into protocol headers, which is what these
headers do.

The SIP content headers - Accept, Accept-Language, Content-Type,
Content-Length are provided by underlying HTTP.

The SIP identifiers - To, From, Call-ID and the branch parameter, are
replaced by the simpler single call URI which is the one and only
identifier for a call. This removes another piece of complexity from
SIP - the convoluted algorithm for identifying calls, transactions,
and call legs. The To and From exist in RIPT, but are replaced with
secure versions using passports. The CSeq header field is not needed
in RIPT since it utilizes reliable transport only, and this header
field was only needed for transaction ordering.

The SIP extensibility mechanisms - Require, Proxy-Require, Allow,
Supported, are not needed in RIPT. These headers are necessary due to
the symmetric nature of the relationship between entities. In RIPT,
the client uses the services of the server and cannot insist on
anything. The client can determine what services are supported through
normal JSON extensibility constructs - similar to SIP heeaders -
wherein unknown elements are ignored.

The SIP forking concept - another source of much complexity - is
eliminated in RIPT, and thus the logic in SIP associated with forking
processing is not needed. Note tht, RIPT does allow a user to have
multiple devices, and to make and receive calls on any of them. This
is accomplished by using the normal HTTP model wherein multiple
clients can manipulate the resources on the server.

Consequently, we believe that RIPT serves as a full replacement for
the entirety of [@RFC3261] and thus this specification is categorized
as "replaced". 

### RFC3262 - Reliability of Provisional Responses

This specification is not needed in RIPT. It was specified to handle
complexities with UDP-based signaling transport. RIPT only uses
reliable transport for signaling. This specification is therefore
categorized as "not-needed". 

### RFC3263 - DNS SRV for SIP

This specification is not needed in RIPT. DNS resolution is a function
of HTTP and provided by A and AAAA records, not SRV. The load
balancing properties of the SRV record never worked well, and are
replaced by the far more robust techniques used with HTTP. This
specification is therefore categorized as "not-needed".

### RFC3264 - Offer/Answer

This specification, more than any other, is the one people love to
hate. It has also proven incredibly robust, extended dramatically
beyond its humble origines. RIPT abandons the offer/answer model
entirely, favoring a model in which the server is always in
control. Consequently, it is replaced by an "advertisement/proposal"
model. At its core, offer/answer allowed clients to indicate their
capabilities and for media streams to be set up and configured. RIPT
provides this functionality, though differently. Consequently, this
specification is categorized as "replaced".

### RFC3265 - SIP Events

This specification provided a generic mechanism for clients to
subscribe to events and receive notifications for them. This
capability exists in RIPT using long-running GET to the /events
endpoint on any resource, and uses the lifecycle of the transaction to
manage the lifecycle of the subscription. Consequently, this
specification is categorized as "replaced".


## SIP Extensions

There are many SIP extensions, we do not consider all of
them. Extensions which are corrections to other specifications are not
considered. 3GPP specific extensions are not considered. Extensions
specific to SIMPLE are not considered, and in general, presence and IM
(which is out of scope for RIPT) is not considered. Generally,
informational and experimental specifications are not considered,
though there are some exceptions when they have effectively become
normative in nature. 

###  SIP INFO (RFC 2976)

TODO

###  UPDATE (RFC 3311)

TODO 

### Resource Management and SIP (RFC 3312)

TODO 

### Privacy Header (RFC 3323)

TODO 

### P-Asserted-ID (RFC 3325)

TODO 

### Reason header field (RFC 3326)

TODO 

### Service-Route (RFC 3327)

TODO 

### REFER (RFC 3515)

TODO 

### Symmetric Response Routing (RFC 3581)

TODO 

### Registration Event Package (RFC 3680)

TODO 

### Third Party Call Controll (RFC 3725)

TODO 

### E.164 and SIP (RFC 3824)

TODO 

### UA Capabilities (RFC 3840)

TODO 

### Caller Prefs (RFC 3841)

TODO 

### Replaces Header Field (RFC 3891)

TODO 

### Referred-By (RFC 3892)

TODO 

### PUBLISH method (RFC 3903)

TODO 

### Join Header Field (RFC 3911)

TODO 

### Early Media (RFC 3960)

TODO 

### Session Timers (RFC 4028)

TODO 

### INVITE Dialog Event Package (RFC 4235)

TODO 

### Request History (RFC 4244)

TODO 

### Actions for non-INVITE?? (RFC 4320)

TODO 

### Pre-Emption Events (RFC 4411)

TODO 

### Resource-Priority

TODO 

### Suppression of Implied REFER Subscription (RFC 4488)

TODO 

### Conveying Feature Tags (RFC 4508)

TODO 

### Request Auth?? (RFC 4538)

TODO 

### KPML (RFC 4730)

TODO 

### representing trunk groups (RFC 4904)

TODO 

### Connected Identity (RFC 4916)

TODO 

### Dial Strin (RFC 4967)

TODO 

### URN for emergency services (RFC 5031)

TODO 

### Rejecting Anonymous Requests (RFC 5079)

TODO 

### Real-Time Text (RFC 5194)

TODO 

### Answering Modes ?? (RFC 5373)

TODO 

### SIP Outbound (RFC 5626)

TODO 

### GRUU (RFC 5627)

TODO 

### App Interaction Framework (RFC 5629)

TODO 

### SIP Session Mobility (RFC 5621)

TODO 

### Diversion (RFC 5806)

TODO 

### Domain Certs (RFC 5922)

TODO 

### Connection Reuse (RFC 5923)

TODO 

### UA Config (RFC 6011)

TODO 

### Event Package for Call Quality (RFC 6035)

TODO 

### Certificate Management Service (RFC 6072)

TODO 

### SIP e2e performance metrics (RFC 6076)

TODO 

### UA Profile Delivery (RFC 6080)

TODO 

### INFO method Package and Framework (RFC 6086)

TODO 

### ANAT? (RFC 6135)

TODO 

### registration of multiple numbersin SIP (RFC 6140)

TODO 

### IPv6 Transition and SIP (RFC 6157)

TODO 

### Indication of Support for Keepalive (RFC 6223)

TODO 

### SIP Response for Indication of Terminated Dialog (RFC 6228)

TODO 

### Location Conveyance in SIP (RFC 6442)

TODO 

### Notification for Rate Control (RFC 6446)

TODO 

### Filtering Location Notifications (RFC 6447)

TODO 

### SIP specific event notification (RFC 6665)

TODO 

### Framework for Session Policy (RFC 6794)

TODO 

### SIP Events for Session Policy (RFC 6795)

TODO 

### UA Profile set for Media Policy (RFC 6796)

TODO 

### Completion of Calls (RFC 6910)

TODO 

### Fax over IP in SIP (RFC 6913)

TODO 

### Request History (RFC 7044)

TODO 

### SIP LOad Control Event Package (RFC 7200)

TODO 

### Session Identifier in SIP (RFC 7329)

TODO 

### Loop Detection in SIP (RFC 7332)

TODO 

### SIP Overload Control (RFC 7339)

TODO 

### Media Traceroute (RFC 7403)

TODO 

### SIP Rate Control (RFC 7415)

TODO 

### Transporting UU Information in SIP (RFC 7433)

TODO 

### URNs for Alert-Info (RFC 7462)

TODO 

### Shared Appearances for an AOR (RFC 7463)

TODO 

### SIPREC (RFC 7866)

TODO 

### E2E Session Identification (RFC 7989)

TODO 

### Response Code for Unwanted Calls (RFC 8197)

TODO 

### Authenticated Identity Management (RFC 8224)

TODO 

### Passport (RFC 8225)

TODO 

### STIR Certs (RFC 8226)

TODO 

### Content-ID (RFC 8262)

TODO 

### Negotiating Human Language (RFC 8373)

TODO 

### Passport for Resource Priority (RFC 8443)

TODO 

### Marking SIP messages to be logged (RFC 8497)

TODO 

### Push Notification and SIP (RFC 8599)

TODO 



## SDP Extensions

### Grouping of m-lines (RFC 3388)

TODO 

### Media Auth (RFC 3521)

TODO 

## NAT Traversal

### STUN (RFC 5389)

TODO 

### TURN (RFC 5766)

TODO 

### Indicating support for ICE in SDP (RFC 5768)

TODO 

### ICE (RFC 5245)

TODO 

### ANAT (RFC 4091)

TODO 

### TURN TCP (RFC 6062)

TODO 

### TCP candidates with ICE (RFC 6544)

TODO 


## RTP Extensions (excepting Payload Types)

TODO 

{backmatter}
