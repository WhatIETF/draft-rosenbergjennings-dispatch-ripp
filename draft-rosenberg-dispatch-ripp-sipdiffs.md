---
title: Real Time Internet Peering Protocol (RIPP) Comparison with the Session Initiaton Protocol (SIP
# abbrev: RIPP vs. SIP
docname: draft-rosenbergjennings-dispatch-ripp-sipdiffs-00
date: 2020-02-07
# date: 2012-01
# date: 2012

# stand_alone: true

ipr: trust200902
area: Applications
wg: dispatch
kw: Internet-Draft
cat: std

coding: us-ascii
pi:    # can use array (if all yes) or hash here
#  - toc
#  - sortrefs
#  - symrefs
  toc: yes
  sortrefs:   # defaults to yes
  symrefs: yes

author:
    -
      ins: J. Rosenberg
      name: Jonathan Rosenberg
      org: Five9
      email: jdrosen@jdrosen.net


--- abstract


The Real-Time Internet Peering Protocol (RIPP) and its extension for
inbound calls to single user devices provide an alternative to the
Session Initiation Protocol (SIP) for several use cases. The question
is - how much of SIP do those two specifications replace? This
document presents an analysis across the set of SIP specifications,
and analyzes whether the two RIPP documents replace each with similar
capability, whether they eliminate the need for that specification, or
whether some or all of that specification are not addressed by RIPP.

--- middle

#Introduction    


The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119, BCP 14
{{RFC2119}} and indicate requirement levels for compliant CoAP
implementations.

The Real-Time Internet Peering Protocol (RIPP)
{{?I-D.rosenbergjennings-dispatch-ripp}} and its extension for inbound
calls to single user devices {{I-D.rosenberg-dispatch-ripp-inbound}}
provide an alternative to the Session Initiation Protocol (SIP)
{{?RFC3261}} for several use cases. The question is - how much of SIP
do those two specifications replace?

This document presents an
analysis across the set of SIP specifications, and categorizes each
specification as one of three types:

1. the two RIPP documents replace the document in whole with similar
 capability (replaced)
2. the two RIPP documents eliminate the need for that specification
 without providing a similar capability (not-needed)
3. the two RIPP documents do not eliminate the need for the
 capabilities of that specification, in whole or in part. In such a
 case, a RIPP extension would be needed if this specification was
 desired as part of RIPP. (not-replaced)


# Core Specifications

We first consider the core specifications - RFCs 3261 - 5, with a
heavy focus on RFC3261.

## The Main SIP Spec - RFC3261

There is a lot of content in this specification. The best way to
analyze it compared to RIPP is to examine each of the methods and
header fields, and consider the functionality provided by them.

The INVITE method is of course replaced by RIPP, as is the BYE
(through the ended event). Re-INVITE, though not a different method,
is also supported in RIPP, though only ever initiated by the server
with a new directive. Clients can move calls around by specifying the
usage of a different handler. CANCEL is replaced in {{ripp-inbound}}
by broadcasting an event to all listeners informing them that the call
has been answered. The usage of CANCEL to end an unanswered call is
replaced by the ended event in RIPP. REGISTER is replaced by the
handler construct. ACK is not needed since RIPP is reliable.

OPTIONS - which never worked that well - is replace by the more robust
and complete TG construct, allowing the client the ability to discover
everything needed to interact with the services of a server. 

Considering header fields, interestingly, a large number of them are
focused on SIP routing features. These include Via, Route,
Record-Route, Contact. These are not needed in RIPP, since RIPP
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
and call legs. The To and From exist in RIPP, but are replaced with
secure versions using passports. The CSeq header field is not needed
in RIPP since it utilizes reliable transport only, and this header
field was only needed for transaction ordering.

The SIP extensibility mechanisms - Require, Proxy-Require, Allow,
Supported, are not needed in RIPP. These headers are necessary due to
the symmetric nature of the relationship between entities. In RIPP,
the client uses the services of the server and cannot insist on
anything. The client can determine what services are supported through
normal JSON extensibility constructs - similar to SIP heeaders -
wherein unknown elements are ignored.

The SIP forking concept - another source of much complexity - is
eliminated in RIPP, and thus the logic in SIP associated with forking
processing is not needed. Note tht, RIPP does allow a user to have
multiple devices, and to make and receive calls on any of them. This
is accomplished by using the normal HTTP model wherein multiple
clients can manipulate the resources on the server.

Consequently, we believe that RIPP serves as a full replacement for
the entirety of {{RFC3261}} and thus this specification is categorized
as "replaced". 

## RFC3262 - Reliability of Provisional Responses

This specification is not needed in RIPP. It was specified to handle
complexities with UDP-based signaling transport. RIPP only uses
reliable transport for signaling. This specification is therefore
categorized as "not-needed". 

## RFC3263 - DNS SRV for SIP

This specification is not needed in RIPP. DNS resolution is a function
of HTTP and provided by A and AAAA records, not SRV. The load
balancing properties of the SRV record never worked well, and are
replaced by the far more robust techniques used with HTTP. This
specification is therefore categorized as "not-needed".

## RFC3264 - Offer/Answer

This specification, more than any other, is the one people love to
hate. It has also proven incredibly robust, extended dramatically
beyond its humble origines. RIPP abandons the offer/answer model
entirely, favoring a model in which the server is always in
control. Consequently, it is replaced by an "advertisement/proposal"
model. At its core, offer/answer allowed clients to indicate their
capabilities and for media streams to be set up and configured. RIPP
provides this functionality, though differently. Consequently, this
specification is categorized as "replaced".

## RFC3265 - SIP Events

This specification provided a generic mechanism for clients to
subscribe to events and receive notifications for them. This
capability exists in RIPP using long-running GET to the /events
endpoint on any resource, and uses the lifecycle of the transaction to
manage the lifecycle of the subscription. Consequently, this
specification is categorized as "replaced".


# SIP Extensions

There are many SIP extensions, we do not consider all of
them. Extensions which are corrections to other specifications are not
considered. 3GPP specific extensions are not considered. Extensions
specific to SIMPLE are not considered, and in general, presence and IM
(which is out of scope for RIPP) is not considered. Generally,
informational and experimental specifications are not considered,
though there are some exceptions when they have effectively become
normative in nature. 

## 2976 - SIP INFO

## 3311 - UPDATE

## 3312 - Resource Management and SIP

## 3323 - Privacy Header

## 3325 - P-Asserted-ID

## 3326 - Reason header field

## 3327 - Service-Route

## 3515 - REFER

## 3581 - Symmetric Response Routing

## 3680 - Registration Event Package

## 3725 - 3PCC

## 3824 - E.164 and SIP

## 3840 - UA Capabilities

## 3841 - Caller Prefs

## 3891 - Replaces Header Field

## 3892 - Referred-By

## 3903 - PUBLISH method

## 3911 - Join Header Field

## 3960 - Early Media

## 4028 - Session Timers

## 4235 - INVITE Dialog Event Package

## 4244 - Request History

## 4320 - Actions for non-INVITE??

## 4411 - Pre-Emption Events

## 4412 - Resource-Priority

## 4488 - Suppression of Implied REFER Subscription

## 4508 - Conveying Feature Tags

## 4538 - Request Auth??

## 4730 - KPML

## 4904 - representing trunk groups

## 4916 - Connected Identity

## 4967 - Dial Strin

## 5031 - URN for emergency services

## 5079 - Rejecting Anonymous Requests

## 5194 - Real-Time Text

## 5373 - Answering Modes ??

## 5626 - SIP Outbound

## 5627 - GRUU

## 5629 - App Interaction Framework

## 5621 - SIP Session Mobility

## 5806 - Diversion

## 5922 - Domain Certs

## 5923 - Connection Reuse

## 6011 - UA Config

## 6035 - Event Package for Call Quality

## 6072 - Certificate Management Service

## 6076 - SIP e2e performance metrics

## 6080 - UA Profile Delivery

## 6086 - INFO method Package and Framework

## 6135 - ANAT?

## 6140 - registration of multiple numbersin SIP

## 6157 - IPv6 Transition and SIP

## 6223 - Indication of Support for Keepalive

## 6228 - SIP Response for Indication of Terminated Dialog

## 6442 - Location Conveyance in SIP

## 6446 - Notification for Rate Control

## 6447 - Filtering Location Notifications

## 6665 - SIP specific event notification

## 6794 - Framework for Session Policy

## 6795 - SIP Events for Session Policy

## 6796 - UA Profile set for Media Policy

## 6910 - Completion of Calls

## 6913 - Fax over IP in SIP

## 7044 - Request History

## 7200 - SIP LOad Control Event Package

## 7329 - Session Identifier in SIP

## 7332 - Loop Detection in SIP

## 7339 - SIP Overload Control

## 7403 - Media Traceroute

## 7415 - SIP Rate Control

## 7433 - Transporting UU Information in SIP

## 7462 - URNs for Alert-Info

## 7463 - Shared Appearances for an AOR

## 7866 - SIPREC

## 7989 - E2E Session Identification

## 8197 - Response Code for Unwanted Calls

## 8224 - Authenticated Identity Management

## 8225 - Passport

## 8226 - STIR Certs

## 8262 - Content-ID

## 8373 - Negotiating Human Language

## 8443 - Passport for Resource Priority

## 8497 - Marking SIP messages to be logged

## 8599 - Push Notification and SIP



# SDP Extensions

## 3388 - Grouping of m-lines

## 3521 - Media Auth

# NAT Traversal

## 5389 - STUN

## 5766 - TURN

## 5768 - Indicating support for ICE in SDP

## 5245 - ICE

## 4091 - ANAT

## 6062 - TURN TCP

## 6544 - TCP candidates with ICE


# RTP Extensions (excepting Payload Types)