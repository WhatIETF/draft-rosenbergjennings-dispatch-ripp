%%%

#
# RIPT Inbound - real time internet peering for Single User Endpoints
#
# Generation tool chain:
#   mmark (https://github.com/miekg/mmark)
#   xml2rfc (http://xml2rfc.ietf.org/)
#


Title = "RealTime Internet Peering for Single User Endpoints"
abbrev = "RIPT Inbound"
category = "std"
docName = "draft-rosenberg-dispatch-ript-inbound-00"
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

The Real-Time Internet Peering for Telephony (RIPT)
protocol defines a technique for establishing, terminating and
otherwise managing calls between entities in differing administrative
domains. While it can be used for single user devices like an IP
phone, it requires the IP phone to have TLS certificates and be
publically reachable with a DNS record. This specification remedies
this by extending RIPP to enable clients to receive inbound calls
through their outbound connection to a server. It also provides
basic single-user features such as forking, call push and pull,
third-party call controls, and call appearances. It describes
techniques for resiliency of calls, especially for mobile clients with
spotty network connectivity.



{mainmatter}

# Introduction 

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in [@!RFC2119].

The Real-Time Internet Peering Protocol (RIPT) defines a technique for
establishing, terminating and otherwise managing calls between
entities. It is an application
ontop of HTTP/3, and as such has the notion of a client that opens
connections and makes requests to a server. In the core RIPT
specification, clients can only place outbound calls. Inbound calls
are supported by requiring an entity to also run a server. 

While this requirement is appropriate for use cases like SIP trunking,
carrier to carrier peering, or other arrangements involving a large
number of calls, it is a poor match for single user devices. A single
user device is one in which an actual end user would log in and use
that device for making and receiving calls. Exampes include desktop
softphones, browser based webRTC appications, IP hardphones, and video
conferencing endpoints. These devices are often behind a NAT, dont
have DNS names, and don't have TLS certificates, all of which are
pre-requisiites to run a server.

Furthermore, an end user may often be logged into multiple such
devices, possibly from multiple locations. This introduces additional
requirements. Inbound calls need to be forked to all devices, and ring
on all of them. A user must be able to answer on one, and stop ringing
on the others. SIP [@?RFC3261] natively supported these
capabilities. However, it lacked other ones which are clearly needed -
native support for mobile-based apps which utilize push notifications
is one significant example.

SIP's lack of call state in servers as a built-in feature of the
protocol has also meant it couldn't readily support other features
truly needed for a system where a user can be logged into multiple
devices. These include the ability for one device to see the state of
the call, and know on which other device the call is being
handled. Another important feature includes the ability to - from any
device - end the call, move it to a different device, or on the device
the user is sitting on. It also includes basic third party call
controls - the ability to initiate or answer a call from one client,
but have the media delivered to another.

To remedy these challenges this specification provides an
extension to RIPT to facilitate multi-user devices. 


# Overview of Operation

The actual protocol enhancement to RIPT is small. The primary one is
enabling a server to inform the client of an inbound call, and to add
additional events and supported event directions. The second one is
additional behaviors required of clients around handlers.

To signal usage of this specification, the server includes a new
element, "inbound", in its TG description. The format of this element
is identical to what it would look like to receive calls on a TG that
would have been hosted by the single-user device, had it been able to
do so. For example, the following TG describes a single user TG which
can handle both outbound and inbound calls:

~~~ ascii-art
{
  "outbound": {
    "origins" : "+14085551002",
    "destinations" : "*"
  },
  "inbound": {
    "destinations" : "+14085551002",
    "origins" : "*"
  }
}  
~~~

The client will follow RIPT procedures for handler registration. This
is analagous to the SIP REGISTER operation. For server to server
peering arrangements, the handler represents a particular collection
of capabilities on an SBC or IP PBX. When used by single-user devices, it
represents each individual device. Consequently, if a user has four IP
phones, there would be four handlers created on the server. As
specified in RIPT each client needs to remember its handler URI
persistently in order to modify it or delete it later on.

Unlike SIP, wherein a client frequently refreshes its registrtion
because it is soft-state, a RIPT client doesn't do this. Handlers are
not soft-state, they are hard-state. Think of handlers like an
inventory of a user's devices, solely for the purpose of an end user
selecting amongst them when making or answering a call. As such, a
server might delete one after extended inactivity (say, one
month). But this is not necessary except to improve the user
experience by eliminating old devices when a device list is too long.

Unlike SIP-outbound, receipt on inbound calls doesnt rely on a client
having a persistent connection to receive a call. RIPT does require a
persistent connection for timely delivery of call events, but it does
not have a functional dependency on it. For example, consider a client
which lost its connection to the server for a few seconds, perhaps due
to a fade-out in wireless connectivity. If an incoming call arrives at
precisely that moment, the client wont receive its event. However,
upon recovery of network connectivity, the client re-establishes its
connection to the /events resource on the TG, performs the long-lived
GET for events, receives an event about the calls in progress,
including a new one that it is not aware of. This event includes the
URI for the call. It queries the server, learns about the call, sees
its state is "proceeding" and direction is "inbound". This tells the
client to render the incoming call dialog. It can then answer and
proceed with the call as normal. Indeed, the client can be out of
network connectivity for as long as the caller is willing to wait for
the call to be answered. This makes RIPT quite resilient to wireless
network hiccups, network handoffs, and other network challenges which
have become commonplace.

In a similar way, the highly stateful nature of the RIPT server means
that RIPT is also more resilient to mid-call drops in connectivity. A
client which loses its network connectivity will, of course, fail to
receive media, and its peer won't receive any either. To explicitly
inform users of this, this specification introduces a new event,
"reconnecting", which informs the client that its peer - which can be
RIPT or SIP-based - has lost connectivity and reconnect is in
progress. There is also a "reconnected" event that is sent to indicate
reconnection. A server can determine when to send this based on any
policy it so desires. It is used by the client solely for UI
purposes. It encourages the end user to wait rather than hanging
up. This allows the remote user to recover their network connectivity,
or perhaps pull the call to another device. So, for example, a user
might be on their call on mobile, lose connectivity when entering
their home. They go to their wired PC, which will know about the call,
and be able to hit a "pull call here" button or similar, and proceed
with the call.
  
The support of inbound calls on the TG means that the client can learn
about incoming calls by performing a GET to the /events resource on
the TG URI, as described in the core RIPT specification. This
specification adds a new event, "call", which includes, as a
parameter, the URI for the call that is now available to the
client. The server will generate this event for both inbound and
outbound calls, allowing any client that is retrieving these events to
know about new calls.

In order to receive inbound calls continuously, the client maintains
its long-lived GET request to the /events resource. Of course, the
client can learn about a new call through other means, such as through
mobile push notifications. These need only deliver the call URI to the
client, who can then query it and proceed from there.

Once the client learns of this new call, it performs a GET on the call
URI. This will provide the client with the call direction (in this
case, inbound), calling party, destination number and most recent
event (in this case, proceeding). This allows the client to render UI.

With call state fetched, the client follows the procedures defined in
RIPT, and establishes the signaling and media byways as normal. Once
it starts alerting the user, it generates an "alerting" event towards
the server. If it wishes to accept the call, it generates an
"answered" event towards the server. The "answered" event, when sent
by the client, includes a handler URI, which specifies the device on
which the client would like the media to be rendered. Normally this
will be itself.

However, the client can specify a different handler. Any authorized
client can learn about the handlers for the TG by querying the
/handlers endpoint, which returns a list of them. The client can then
iterate through them and request their details. It can also receive
updates to the set of handlers using the /events resource on the
TG. Specifying a different handler enables third-party call control
operations. The image, device nickname and other attributes on the
handler allow an end user to usefully select the device on which to
receive the audio and/or video.

In the case where, for example, a user answers a call and specifies a
handler different from itself, the device associated with that handler
needs to know about this. It will learn about this through its
signaling byway to the call. It will see an "answered" event for a
call, and then an "attaching" event with the handler URI. When the
client sees that the handler URI is itself, this tells it that it must
render media. To do so, it queries the call URI, which will return to
it the directive to use. It also begins to accept media from the
server.

# Example Use Cases

This section outlines example use cases that are enabled by this
specification. It is not normative in nature. It merely describes how
the new API features defined by this specification can be used by
clients to deal with these cases.

## Inbound Call Forking

TODO

## Answer and Stop Ringing Other Devices

TODO

## Remote in Use

## Call Pull

## Call Push

## Select Device

## Third Party Call Control Place Outbound

## Third Party Call Control Answer or Decline Inbound

## Third Party Call Control  Hangup

## Third Party Call Control  Move Call

## Resiliency Miss Incoming call

## Resiliency MidCall Network Change

## Resiliency MidCall Wireless Fade and Recover

## Resiliency MidCall Wireless Fade and Move

## Resiliency MidCall Wireless Fade and Peer Hangup

## Resiliency MidCall Wireless Fade and Server Drop

# Normative Protocol Specification

A server that supports inbound calls on its TG MUST include the
"inbound" element in its TG description. This MUST include the allowed
caller IDs in the "origins" element, and the allowed destinations in
the "destinations".

When a server receives a new inbound call, or places a new outbound
call, it MUST send the "call" event to any clients which have a GET
query in progress to its TG. This event MUST include the call URI
associated with the call that the server is aware of. The server can
also utilize push notifications or other techniques outside the scope
of this speification to alert clients to new calls.

The server MUST allow the client to send a "proceeding", "alerting",
"answered", "declined", "failed", "noanswer" and "end" events, and
take the associated actions on the call.

A client that answers a call MUST include, as an attribute to the
"answered" event, the handler that is to be used for the call. This
handler MUST be active and registered to the TG against which the call
was received. The server MUST verify this, and if it is not, generate
a "handler-invalid" event, with the handler URI from the request as a
parameter. In this case, the server MUST NOT consider the call
answered. If the handler URI was valid, the server MUST construct a
directive per the procedures defined in the core RIPT
specification. It MUST then generate an "attaching" event to all
listeners, and MUST include the handler URI. It MUST also generate the
"answered" event.
  
When a client that had sent an "answered" event receives a
"handler-invalid" event including the URI it had generated, it SHOULD
refresh its list of handlers, inform the user of the answer failure,
and request the user to try again. If the client receives an
"attaching" event, and the handler specified matches its own, it
SHOULD query the call URI to obtain the directive OPEN ISSUE: Not
sure I like this, vs. having the client do a POST and have the server
construct the directive then. Thinking. It MUST initiate signaling
and media byways for the call, render incoming media and generate
outgoing media for the call. Once the client has sent and received at
least one media packet, indicating a successful connection, it MUST
generate a "handler-connected" event, including the URI of its
handler. As will all call events, this is sent to all listeners. This
allows for a reliable handshake for answering calls elsewhere.
  

Similarly, a client MAY, when creating a call, specify a handler in
the POST to create the call which is different than itself. When it
does that, it follows the procedures defined in the previous paragraph
as well.

A server MAY send, at its own discretion, a "reconnecting" event if it
believes the remote side has lost connectivity. It is RECOMMENDED that
the server send this event once it has ceased to receive inbound media
packets for five seconds. Similarly, a server MUST send a subsequent
"reconnected" event once media begins to flow once more. If a server
receives a new GET request against the /events resource on the call,
it MUST include the "reconnecting" event if it had sent one recently
but not yet sent the "reconnected event. This allows a client to
obtain the full state of the call when retrieving events.
  
# Syntax

This specification outlines the syntax for the new events and TG
description. 


# IANA Considerations

No values are assigned in this document, no registries are created,
and there is no action assigned to the IANA by this document. 


# Security Considerations

TODO

# Acknowledgements

Thanks to Cullen Jennings for his input on this document.

{backmatter}


