




GET <trunk-uri>/capAdv
POST <trunk-uri>/calls/<phone-number> to create call. returns <call-uri>


POST  <call-uri>/byways with JSON object with base seq, time, codec. Returns set of <byway-URI>
GET   <call-uri>/event to get most resent event
PUT   <call-uri>/event to update most resent even 
DELETE <call-uri> to end call

PUT <call-uri>/media - with JSON object with base seq, time, codec. followed by media  

NO GET <byway-uri> recv media
NO PUT <byway-uri> send media

ACKs go back on any open byway. 

Event is JSON object with timestamp,  alerting, connected, ended

Perhaps have migrate or do other way - prefer a 3xx redirect response to GET <call-uri>/event

Don't need keepalive,
Do we need transfer-and-takeback ?


--------

API

How setup work - API not Web page

When are the bearer tokens, provided, refreshed etc

Why timestamp and seq numb

Stereo is joint codec

On SIP GW - when client connects to provider, it does gets the 
