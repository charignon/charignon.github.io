---
layout: post
title: Practical one time padding with Node JS
---

Source code: [https://github.com/charignon/otpCSnode](https://github.com/charignon/otpCSnode)

<div class="message">
  Too long don't read: How I used Node JS & CoffeeScript to implement one time padding of TCP traffic. Example use with: SSH, SCP and HTTP Proxying.
</div>

## One time padding

<cite>
In cryptography, a one-time pad (OTP) is an encryption technique that cannot be cracked if used correctly. In this technique, a plaintext is paired with random, secret key (or pad). Then, each bit or character of the plaintext is encrypted by combining it with the corresponding bit or character from the pad using modular addition.</cite>[Wikipedia: One time pad](http://en.wikipedia.org/wiki/One-time_pad).

In other words, one-time padding is a cryptography technique using a key (that both sides know) as long as the message.
Since the key is as long as the message, the message appear as random as the key and is uncrackable if the key cannot be guessed.

Technically, it is implemented with a simple XOR between the message and the key. It has been deem quite unpractical for most encryption needs because the key has to be as long as the data. But when you can afford to use it, it is the only uncrackable encryption technique. Don't take my word for it, the red telephone apparently used it according to the same wikipedia article.

## Key generation and distribution

We can easily create a key using the `/dev/random` file. For instance to generate a key file named `key` of `100Mb` you could run:

{% highlight bash %}
dd if=/dev/random of=./key bs=1048576 count=100
{% endhighlight bash %}

In the next part I assume that you have this key on two different hosts.

## Don't reuse the key

Contrary to most encryption method, the one-time-pad keys are used only once. In our case, it means that our 100Mb key can encrypt only 100Mb, not one more bit!

To use the keys several times (for example several ssh sessions) without having to dump it after each one, you must keep track of what your encrypted before. In other words you need to know your offset in the key file.

## Client and server code

To simplify, the key file is hardcoded and loaded fully in memory.

As an improvement the key could be specific on the command line and precached by chunk at runtime.

### Server code

The server connects to a service like SSH, HttpProxy, VoIP server etc.
It allows the client to operate with the service by:
- Encrypting the traffic from the service and forwarding it to the client
- Decrypting the traffic coming from the client and forwarding it to the service

{% highlight coffee %}
net = require("net")
otp = require("./otp")
argv = require('minimist')(process.argv.slice(2))

expectedArgs = ["localPort", "servicePort", "serverOffset", "clientOffset"]
otp.validateArgs(argv, expectedArgs)

servicePort = Number(argv.servicePort)
localPort = Number(argv.localPort)
serverOffset = Number(argv.serverOffset)
clientOffset = Number(argv.clientOffset)

net.createServer((outBoundSocket) ->
  inBoundSocket =  net.createConnection(servicePort, "localhost")
  outBoundSocket.pipe(otp.encryptor("client", clientOffset)).pipe(inBoundSocket)
  inBoundSocket.pipe(otp.encryptor("server",serverOffset)).pipe(outBoundSocket)
).listen Number(localPort)

{% endhighlight coffee %}

The first part of the code is straightforward, we just parse the arguments and
validate them.

Then we create a tcp server bound to `localPort` and when a client connects to
this server we:

  - Create a connection to the service
  - Wire the connection between service and client with an offset for each encryptor: the offset is in byte from start of the key file

### Client code

Very similar to the server code:

{% highlight coffee %}
net = require("net")
otp = require("./otp")
argv = require('minimist')(process.argv.slice(2))

expectedArgs = ["localPort", "serverPort", "clientOffset", "serverOffset", "host"]
otp.validateArgs(argv, expectedArgs)

serverPort = Number(argv.serverPort)
localPort = Number(argv.localPort)
host = argv.host
serverOffset = Number(argv.serverOffset)
clientOffset = Number(argv.clientOffset)

outBoundSocket = net.createConnection(serverPort, host)
  net.createServer((inBoundSocket) ->
  outBoundSocket.pipe(otp.encryptor("server",serverOffset)).pipe(inBoundSocket)
  inBoundSocket.pipe(otp.encryptor("client",clientOffset)).pipe(outBoundSocket)
).listen(localPort)
{% endhighlight coffee %}


### Library code

This is where the encryption is done, again, pretty straightforward:

{% highlight coffee %}
through = require('through')
_ = require("underscore")
fs = require("fs")

# Keeping track of usage of key per entity
root = exports ? this
root.offsets = {}

# Load the key in memory
key = fs.readFileSync("key")

# Show usage notice
usage = (expected) ->
  console.log "Missing argument expecting #{expected}"
  process.exit 1

# Compute XOR of two buffers
xor = (v1,v2) ->
  new Buffer(_(v1).map((e,i) ->
  v2[i] ^ e
))

# Encryptor Through Stream, identifier is for accounting purposes of the offset
exports.encryptor = (identifier,offset) ->
  console.log "Init encryptor with offset #{offset}"
  _offset = offset
  through((data) ->
    end_offset = _offset + data.length
    @queue(xor(data,key.slice(_offset,end_offset)))
    _offset += data.length
    root.offsets[identifier] = _offset
    console.log root.offsets
)

# Validate arguments, actual = object from minimist, expected = array
exports.validateArgs = (actual,expected) ->
  actualKeys = _.keys(actual)
  _.each expected, (k) ->
    do usage(expected) if actualKeys.indexOf(k) == -1

# Show offset on CTRL-C to keep track of where we stopped
process.on 'SIGINT', () ->
  console.log "Logging offsets"
  console.log root.offsets
  process.exit 0

{% endhighlight coffee %}

## Encrypt ssh traffic

We have two computers called HostA and HostB, let's say that the ssh server is
on HostB. Let's say that out of the 100Mb key, we want to use the last 50Mb for
the server and the first 50Mb for the client.

On HostB we start the encryption server:
{% highlight bash %}
coffee receiver.coffee --localPort=8000 --servicePort=22 --serverOffset=52428800 --clientOffset=0
{% endhighlight bash %}
localPort,serverPort,clientOffset,serverOffset,host

On HostA we start the encryption client:
{% highlight bash %}
coffee sender.coffee --localPort=9000 --serverPort=8000 --host=HostB --serverOffset=52428800 --clientOffset=0
{% endhighlight bash %}

Then we can connect to HostB through the encryption tunnel with this command on HostA:
{% highlight bash %}
ssh localhost -p 9000
{% endhighlight bash %}

I also tried it with SCP and even an HTTP proxy and it worked fine!
Let me know what you think of it!
