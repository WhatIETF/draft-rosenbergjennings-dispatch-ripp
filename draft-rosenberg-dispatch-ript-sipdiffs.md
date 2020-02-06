%%%

Title = "Real Time Internet Peering for Telephony (RIPT) Comparison with the Session Initiaton Protocol (SIP)"
abbrev = "RIPT vs. SIP"
docName = "draft-rosenbergjennings-dispatch-ript-sipdiffs-00"
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
cases. The question is - how much of SIP do those two specifications
replace? This document presents an analysis across the set of SIP
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
[@?I-D.rosenbergjennings-dispatch-ript] and its extension for inbound
calls to single user devices [TODO ref draft-rosenberg-dispatch-ript-inbound]
provide an alternative to the Session Initiation Protocol (SIP)
[@?RFC3261] for several use cases. The question is - how much of SIP
do those two specifications replace?

This document presents an
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


# Core Specifications

We first consider the core specifications - RFCs 3261 - 5, with a
heavy focus on RFC3261.


## The Main SIP Spec - RFC3261

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

## RFC3262 - Reliability of Provisional Responses

This specification is not needed in RIPT. It was specified to handle
complexities with UDP-based signaling transport. RIPT only uses
reliable transport for signaling. This specification is therefore
categorized as "not-needed". 

## RFC3263 - DNS SRV for SIP

This specification is not needed in RIPT. DNS resolution is a function
of HTTP and provided by A and AAAA records, not SRV. The load
balancing properties of the SRV record never worked well, and are
replaced by the far more robust techniques used with HTTP. This
specification is therefore categorized as "not-needed".

## RFC3264 - Offer/Answer

This specification, more than any other, is the one people love to
hate. It has also proven incredibly robust, extended dramatically
beyond its humble origines. RIPT abandons the offer/answer model
entirely, favoring a model in which the server is always in
control. Consequently, it is replaced by an "advertisement/proposal"
model. At its core, offer/answer allowed clients to indicate their
capabilities and for media streams to be set up and configured. RIPT
provides this functionality, though differently. Consequently, this
specification is categorized as "replaced".

## RFC3265 - SIP Events

This specification provided a generic mechanism for clients to
subscribe to events and receive notifications for them. This
capability exists in RIPT using long-running GET to the /events
endpoint on any resource, and uses the lifecycle of the transaction to
manage the lifecycle of the subscription. Consequently, this
specification is categorized as "replaced".


# SIP Extensions

There are many SIP extensions, we do not consider all of
them. Extensions which are corrections to other specifications are not
considered. 3GPP specific extensions are not considered. Extensions
specific to SIMPLE are not considered, and in general, presence and IM
(which is out of scope for RIPT) is not considered. Generally,
informational and experimental specifications are not considered,
though there are some exceptions when they have effectively become
normative in nature. 

##  SIP INFO (RFC 2976)

TODO

##  UPDATE (RFC 3311)

TODO 

## Resource Management and SIP (RFC 3312)

TODO 

## Privacy Header (RFC 3323)

TODO 

## P-Asserted-ID (RFC 3325)

TODO 

## Reason header field (RFC 3326)

TODO 

## Service-Route (RFC 3327)

TODO 

## REFER (RFC 3515)

TODO 

## Symmetric Response Routing (RFC 3581)

TODO 

## Registration Event Package (RFC 3680)

TODO 

## Third Party Call Controll (RFC 3725)

TODO 

## E.164 and SIP (RFC 3824)

TODO 

## UA Capabilities (RFC 3840)

TODO 

## Caller Prefs (RFC 3841)

TODO 

## Replaces Header Field (RFC 3891)

TODO 

## Referred-By (RFC 3892)

TODO 

## PUBLISH method (RFC 3903)

TODO 

## Join Header Field (RFC 3911)

TODO 

## Early Media (RFC 3960)

TODO 

## Session Timers (RFC 4028)

TODO 

## INVITE Dialog Event Package (RFC 4235)

TODO 

## Request History (RFC 4244)

TODO 

## Actions for non-INVITE?? (RFC 4320)

TODO 

## Pre-Emption Events (RFC 4411)

TODO 

## Resource-Priority

TODO 

## Suppression of Implied REFER Subscription (RFC 4488)

TODO 

## Conveying Feature Tags (RFC 4508)

TODO 

## Request Auth?? (RFC 4538)

TODO 

## KPML (RFC 4730)

TODO 

## representing trunk groups (RFC 4904)

TODO 

## Connected Identity (RFC 4916)

TODO 

## Dial Strin (RFC 4967)

TODO 

## URN for emergency services (RFC 5031)

TODO 

## Rejecting Anonymous Requests (RFC 5079)

TODO 

## Real-Time Text (RFC 5194)

TODO 

## Answering Modes ?? (RFC 5373)

TODO 

## SIP Outbound (RFC 5626)

TODO 

## GRUU (RFC 5627)

TODO 

## App Interaction Framework (RFC 5629)

TODO 

## SIP Session Mobility (RFC 5621)

TODO 

## Diversion (RFC 5806)

TODO 

## Domain Certs (RFC 5922)

TODO 

## Connection Reuse (RFC 5923)

TODO 

## UA Config (RFC 6011)

TODO 

## Event Package for Call Quality (RFC 6035)

TODO 

## Certificate Management Service (RFC 6072)

TODO 

## SIP e2e performance metrics (RFC 6076)

TODO 

## UA Profile Delivery (RFC 6080)

TODO 

## INFO method Package and Framework (RFC 6086)

TODO 

## ANAT? (RFC 6135)

TODO 

## registration of multiple numbersin SIP (RFC 6140)

TODO 

## IPv6 Transition and SIP (RFC 6157)

TODO 

## Indication of Support for Keepalive (RFC 6223)

TODO 

## SIP Response for Indication of Terminated Dialog (RFC 6228)

TODO 

## Location Conveyance in SIP (RFC 6442)

TODO 

## Notification for Rate Control (RFC 6446)

TODO 

## Filtering Location Notifications (RFC 6447)

TODO 

## SIP specific event notification (RFC 6665)

TODO 

## Framework for Session Policy (RFC 6794)

TODO 

## SIP Events for Session Policy (RFC 6795)

TODO 

## UA Profile set for Media Policy (RFC 6796)

TODO 

## Completion of Calls (RFC 6910)

TODO 

## Fax over IP in SIP (RFC 6913)

TODO 

## Request History (RFC 7044)

TODO 

## SIP LOad Control Event Package (RFC 7200)

TODO 

## Session Identifier in SIP (RFC 7329)

TODO 

## Loop Detection in SIP (RFC 7332)

TODO 

## SIP Overload Control (RFC 7339)

TODO 

## Media Traceroute (RFC 7403)

TODO 

## SIP Rate Control (RFC 7415)

TODO 

## Transporting UU Information in SIP (RFC 7433)

TODO 

## URNs for Alert-Info (RFC 7462)

TODO 

## Shared Appearances for an AOR (RFC 7463)

TODO 

## SIPREC (RFC 7866)

TODO 

## E2E Session Identification (RFC 7989)

TODO 

## Response Code for Unwanted Calls (RFC 8197)

TODO 

## Authenticated Identity Management (RFC 8224)

TODO 

## Passport (RFC 8225)

TODO 

## STIR Certs (RFC 8226)

TODO 

## Content-ID (RFC 8262)

TODO 

## Negotiating Human Language (RFC 8373)

TODO 

## Passport for Resource Priority (RFC 8443)

TODO 

## Marking SIP messages to be logged (RFC 8497)

TODO 

## Push Notification and SIP (RFC 8599)

TODO 



# SDP Extensions

## Grouping of m-lines (RFC 3388)

TODO 

## Media Auth (RFC 3521)

TODO 

# NAT Traversal

## STUN (RFC 5389)

TODO 

## TURN (RFC 5766)

TODO 

## Indicating support for ICE in SDP (RFC 5768)

TODO 

## ICE (RFC 5245)

TODO 

## ANAT (RFC 4091)

TODO 

## TURN TCP (RFC 6062)

TODO 

## TCP candidates with ICE (RFC 6544)

TODO 


# RTP Extensions (excepting Payload Types)

TODO 

{backmatter}
