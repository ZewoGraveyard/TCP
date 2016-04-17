TCP
======

[![Swift][swift-badge]][swift-url]
[![Platform][platform-badge]][platform-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]

## Features

- [x] TCPConnection
- [x] TCPServer

##Usage


```swift
co {
  do {
    let server = try TCPServer(for: URI("tcp://0.0.0.0:8080"))
    let connection = try server.accept()
    let data = try connection.receive(max: 1024)
    try connection.send(data)
  } catch {
    print(error)
  }
}

let connection = try TCPConnection(to: URI("tcp://127.0.0.1:8080"))
try connection.open()
try connection.send("hello")
let data =  try connection.receive(upTo: 1024)
print(data)
```


## Community

[![Slack](http://s13.postimg.org/ybwy92ktf/Slack.png)](https://zewo-slackin.herokuapp.com)

Join us on [Slack](https://zewo-slackin.herokuapp.com).

License
-------

**TCP** is released under the MIT license. See LICENSE for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[platform-badge]: https://img.shields.io/badge/Platform-Mac%20%26%20Linux-lightgray.svg?style=flat
[platform-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
