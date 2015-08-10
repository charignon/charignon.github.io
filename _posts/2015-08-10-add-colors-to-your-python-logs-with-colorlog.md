---
layout: post
title: Add Colors To Your Python Logs With Colorlog
---

[colorlog](https://pypi.python.org/pypi/colorlog) is a drop-in replacement for the
Python logging module that allows you to add color to your logs.

Start by installing the *colorlog* module with *pip* (or easy_install):

{% highlight python %}
pip install colorlog
{% endhighlight python %}

Then you can use *colorlog* the way you would use *logging*:

{% highlight python %}
import colorlog
import logging

colorlog.basicConfig(level=logging.DEBUG)
colorlog.debug("debug")
colorlog.info("info")
colorlog.warning("warning")
colorlog.error("error")
colorlog.critical("critical")
{% endhighlight python %}

And your log become much easier to read:

![Color logging](/assets/colorlog.gif)
