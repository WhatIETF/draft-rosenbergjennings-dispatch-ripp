%%%

#
# RIPT WebRTC - RIPT compatibility with webRTC
#
# Generation tool chain:
#   mmark (https://github.com/miekg/mmark)
#   xml2rfc (http://xml2rfc.ietf.org/)
#


Title = "RealTime Internet Peering for Telephony (RIPT) Compatibility with webRTC"

abbrev = "RIPT webRTC"
category = "std"
docName = "draft-rosenberg-dispatch-ript-webrtc-00"
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

The Real-Time Internet Peering for Telephony (RIPT) Protocol defines a
technique for establishing, terminating and otherwise managing calls
between entities in differing administrative domains. The RIPT Inbound
extension brings this to end clients, such as a browser. However, it
defines a different technique for media that cannot directly use the
webRTC APIs, and require a change to them. This specification provides
an extension to RIPT for webRTC compatibility, enabling media to flow
from browser to server as is done with RIPT, or from browser to
browser as is done with webRTC. It also discusses techniques for
sending e2e encrypted media.


{mainmatter}

# Introduction 

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in [@!RFC2119].

# Overview of Operation

Basic idea: The TG indicates that this compatibility mode is supported
on the TG. The handler is also indicates that this mode is
supported. The handler includes its own ICE candidates. This means we
provide the ICE candidates at "registration" time and not before the
call. This is necessary to facilitate the many call move and other
operations in RIPT-inbound. This also means the browser needs to keep
them fresh all of the time, rather than just before the call [[is this
posible with current API??]]. 

Since the media is sent by DTLS-SRTP and not embedded as media
chunks in a client-to-server HTTPS connection, the browser includes
its fingerprint in the handler as well. 

To initiate this compatibility mode for media, the server indicates as
such in the directive. It can only put it in a directive if the
handler that is selected, supports the mode. The directive includes
the ICE candidates from the peer. This will trigger the client to
perform ICE and send media (which will be DTLS-SRTP). 

RIPT itself doesnt convey the ICE candidates in the server to server
link, since its only through handler whih is static for a device and
not per-call. So we'd either need to move them, develop a separate way
to convey them, or assume SIP or some other technique is used for
server to server calls.


Suggest we also require a well-known port for media, and we'll
need an RTP headr extension to convey the callID since its included
inband in RIPT.

# IANA Considerations


TODO

# Security Considerations

TODO

# Acknowledgements

Thanks to Justin Uberti and Cullen Jennings for the discussion on this
concept. 


{backmatter}
