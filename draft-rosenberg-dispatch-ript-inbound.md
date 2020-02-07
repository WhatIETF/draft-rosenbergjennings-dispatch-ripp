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

The Real-Time Internet Peering for Telephony (RIPT) protocol defines a
technique for establishing, terminating and otherwise managing calls
between entities in differing administrative domains. While it can be
used for single user devices like an IP phone, it requires the IP
phone to have TLS certificates and be publically reachable with a DNS
record. This specification remedies this by extending RIPP to enable
clients to receive inbound calls.  It also provides basic single-user
features such as forking, call push and pull, third-party call
controls, and call appearances. It describes techniques for resiliency
of calls, especially for mobile clients with spotty network
connectivity.



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
extension to RIPT to facilitate single-user devices. 


# Differences with SIP Outbound

This specification covers a similar problem space as SIP Outboud
[@?RFC5626], however it works much differently.

Firstly, delivery of an inbound call to an IP phone in a timely
fashion clearly requires the IP phone to be able to have some kind of
persistent connection over which it can receive incoming call
indications. In SIP Outbound, the specification itself provided this
capability. This specification, however, does not. Rather, it assumes
that it merely exists, and is provided through some non-standardied
means, which we refer to as a "push channel".

For mobile devices, the push channel is provided by the mobile OS. For
browser applications, it might be provided by a websocket connection
that the application is using to receive a variety of events,
including those having nothing to do with calling.

The push channel is also used to provide an indication of feature
invocations to the client when those features are invoked elsewhere
(ie., third party call control). The specific feature names and other
UI elements are out of scope for this spceification as well. Rather,
this specification only shows how, once a client knows it needs
perform a call manipulation, it can use RIPT to do it.

The second significant difference compared to SIP Outbound is that
RIPT does not use the push channel to push actual protocol messages;
rather it uses it as a "shoulder tap" to let the client know about a
new event, and provide it a URI with which it can get more
information or take action.

# Overview of Operation

To signal usage of this specification, the server includes a new
element, "inbound", in its TG description. The format of this element
is identical to what it would look like to receive calls on a TG that
would have been hosted by the single-user device, had it been able to
do so. For example, the following TG describes a single user TG which
can handle both outbound and inbound calls:

~~~ ascii-art
{
  "outbound": {
    "origins" : (encoded passport)
    "destinations" : "*"
  },
  "inbound": {
    "destinations" : "+14085551002",
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

If an incoming call arrives for the client, the server creates the
call, including the call URI, and the push channel is used to inform
the client of a new call, and provide it with the call URI. The client
performs a GET against this URI to obtain the information about the
call. As defined in the core RIPT specification, this will provide the
client with the calling and caller party identifiers, call direction
(here, inbound), and the client directive. The client can then alert
the user, and in parallel establish the signaling and media
byways. The client can send the proceeding, alerting, answered,
or declined events to the server to adjust the state of the call. Once
answered, the call is active and processing proceeds identically to
the case where it had placed an outbound call.

Multi-device handling follows from the fact that the server will
broadcast all call events to all open GET requests to /events on the
call. As such, if there are multiple IP phones, each of which
receives a push notification of the new call, all of them will perform
a GET on the call URI, establish signaling and media byways, and then
alert the user. Once the user answers on one device, the call state
changes to answered and this event is sent to the other devices, which
can cease ringing. Furthermore, the other devices can follow the state
of the call by maintaining a GET to /events, even though they are not
sending or receiving media.

Since other devices can track the state of the call, they can render
it while the call is ongoing - providing basic 'shared call
appearance' functionality.

The movement of calls between different devices is learned through a
new event defined here, the "handler changed" event, which is sent by
the server. Its payload is the URI of the new handler. 

The core RIPT specification also provides a simple way for one device
to take a call from another - by using a client-side migration. The
device which wishes to take the call would POST to the call URI,
changing the handler to itself. It would get a new,  modified
directive, and then connect its media byways to begin sending and
receiving media.

These basic primitives can be used in concert with
application-specific (and non-standardized) user interface and push
channel contents to accomplish many different functions.


# Example Use Cases

This section outlines example use cases that are enabled by this
specification. It is not normative in nature. It merely describes how
the new API features defined by this specification can be used by
clients to deal with these cases.

## Inbound Call Forking

Consider two devices - A and B. A single user, Alice, logs into both
devices. These devices query the provider, and through the techniques
described in RIPT, get the TG for the service provided to Alice and
register their respective handlers. Furthermore, assume that device A
only supports G.711 and Opus, while device B supports both Opus,
G.711, and G.729.

When a new call arrives for Alice, the server would create a call URI,
and use the push channel to inform both devices that a new call has
arrived. The push notification would inform the IP Phones of the call
URI. Both phones perform a GET against the call URI, which returns the
caller and called numbers, call direction, and current state - which
is proceeding. Since the clients see that this call has not yet been
answered, both of them render UI and begin alerting. Both will also
open signaling byways to the call URI and PUT "proceeding" and then
"alerting" events. The server will in turn, echo the "alerting" events
back to all clients which are receiving events on the byway, since the
state of the call has changed to "alerting".

This achieves the basic forking operation.

## Answer and Stop Ringing Other Devices

Consider now that user Alice answers on device A. This will cause
device A to send an "answered" event to the server. In parallel, it
will perform a POST to the call URI and provide its handler URI in
the body. The response includes the directive for the call. This
allows the server to know that device A doesnt support G.729, and thus
it directs device A to send with G.711. Furthemore, the server would
send the "answered" event to all other clients which have an open
signaling byway, which in this case is phone B. It will receive the
"answered" event and thus cease ringing.

Note that - had IP phone B receive the original push notification
late, if it should query the call URI after the call has been
answered, it would see that the state is answered and thus not
ring. Because the server maintais state, it is resilient to
intermittent client connectivity. 

## Remote in Use

Consider further now what happens with device B. The call is being
handled on device A. However, device B maintains its signaling
byway. As a result, it will see the the call remains live. If that
call should end, the client would receive the "ended" event from the
server, and therefore be able to show that the call is no longer
active.

Additionally, if the service provider offers advanced telephony
features such as "hold" or "transfer", those state changes could be
delivered to device B via the push-channel. Similarly, the client
could query - using web APIs beyond the scope of this specification -
to learn about states like "on-hold". (OPEN ISSUE: this does seem a
bit wonky that RIPP is used for the basic call state, but a separate
web API is needed if the state is something like "on-hold".)

## Call Pull

Consider now that IP phone B wishes to take over the call. This is
called "call pull".

To do that, it performs a client migration. It POSTS to the call URI
its own handler. The server sees that this new handler supports G.729,
so it returns a directive to the client telling it to send with
G.729. Device A would receive a notification on the signaling byway
that the handler has changed to device B, and thus it knows that a
migration has happened and it should close its media byway. (NOTE:
need to consider race conditions). 

## Call Push

In the push case, the user on device A wishes to move the call to
device B. The user is in front of device A, and not device B. To
perform the move, it uses its UI, obtains the list of devices which
are available from the server, and asks the server to move the call to
device B. The means by which this happens are not standardized here,
and assume the existence of a browser function in the client which can
render the UI for features such as this.

When the server wants to move the call to device B, it sends it a push
on the push channel and tells it to take the call, along with the call
URI. Device B then performs the client migration, identically to the
pull case above. 

## Select Device

As part of the call push operation, the user on device A will need to
obtain the list of devices to which it can push the call. This
specification assumes that this is provided through non-standardized
means, by virtue of the phone having a browser which allows it to see
the set of devices and select one. 

## Third Party Call Control - Place Outbound

In a similar way, this specification allows a device to be controlled
by third party call control. A user would visit a web page, enter in a
number to call, and click the "call" button. This capability does not
require standardization. The RIPT server would create
an outbound call object, and then perform a push notification to both
devices with the call URI. Both devices would query the call URI, and
see that there is a new call happening, in the outbound direction,
with the state of proceeding. The call state would also indicate the
caller (here, user Alice herself) and the called party - the number
dialed by Alice.

Both phones could alert Alice to the outbound call in progress. When
Alice selets the device on which to proceed, this would cause that
device to perform a POST to the call URI to set itself as the handler,
and then establish media and signaling byways. This would also trigger
the server to actually place the call towards the destination.

This technique for third party call control is superior to the one
described in [@?RFC3725]. Firstly, the calling and called party
numbers are properly represented and will render correctly on the
devices. This is because we're not actually placing a call towards
ALice's phone - we're informing Alice of an outbound call placed from
another location. Secondly, the technique allows the phone to render
proper UI - that this is not an inbound call, that it is an outbound
call to be taken. Call progress can also be properly rendered,
including locally generated ringback.

In this use case, the outbound call was picked up by Alice by
'forking' the outbound call notification to all of her devices. The
service provider could, alternatively, allow Alice to choose a
specific device for placing the outbound call. In that case, the
server would send an indication to just that device, over the push
channel, telling it to connect to the call URI. 

## Third Party Call Control Answer or Decline Inbound

Another third party call control use case is that of an inbound call
which rings user devices, and a user would like to accept the call
from a webpage or other client, distinct from the device on which the
call is to actually be answered.

This capability is not possible with the mechanism defined in
[@?RFC3725].

This is possible with RIPT. The webpage would render the incoming call
notification to the user (again, no standardization is needed for
this, it is all just a browser application). The user would see
information on the incoming caller, select the device on which to
answer, and then hit an answer button. The server would then send a
push notification to the selceted device, with an instruction to
answer the call. The IP phone would then perform the POST operation to
the call URI, including its handler in the body, and accept the call
with the "answered" event.


## Third Party Call Control  Hangup

To hangup the call, once again Alice is in front of her browser, and
is able to see the call in the browser UI, and see that the call is
being handled by device A. Alice clicks the 'hangup' button on her
browser. The server changes the state of the call by sending an
"ended" event to all devices which have a signaling byway open (which,
in this case, would be both devices A and B). Device A would cease
rendering media and disconnect its signaling and media byways for the
call. Device B, which had remote-in-use, would remove the
remote-in-use indication from the UI.

TODO: should add meta-data to the ended event, indicating who ended
the event, to drive better UI and also deal with call drops


## Third Party Call Control  Move Call

In this use case, Alice is once again at her PC on her browser. She is
on a call which is rendering media on device A, and wishes to move the
call to device B. Using the browser UI, she instructs the server to do
so. The server would send a push notification to device B, asking it
to take the call. Device B would then POST its handler to the call
URI, open the media byways, and take the call, identically to the pull
use case above.

## Resiliency Miss Incoming call

Consider now user Alice that has a mobile app with a RIPT client in
it. Alice was driving in her car. At the very moment the server sends
a push notification, Alice's device loses network coverage and the
push notification is lost.

When Alice exits the tunnel a few moments later, the application gets
notified that network connectivity has ben restored (note: i dont
believe this is actually provided in mobile OS today, it would require
a change perhaps to enable it). The application can then perform a
query to the server to get its current calls, using techniques outside
of the scope of this spceification. Once it learns the call URI, it
can query the call state and then render the call as alerting.


## Resiliency MidCall Network Change

Consider a case where user Alice is on her mobile device, and on a
call. While she is on the call, she moves from her cellular network
into her home, and her device switches to WiFi.

When this happens, the VoIP application on the mobile device receives
a notification from the OS that there has been a network change. Note
that - since RIPT doesnt use IP addresses at all - there is no need to
're-REGISTER', or in fact to 're-INVITE'. The client just continues
doing what it was doing - performing GETs on /media to receive media
packets, and PUTs on /media to send them. In fact, the client need not
even explicitly listen for network change events. It just continues
sending and receiving media as before.

The change in IP will cause the signaling byways to end. The client
just re-establises them and continues where it was. RIPT requires a
client and server to buffer a small amount of media for cases where
the media byways are temporarily disconnected. In cases where there is
no network connectivity during the transition, the buffered packets
are sent in a burst. In this way, there is no loss of media through
the transition. 

## Resiliency MidCall Wireless Fade and Recover

Consider a similar case, where user Alice is on her mobile device, and on a
call. While she is on the call, she moves into a tunnel, and network
connectivity is lost for a few seconds.

The PUT and GET requests against the server for the media byway will
fail, and the signaling byway will possibly timeout or return an
error. The IP phone just buffers the media content being spoken by the
user. Similarly, the server will be buffering the media it
receives. When the connection is restored, the media byways will be
re-established, and the server will quickly push the buffered media to
the client and vice-a-versa. This allows the call to continue, with no
loss of media, within the depths of the jitter buffer. 


## Resiliency MidCall Wireless Fade and Move

In a similar use case, Alice is on her mobile phone in a call and goes
to her house. She is one of those unfortunate few who have no cell
signal in her house, nor does she have WiFi on her cell phone. Poor
Alice.

When Alice enters her home, the network connectivity on her mobile
phone is lost. However, her PC is up and running, so she logs into her
service provider's portal from the browser. This shows the call in
progress. Alice can hit the "move" button, which will cause the
browser to take the call, identically to the technqiues described
above. 

## Resiliency MidCall Wireless Fade and Peer Hangup

In this case, Alice is once again on her mobile device and enters an
area where there is no coverage for a long distance. As such, her
device is unable to send and receive media for many seconds. The
server is able to detect this, and can inform the remote user that
Alice has lost network connectivity (open question: should this be
done via ripp or through proprietary means?). The remote user gives up
and some point and hangs up the call. Alice's server ends the call.

When Alice's phone finally regains network connectivity, it connects
to the call URI and gets a 404. This tells the device that the call no
longer exists, and so Alice's phone indicates to Alice that the call
has been ended (todo: should we keep the call state around in the
'ended' state for an hour or so, so that Alice's device can query it
later and learn that it was ended by the remote party through an
explicit hangup event, and also learn when)

## Resiliency MidCall Wireless Fade and Server Drop

In this final use case, Alice enters an area where there is no
coverage for an extended period of time. The server quickly detects
that she is not connected (it ceases receiving media). After a period
of time, the server decices to end the call. It changes the call state
to ended, which is passed to the remote party.

When Alice's phone recovers and connects to the call, it gets a 404,
informing her that the call has ended. 

# Normative Protocol Specification

A server that supports inbound calls on its TG MUST include the
"inbound" element in its TG description. This MUST include the allowed
caller IDs in the "origins" element, and the allowed destinations in
the "destinations".

The server MUST allow the client to send a "proceeding", "alerting",
"answered", "declined", "failed", "noanswer" and "end" events, and
take the associated actions on the call.

A client that answers a call MUST perform a POST operation to the call
URI, and in the body of the request, it MUST include its handler URI,
and no other information. The server MUST respond with a directive. If
the directive works for the client, the client MUST generate an
'answered' event to answer the call. The client MUST NOT POST its
handler to the call URI until the user indicates that this device
should accept the call. 

It MUST initiate signaling and media byways for the call, render
incoming media and generate outgoing media for the call. 


  
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


