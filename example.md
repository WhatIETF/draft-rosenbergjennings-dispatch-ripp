

This section describes a typical example where one company, Acme, is
using a cloud call service, Webex, and gets PSTN trying from the
provider Comcast.

The first stage is the Webex set up their service to be able to work as
an OAuth Resource Server working with ComCast as the Authorization
Server and understand the baseURI that ComCast uses for RIPP. Assume
that this is "https\://ripp.comcast.com". The next stage is the admin
from ACME logs on the Webex account and selects Comcast as the RIPP
provider.  This will cause the OAUTH dance and the admin will end up
having approved WebEX to use Acme's account at ComCast for RIPP. Webex
will have received an OAuth access and refresh token from ComCast and be
redirected to the new Provider Trunk URI. At this point, the pre setup
is read and RIPP can start. Assume the base provider trunk returned is
"https\://ripp.comcast.com/trunks/wbx234acme".

Webex will start by setting up for incoming calls at
"https\://ripp.webex/trunks/acme123" with an opaque security token of
"secret1234". This is done by making a HTTP PUT to
https\://ripp.comcast.com/trunks/wbx234acme/consumerTrunk with a JSON
body of:

~~~
{
"consumerTrunkURI":"https://ripp.webex/trunks/acme123 " ,
"consumerToken":"secret1234"
}
~~~

The ComCast server will then validate the token and URI are correct as
well as find out the advertised capability of the Webex trunk by doing a
GET to https\://ripp.webex/trunks/acme123/capAdv and using the secret1234
as an authorization token. Webex supports the default values but also
support G.729 as an additional codec so it needs to return the list of
codecs supported. It returns a JSON body of:

~~~
{ "codec":  [ "opus", "g711", "dtmf", "cn", "g729" ] }
~~~

At this point we are ready for inbound or outbound calls.

## Inbound Call

A PSTN calls arrives at Comcast that is routed to the this trunk via a
Comcast SBC that will convert it from SIP to RIPP. The SBC knows which
codecs the trunk the support and can immediately send the SIP answer in
a 183 then can make HTTP post to the consumer trunk URI to set up the
incoming call. This is does by doing a POST to
"https\://ripp.webex/trunks/acme123/calls" using the authorization token
"secret1234". This will return a new call URI for this call of
https\://ripp.webex/call/c567.

At this point the SBC can make a long poll GET to
"https\://ripp.webex/call/c567/events" to get any update events about
this call. The SBC will also open a number of byways by making POST
requests to "https\://ripp.webex/call/c567/media-up" and
"https\://ripp.webex/call/c567/media-down" to send and receive media.

For each of the media-up byways, the Comcast SBC will send BywayPreamble
that tells the other side meta data about what will be sent on this
byway. For the media-down byways, the Webex server will sen the
BywayPreamble. The BywayPreamble contains the name of the codec, the
base sequence number, frameTime, and baseTime. After this BywayPreamble,
media frames can be sent that contain a seqOffset number, media length,
and then the media data. The receiver compute the time sequence number
for the frame by adding the baseSeqNum for the byway to the seqOffset
for the frame. The timestamp for the media is computed using the
baseTime for the byway plus the packeTime multiplied by the seqNum.

The data from the https\://ripp.webex/call/c567/events request will be an
infinite JSON array of Events. When the Webex server answers the call,
the event returned would look like:

~~~
{ "name":"accepted" }
~~~

## Outbound Call

For Webex to make it outbound call, it is the same as the inbound call
other than the provider trunk URI is used. The Webex server would act as
a client and do a HTTP POST to
"https\://ripp.comcast.com/trunks/wbx234acme/calls" to create a call URI
of "http\s://ripp.comcast.com/call/c789". From that point the flow is
roughly the same as inbound with the client and server roles reversed.

## End of call 

If the call is ended on the server side, server sends a terminated event
with the ended flag set to true then waits a small time for client to
close the connection then closes the connection.

If the call is ended on the client side, the client sends a terminated
event with the ended flag set to true and then closes the connection. In
either case the even looks like:

~~~
{ "name":"terminated", "ended": true }
~~~
















