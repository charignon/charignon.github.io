---
layout: post
title: A Test Automation Story
---

I am working on [Mercurial](https://www.Mercurial-scm.org/). Whenever I work
on a new series of patches, I want to ensure that the whole test suite passes
on every patch of the series. This article describes the steps I took toward
making this task completely **automated** and **transparent** to me. 



---

### Iteration Zero: run the tests and go grab a drink with a friend

The very first time I ran the Mercurial test I stared at my screen while the tests results
were being slowly displayed. After a while, I went to grab coffee, came back, and all the tests had run. I swore to myself that I would never waste more time staring at the screen waiting for the tests to finish. The first
step to a successful automation is getting frustrated with doing things manually.
Some people never get frustrated by that but I have a pretty low tolerance for
repetitive tasks!

> I am not saying that Mercurial tests are too slow, they actually take typically
less than 5 minutes to run. For tests that take one hour to run, people
don't hesitate to automate the process. For tests that take 2 minutes, most
people think they can stand staring at their screen and it is a **mistake**! 
Automate **all the things**, don't manually do the same thing **twice** and you
will improve!


### First iteration: Open a new window, type some commands, check later
The first improvement I made was opening a new terminal window to run all the tests.
This was better than waiting for the tests to finish. If you are not using
a terminal multiplexer, I strongly advise you to do so, check out [tmux](https://tmux.github.io/).
While running the tests, I was being careful not to modify any files to avoid messing up the results of the test.


### Second iteration: Isolate testing and work environment
Soon after, I decided to have two copies of the Mercurial repository. I kept one copy  to run the test
completely in RAM (for the sake of speed) and one copy on disk on which I was working. After
finishing a patch, I would push my changes to the test repository and run the
tests while not being blocked to make further changes. This created a separation
of environment between the test environment and the development environment, effectively
overcoming the main issue of the first iteration.

Despite being an enhancement over the previous iteration, four key things were missing:

1. I still had to type commands to push the changes, checkout the revisions
and run the tests
2. If I had to test 10 patches, I would have to launch them one by one
3. I had to look through the test results and take note of what passed and what
didn't pass
4. There was no neat way for me to see what changes pass the test and what changes
didn't pass the test

### Third iteration: Avoid unnecessary typing

I got fed up with typing the commands to push my changes, check them out
and run the tests. I did some research and figured out that tmux allows
you to open new windows and run commands in other windows programmatically. 
I used this API and scripted tmux to open a new window to run my tests.


### Fourth iteration: Getting tired of reading test output

I realized that our tests runner could produce a JSON report with the results
of each test. There was a bug where the output was not a valid JSON and it didn't
contain some of the information I needed so I sent patches upstream. Once fixed
I managed to get my previous automation to read the report, archive it, parse it
and give me a summary. I decided to store all these information in SQLite to
easily query them later.

### Fifth iteration: When it gets serious

My main issue at that point was that I was launching the tests one by one and
being careful not to launch two at a time. I added a task queue to my system using
[Celery](http://www.celeryproject.org/) to separate launching the tests and running them.
This way also, I can run the tests on multiple machines in the future or run unrelated tests in parallel. 
At this point, I hooked up tests for other repositories and not just the core Mercurial repository.
I built a command line tool to easily select what tests to run and to query the tests
results and failures.

![List of changesets and test results](/assets/listcset.png)

One thing was missing, I still had to read the reports to know when the tests were passing.

### Sixth iteration: Cherry on the cake: a hud, colored labels, and vim integration!

It is extremely easy to write Mercurial extensions, it can take as little as 
5 lines of python to add something useful. I wrote an extension that adds an
overlay on top of the list of commits in my repository to show me if the tests
passed for each revision:

![Changelog](/assets/slog.png)

I added a status bar in tmux to inform me of what is being tested and I am thinking
of adding an ETA for the tests.

Finally, I added shortcuts in vim to launch tests against the current revision,
the current stack and see test results.

### Future iterations: Dependencies, packaging, and distribution

I installed this automation on three machines already and it works great! 
Moving forward, I want to distribute this system to more people. I will write
more about it and talk about implementation details in other articles. 

