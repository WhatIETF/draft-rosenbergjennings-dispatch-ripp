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
heavily focused on HTTP based services.

{mainmatter}

# Introduction

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
balancing, scaling, and HTTP request routing. A more recent technology
is Istio, which utilizes an HTTP proxy (Envoy) to provide managed
routing between HTTP services, with features such as canary deploys.

Another example are HTTP tracing tools, which facilitate the tracing
of requests through distributed microservices. These tools can
autogenerate sequence diagrams and facilitate in troubleshooting.

Unfortunately, there are many applications being deployed into these
cloud platforms which require interconnection with the public switched
telephone network (PSTN). Examples of such applications include cloud
PBXs, cloud contact centers, cloud meetings applications, and so
on. Furthermore, commerce websites would like to allow customers
to call into the telephone network for support.

In order for these applications to connect to the PSTN, they typically
deploy SIP-based servers - SBCs, SIP proxies, and softswitches, to
provide this interconnection. Unfortunately, SIP based applications
cannot make use of the many capabilities these cloud platforms afford
to HTTP based applications. These SIP servers are usually deployed on
bare metal or VMs at best. Application developers must build their own
load balancing, HA, failover, clustering, and scaling techniques,
rather than using the capabilities of these platforms.

The goal of this specification is to define a new protocol that can be
used instead of SIP and RTP for the purposes of interconnection of
cloud-based applications to the PSTN. This protocol does not actually
deprecate or replace SIP itself, as it covers only a small subset of
the broader functionality that SIP provides.

More stuff

{backmatter}

